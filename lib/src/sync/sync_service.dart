import "dart:async";

import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../models.dart";
import "../store.dart";
import "supabase_config.dart";

enum SyncStatus {
  /// Bulut sozlanmagan - ilova faqat shu brauzerda ishlaydi.
  disabled,

  /// Sozlangan, lekin qurilma hali ulanmagan (kirish kerak).
  signedOut,

  /// Ayni damda yuborilyapti / olinyapti.
  syncing,

  /// Hammasi bulutda saqlangan.
  synced,

  /// Internet yo'q - o'zgarishlar navbatda turibdi.
  offline,
}

/// Kassa ma'lumotlarini Supabase bilan sinxronlaydi.
///
/// Ish tartibi "avval lokal": har qanday o'zgarish darhol brauzer
/// xotirasiga yoziladi va ekranda ko'rinadi, keyin fonda bulutga
/// yuboriladi. Internet uzilsa kassa ishlashda davom etadi.
class SyncService extends ChangeNotifier {
  SyncService._();

  static final SyncService instance = SyncService._();

  static const String _stateId = "main";
  static const String _skipKey = "saxovat_cloud_skip";
  static const Duration _debounce = Duration(milliseconds: 1500);
  static const Duration _retryEvery = Duration(seconds: 45);

  SupabaseClient? _client;
  SyncStatus _status = SyncStatus.disabled;
  String? _error;
  DateTime? _lastSyncAt;

  bool _skipped = false;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _busy = false;
  bool _dirty = false;

  SyncStatus get status => _status;
  String? get error => _error;
  DateTime? get lastSyncAt => _lastSyncAt;
  bool get enabled => SupabaseConfig.isConfigured;
  bool get pending => _dirty;
  String? get email => _client?.auth.currentUser?.email;

  /// Qurilma bulutga ulanganmi (sessiya bormi).
  bool get isLinked => _client?.auth.currentSession != null;

  /// Qurilmani ulash ekranini ko'rsatish kerakmi.
  ///
  /// Holatga emas, sessiyaga qaraydi: aks holda ulanish so'rovi ketayotganda
  /// ekran almashib, kiritilgan ma'lumot yo'qoladi.
  bool get needsLink => enabled && !isLinked && !_skipped;

  /// "Hozircha shu qurilmada ishlayman" - ulashni keyinga qoldirish.
  Future<void> skipLink() async {
    _skipped = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipKey, true);
    notifyListeners();
  }

  /// Sozlamalardan qayta ulanish uchun.
  Future<void> askLinkAgain() async {
    _skipped = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skipKey);
    notifyListeners();
  }

  String get statusText => switch (_status) {
        SyncStatus.disabled => "Faqat shu qurilmada",
        SyncStatus.signedOut => "Bulutga ulanmagan",
        SyncStatus.syncing => "Saqlanmoqda...",
        SyncStatus.synced => "Bulutda saqlangan",
        SyncStatus.offline => "Ulanish yo'q",
      };

  // ------------------------------------------------------------------ ishga

  Future<void> init() async {
    if (!SupabaseConfig.isConfigured) {
      _set(SyncStatus.disabled);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _skipped = prefs.getBool(_skipKey) ?? false;

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
      _client = Supabase.instance.client;
    } catch (e) {
      _error = "$e";
      _set(SyncStatus.disabled);
      return;
    }

    store.onMutated = schedulePush;
    _retryTimer = Timer.periodic(_retryEvery, (_) {
      if (_dirty && !_busy) unawaited(_push());
    });

    if (_client!.auth.currentSession == null) {
      _set(SyncStatus.signedOut);
      return;
    }
    // Birinchi sinxronizatsiya fon rejimida - ilova kutib turmaydi.
    unawaited(syncNow());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }

  void _set(SyncStatus s) {
    _status = s;
    notifyListeners();
  }

  // ------------------------------------------------------------- qurilmani

  /// Qurilmani bulutga ulaydi. Xato bo'lsa - matn qaytaradi.
  Future<String?> signIn(String email, String password) async {
    final client = _client;
    if (client == null) return "Bulut sozlanmagan";
    _set(SyncStatus.syncing);
    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _skipped = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_skipKey);
    } on AuthException catch (e) {
      _set(SyncStatus.signedOut);
      return _authMessage(e);
    } catch (e) {
      _set(SyncStatus.signedOut);
      return _netMessage;
    }
    await syncNow();
    return null;
  }

  static const String _netMessage =
      "Bulutga ulanib bo'lmadi. Internetni va Supabase manzilini tekshiring.";

  String _authMessage(AuthException e) {
    // Tarmoq xatolari ham AuthException bo'lib keladi - ularni ajratamiz.
    if (e is AuthRetryableFetchException) return _netMessage;

    final code = e.code ?? "";
    if (code == "invalid_credentials") return "Email yoki parol noto'g'ri";
    if (code == "email_not_confirmed") {
      return "Email tasdiqlanmagan. Supabase'da foydalanuvchini tasdiqlang.";
    }

    final m = e.message.toLowerCase();
    if (m.contains("failed to fetch") ||
        m.contains("failed host lookup") ||
        m.contains("clientexception") ||
        m.contains("socketexception") ||
        m.contains("timeout")) {
      return _netMessage;
    }
    if (m.contains("invalid login") || m.contains("invalid credentials")) {
      return "Email yoki parol noto'g'ri";
    }
    if (m.contains("email not confirmed")) {
      return "Email tasdiqlanmagan. Supabase'da foydalanuvchini tasdiqlang.";
    }
    return e.message;
  }

  Future<void> signOut() async {
    await _client?.auth.signOut();
    _set(SyncStatus.signedOut);
  }

  // ---------------------------------------------------------- sinxronizatsiya

  void schedulePush() {
    if (_client == null || _client!.auth.currentSession == null) return;
    _dirty = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => unawaited(_push()));
    notifyListeners();
  }

  /// To'liq sinxronizatsiya: bulut bilan lokalni solishtirib, birini oladi.
  Future<void> syncNow() async {
    final client = _client;
    if (client == null || client.auth.currentSession == null) return;
    if (_busy) return;
    _busy = true;
    _set(SyncStatus.syncing);

    try {
      final row = await client
          .from("kassa_state")
          .select("data, updated_at")
          .eq("id", _stateId)
          .maybeSingle();

      if (row == null) {
        // Bulut bo'sh - shu qurilmadagi ma'lumotni yuboramiz.
        await _writeState(client);
      } else {
        final remoteAt =
            DateTime.parse(row["updated_at"] as String).toUtc();
        final seen = store.remoteUpdatedAt;
        final remoteIsNewer = seen == null || remoteAt.isAfter(seen);

        if (remoteIsNewer && !store.hasLocalWork) {
          // Bu qurilma yangi (yoki bo'sh) - bulutdagi nusxani olamiz.
          store.applyRemoteState(
            (row["data"] as Map).cast<String, Object?>(),
            remoteAt,
          );
          await _pullReceipts(client);
        } else {
          await _writeState(client);
        }
      }

      await _pushReceipts(client);
      _dirty = false;
      _error = null;
      _lastSyncAt = DateTime.now();
      _set(SyncStatus.synced);
    } catch (e) {
      _error = "$e";
      _set(SyncStatus.offline);
    } finally {
      _busy = false;
    }
  }

  Future<void> _push() async {
    final client = _client;
    if (client == null || client.auth.currentSession == null) return;
    if (_busy) return;
    _busy = true;
    _set(SyncStatus.syncing);

    try {
      await _writeState(client);
      await _pushReceipts(client);
      _dirty = false;
      _error = null;
      _lastSyncAt = DateTime.now();
      _set(SyncStatus.synced);
    } catch (e) {
      _error = "$e";
      _set(SyncStatus.offline);
    } finally {
      _busy = false;
    }
  }

  Future<void> _writeState(SupabaseClient client) async {
    final now = DateTime.now().toUtc();
    final res = await client
        .from("kassa_state")
        .upsert({
          "id": _stateId,
          "data": store.stateForRemote(),
          "updated_at": now.toIso8601String(),
        })
        .select("updated_at")
        .single();
    store.setRemoteUpdatedAt(
      DateTime.parse(res["updated_at"] as String).toUtc(),
    );
  }

  Future<void> _pushReceipts(SupabaseClient client) async {
    final pendingList = store.unsyncedReceipts;
    if (pendingList.isEmpty) return;
    await client
        .from("receipts")
        .upsert(pendingList.map((r) => r.toRow()).toList());
    await store.markReceiptsSynced(pendingList.map((r) => r.id));
  }

  Future<void> _pullReceipts(SupabaseClient client) async {
    final rows = await client
        .from("receipts")
        .select()
        .order("closed_at", ascending: false)
        .limit(500);
    await store.mergeRemoteReceipts(
      (rows as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((r) => Receipt.fromRow(r.cast<String, Object?>()))
          .toList(),
    );
  }
}

final SyncService sync = SyncService.instance;
