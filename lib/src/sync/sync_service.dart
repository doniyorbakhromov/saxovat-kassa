import "dart:async";

import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../store.dart";
import "pending_ops.dart";
import "supabase_config.dart";

enum SyncStatus {
  /// Bulut sozlanmagan - ilova faqat shu brauzerda ishlaydi.
  disabled,

  /// Sozlangan, lekin qurilma hali ulanmagan (kirish kerak).
  signedOut,

  /// Ayni damda yuborilyapti / olinyapti.
  syncing,

  /// Hammasi bulutda va jonli ulanish bor.
  synced,

  /// Internet yo'q - o'zgarishlar navbatda turibdi.
  offline,
}

/// Kassa ma'lumotlarini Supabase bilan real vaqtda sinxronlaydi.
///
/// Ish tartibi "avval lokal": o'zgarish darhol qurilmada saqlanadi va
/// ekranda ko'rinadi, so'ng navbat orqali bulutga yuboriladi. Boshqa
/// qurilmalardagi o'zgarishlar jonli kanal orqali darhol yetib keladi.
/// Internet uzilsa kassa ishlashda davom etadi, navbat to'planib turadi.
class SyncService extends ChangeNotifier {
  SyncService._();

  static final SyncService instance = SyncService._();

  static const String _skipKey = "saxovat_cloud_skip";
  static const Duration _debounce = Duration(milliseconds: 700);
  static const Duration _retryEvery = Duration(seconds: 20);

  /// Bulutda kuzatiladigan jadvallar.
  static const List<String> _entities = [
    "tables",
    "order_lines",
    "menu_items",
    "categories",
    "settings",
    "receipts",
  ];

  /// Har bir jadvalning kaliti.
  static const Map<String, String> _pk = {
    "tables": "id",
    "order_lines": "id",
    "menu_items": "id",
    "categories": "name",
    "settings": "id",
    "receipts": "id",
  };

  SupabaseClient? _client;
  RealtimeChannel? _channel;
  SyncStatus _status = SyncStatus.disabled;
  String? _error;
  DateTime? _lastSyncAt;
  bool _live = false;

  bool _skipped = false;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _busy = false;

  SyncStatus get status => _status;
  String? get error => _error;
  DateTime? get lastSyncAt => _lastSyncAt;
  bool get enabled => SupabaseConfig.isConfigured;
  bool get pending => store.ops.isNotEmpty;
  int get pendingCount => store.ops.length;
  String? get email => _client?.auth.currentUser?.email;

  /// Jonli kanal ulanganmi (boshqa qurilma o'zgarishi darhol keladimi).
  bool get live => _live;

  bool get isLinked => _client?.auth.currentSession != null;

  bool get needsLink => enabled && !isLinked && !_skipped;

  String get statusText => switch (_status) {
        SyncStatus.disabled => "Faqat shu qurilmada",
        SyncStatus.signedOut => "Bulutga ulanmagan",
        SyncStatus.syncing => "Saqlanmoqda...",
        SyncStatus.synced => _live ? "Jonli ulangan" : "Bulutda saqlangan",
        SyncStatus.offline => pending
            ? "Ulanish yo'q - $pendingCount ta kutmoqda"
            : "Ulanish yo'q",
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
      if (!_busy && isLinked && (store.ops.isNotEmpty || !_live)) {
        unawaited(_flushAndMaybeReconnect());
      }
    });

    if (!isLinked) {
      _set(SyncStatus.signedOut);
      return;
    }
    store.trackOps = true;
    unawaited(syncNow());
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    unawaited(_channel?.unsubscribe());
    super.dispose();
  }

  void _set(SyncStatus s) {
    _status = s;
    notifyListeners();
  }

  // ------------------------------------------------------------- qurilmani

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
      store.trackOps = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_skipKey);
    } on AuthException catch (e) {
      _set(SyncStatus.signedOut);
      return _authMessage(e);
    } catch (_) {
      _set(SyncStatus.signedOut);
      return _netMessage;
    }
    await syncNow();
    return null;
  }

  static const String _netMessage =
      "Bulutga ulanib bo'lmadi. Internetni va Supabase manzilini tekshiring.";

  String _authMessage(AuthException e) {
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
    return e.message;
  }

  Future<void> signOut() async {
    await _stopLive();
    await _client?.auth.signOut();
    store.trackOps = false;
    store.ops.clear();
    _set(SyncStatus.signedOut);
  }

  Future<void> skipLink() async {
    _skipped = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipKey, true);
    notifyListeners();
  }

  Future<void> askLinkAgain() async {
    _skipped = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skipKey);
    notifyListeners();
  }

  // ---------------------------------------------------------- yuborish

  void schedulePush() {
    if (!isLinked) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => unawaited(_flush()));
    notifyListeners();
  }

  /// Navbatdagi amallarni bulutga yuboradi.
  Future<bool> _flush() async {
    final client = _client;
    if (client == null || !isLinked) return false;
    if (_busy) return false;
    if (store.ops.isEmpty) return true;

    _busy = true;
    _set(SyncStatus.syncing);
    try {
      final batch = store.ops.pending;
      for (final op in batch) {
        await _send(client, op);
      }
      store.ops.done(batch);
      _error = null;
      _lastSyncAt = DateTime.now();
      _set(SyncStatus.synced);
      return true;
    } catch (e) {
      _error = "$e";
      _set(SyncStatus.offline);
      return false;
    } finally {
      _busy = false;
    }
  }

  Future<void> _send(SupabaseClient client, PendingOp op) async {
    final key = _pk[op.entity] ?? "id";
    if (op.isDelete) {
      await client.from(op.entity).delete().eq(key, op.rowId);
    } else {
      await client.from(op.entity).upsert({
        ...op.data,
        if (op.entity != "receipts") "updated_by": store.clientId,
        if (op.entity != "receipts")
          "updated_at": DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  // ------------------------------------------------------------- olish

  /// To'liq sinxronizatsiya: avval navbatni bo'shatamiz, keyin bulutdagi
  /// holatni to'liq olamiz va jonli kanalni ulaymiz.
  Future<void> syncNow() async {
    final client = _client;
    if (client == null || !isLinked) return;

    if (!await _flush()) return;
    if (_busy) return;

    _busy = true;
    _set(SyncStatus.syncing);
    try {
      final tableRows = await _select(client, "tables");
      final lineRows = await _select(client, "order_lines");
      final itemRows = await _select(client, "menu_items");
      final catRows = await _select(client, "categories", order: "position");
      final receiptRows = await _select(
        client,
        "receipts",
        order: "closed_at",
        ascending: false,
        limit: 500,
      );
      final settingsRows = await _select(client, "settings");

      final bulutBosh = tableRows.isEmpty &&
          itemRows.isEmpty &&
          catRows.isEmpty &&
          settingsRows.isEmpty;

      if (bulutBosh) {
        // Birinchi ulanish - shu qurilmadagi hamma narsani yuboramiz.
        store.queueEverything();
        _busy = false;
        await _flush();
        _busy = true;
      } else {
        await store.replaceFromRemote(
          tableRows: tableRows,
          lineRows: lineRows,
          itemRows: itemRows,
          categoryRows: catRows,
          receiptRows: receiptRows,
          settingsRow: settingsRows.isEmpty ? null : settingsRows.first,
        );
      }

      _error = null;
      _lastSyncAt = DateTime.now();
      _set(SyncStatus.synced);
    } catch (e) {
      _error = "$e";
      _set(SyncStatus.offline);
    } finally {
      _busy = false;
    }

    await _startLive();
  }

  Future<List<Map<String, Object?>>> _select(
    SupabaseClient client,
    String table, {
    String? order,
    bool ascending = true,
    int? limit,
  }) async {
    var q = client.from(table).select();
    final rows = order == null
        ? (limit == null ? await q : await q.limit(limit))
        : (limit == null
            ? await q.order(order, ascending: ascending)
            : await q.order(order, ascending: ascending).limit(limit));
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((r) => r.cast<String, Object?>())
        .toList();
  }

  Future<void> _flushAndMaybeReconnect() async {
    await _flush();
    if (!_live && isLinked) await _startLive();
  }

  // -------------------------------------------------------- jonli kanal

  Future<void> _startLive() async {
    final client = _client;
    if (client == null || !isLinked) return;
    await _stopLive();

    final channel = client.channel("kassa");
    for (final entity in _entities) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: "public",
        table: entity,
        callback: (payload) => _onRemoteChange(entity, payload),
      );
    }
    channel.subscribe((status, err) {
      final ok = status == RealtimeSubscribeStatus.subscribed;
      if (_live != ok) {
        _live = ok;
        notifyListeners();
      }
      if (err != null) _error = "$err";
    });
    _channel = channel;
  }

  Future<void> _stopLive() async {
    final ch = _channel;
    _channel = null;
    _live = false;
    if (ch != null) await ch.unsubscribe();
  }

  void _onRemoteChange(String entity, PostgresChangePayload payload) {
    final newRow = payload.newRecord.cast<String, Object?>();
    final oldRow = payload.oldRecord.cast<String, Object?>();

    // O'z o'zgarishimizning aks-sadosini qayta qo'llamaymiz.
    if (newRow["updated_by"] == store.clientId) return;

    final key = _pk[entity] ?? "id";
    final isDelete = payload.eventType == PostgresChangeEvent.delete;
    final row = isDelete ? oldRow : newRow;
    final id = "${row[key] ?? ""}";

    switch (entity) {
      case "tables":
        isDelete ? store.removeRemoteTable(id) : store.applyRemoteTable(row);
      case "order_lines":
        isDelete ? store.removeRemoteLine(id) : store.applyRemoteLine(row);
      case "menu_items":
        isDelete ? store.removeRemoteItem(id) : store.applyRemoteItem(row);
      case "categories":
        isDelete
            ? store.removeRemoteCategory(id)
            : store.applyRemoteCategory(row);
      case "settings":
        if (!isDelete) store.applyRemoteSettings(row);
      case "receipts":
        unawaited(
          isDelete
              ? store.removeRemoteReceipt(id)
              : store.applyRemoteReceipt(row),
        );
    }
  }
}

final SyncService sync = SyncService.instance;
