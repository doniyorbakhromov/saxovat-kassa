import "dart:async";
import "dart:convert";

import "package:flutter/foundation.dart";
import "package:shared_preferences/shared_preferences.dart";

import "data/receipt_db.dart";
import "models.dart";
import "utils.dart";

/// Barcha ma'lumotlar shu klassda saqlanadi va brauzer xotirasiga yoziladi.
class AppStore extends ChangeNotifier {
  AppStore._();

  static final AppStore instance = AppStore._();

  static const String _key = "saxovat_kassa_v1";

  late SharedPreferences _prefs;
  final ReceiptDb _receiptDb = ReceiptDb();

  /// Eski versiyalarda cheklar shu yerda edi - bir marta ko'chiriladi.
  List<Receipt> _legacyReceipts = <Receipt>[];
  bool _ready = false;
  bool get ready => _ready;

  List<BarTable> tables = <BarTable>[];
  List<MenuItem> menu = <MenuItem>[];
  List<String> categories = <String>[];
  List<Receipt> receipts = <Receipt>[];
  AppSettings settings = AppSettings();

  bool unlocked = false;

  /// Bulutdagi holatning oxirgi ko'rilgan versiyasi.
  DateTime? remoteUpdatedAt;

  /// Har bir o'zgarishdan keyin chaqiriladi (sinxronizatsiya uchun).
  void Function()? onMutated;

  // ---------------------------------------------------------------- yuklash

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      _seed();
      _persist();
    } else {
      try {
        _fromJson(jsonDecode(raw) as Map<String, Object?>);
      } catch (_) {
        _seed();
        _persist();
      }
    }
    await _loadReceipts();

    _ready = true;
    notifyListeners();
  }

  /// Testlar uchun: bazani yopib, xotiradagi holatni tozalaydi.
  @visibleForTesting
  Future<void> resetStorageForTest() async {
    await _receiptDb.close();
    receipts = <Receipt>[];
    _legacyReceipts = <Receipt>[];
    remoteUpdatedAt = null;
  }

  /// Cheklarni IndexedDB'dan yuklaydi va eski nusxalarni ko'chiradi.
  Future<void> _loadReceipts() async {
    try {
      await _receiptDb.open();
      receipts = await _receiptDb.loadAll();

      if (_legacyReceipts.isNotEmpty) {
        final known = receipts.map((r) => r.id).toSet();
        final moving =
            _legacyReceipts.where((r) => !known.contains(r.id)).toList();
        if (moving.isNotEmpty) {
          await _receiptDb.putAll(moving);
          receipts = await _receiptDb.loadAll();
        }
        _legacyReceipts = <Receipt>[];
        _persist();
      }
    } catch (_) {
      // IndexedDB ishlamasa (masalan maxfiy rejim) - kassa baribir ishlaydi,
      // cheklar faqat shu sessiyada va bulutda qoladi.
      receipts = _legacyReceipts;
      _legacyReceipts = <Receipt>[];
    }
  }

  void _fromJson(Map<String, Object?> j) {
    tables = (j["tables"] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(BarTable.fromJson)
        .toList();
    menu = (j["menu"] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(MenuItem.fromJson)
        .toList();
    categories = (j["categories"] as List<Object?>? ?? const [])
        .whereType<String>()
        .toList();
    _legacyReceipts = (j["receipts"] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(Receipt.fromJson)
        .toList();
    final s = j["settings"];
    settings = s is Map<String, Object?>
        ? AppSettings.fromJson(s)
        : AppSettings();
    settings.pin = _decodePin(settings.pin);
    remoteUpdatedAt = DateTime.tryParse(asStr(j["remoteUpdatedAt"]));
    if (categories.isEmpty) {
      categories = menu.map((e) => e.category).toSet().toList();
    }
  }

  Map<String, Object?> _toJson() => {
        "tables": tables.map((e) => e.toJson()).toList(),
        "menu": menu.map((e) => e.toJson()).toList(),
        "categories": categories,
        "settings": {
          ...settings.toJson(),
          "pin": _encodePin(settings.pin),
        },
        "remoteUpdatedAt": remoteUpdatedAt?.toIso8601String(),
      };

  void _persist() {
    unawaited(_prefs.setString(_key, jsonEncode(_toJson())));
  }

  void _changed() {
    _persist();
    onMutated?.call();
    notifyListeners();
  }

  // ------------------------------------------------------------------ kirish

  static const String _pinSalt = "saxovat-kassa";

  String _encodePin(String pin) {
    final b = utf8.encode(pin);
    final k = utf8.encode(_pinSalt);
    return base64Encode(
      List<int>.generate(b.length, (i) => b[i] ^ k[i % k.length]),
    );
  }

  String _decodePin(String stored) {
    try {
      final b = base64Decode(stored);
      final k = utf8.encode(_pinSalt);
      return utf8.decode(
        List<int>.generate(b.length, (i) => b[i] ^ k[i % k.length]),
      );
    } catch (_) {
      return stored;
    }
  }

  bool login(String pin) {
    if (pin == settings.pin) {
      unlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    unlocked = false;
    notifyListeners();
  }

  void setPin(String pin) {
    settings.pin = pin;
    _changed();
  }

  void setVenueName(String name) {
    settings.venueName = name.trim().isEmpty ? "SAXOVAT BAR" : name.trim();
    _changed();
  }

  void setAutoLockMinutes(int m) {
    settings.autoLockMinutes = m.clamp(0, 120);
    _changed();
  }

  void setServicePercent(int p) {
    settings.servicePercent = p.clamp(0, 30);
    _changed();
  }

  // ----------------------------------------------------------------- stollar

  BarTable? tableById(String id) {
    for (final t in tables) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<String> get zones {
    final z = <String>[];
    for (final t in tables) {
      if (!z.contains(t.zone)) z.add(t.zone);
    }
    return z;
  }

  BarTable addTable(String name, String zone, int seats) {
    final t = BarTable(
      id: newId(),
      name: name.trim().isEmpty ? "Stol ${tables.length + 1}" : name.trim(),
      zone: zone.trim().isEmpty ? "Zal" : zone.trim(),
      seats: seats,
    );
    tables.add(t);
    _changed();
    return t;
  }

  void editTable(String id, String name, String zone, int seats) {
    final t = tableById(id);
    if (t == null) return;
    t.name = name.trim().isEmpty ? t.name : name.trim();
    t.zone = zone.trim().isEmpty ? "Zal" : zone.trim();
    t.seats = seats;
    _changed();
  }

  void deleteTable(String id) {
    tables.removeWhere((t) => t.id == id);
    _changed();
  }

  /// Bir nechta stolni ketma-ket qo'shadi: "Stol 1", "Stol 2", ...
  /// Mavjud nomlar o'tkazib yuboriladi. Qo'shilganlar sonini qaytaradi.
  int addTables(String baseName, String zone, int seats, int count) {
    final base = baseName.trim().isEmpty ? "Stol" : baseName.trim();
    final z = zone.trim().isEmpty ? "Zal" : zone.trim();
    final taken = tables.map((t) => t.name.toLowerCase()).toSet();

    var added = 0;
    var n = 1;
    while (added < count && n < count + 500) {
      final name = "$base $n";
      n++;
      if (taken.contains(name.toLowerCase())) continue;
      taken.add(name.toLowerCase());
      tables.add(BarTable(id: newId(), name: name, zone: z, seats: seats));
      added++;
    }
    _changed();
    return added;
  }

  // -------------------------------------------------------------- buyurtma

  void addToOrder(String tableId, MenuItem item, {int qty = 1}) {
    final t = tableById(tableId);
    if (t == null) return;
    t.openedAt ??= DateTime.now();
    final idx = t.lines.indexWhere((l) => l.itemId == item.id && l.note.isEmpty);
    if (idx >= 0) {
      t.lines[idx].qty += qty;
    } else {
      t.lines.add(
        OrderLine(
          id: newId(),
          itemId: item.id,
          name: item.name,
          price: item.price,
          qty: qty,
          addedAt: DateTime.now(),
        ),
      );
    }
    _changed();
  }

  void changeQty(String tableId, String lineId, int delta) {
    final t = tableById(tableId);
    if (t == null) return;
    final idx = t.lines.indexWhere((l) => l.id == lineId);
    if (idx < 0) return;
    final line = t.lines[idx];
    line.qty += delta;
    if (line.qty <= 0) t.lines.removeAt(idx);
    if (t.lines.isEmpty) t.openedAt = null;
    _changed();
  }

  void removeLine(String tableId, String lineId) {
    final t = tableById(tableId);
    if (t == null) return;
    t.lines.removeWhere((l) => l.id == lineId);
    if (t.lines.isEmpty) t.openedAt = null;
    _changed();
  }

  void setLineNote(String tableId, String lineId, String note) {
    final t = tableById(tableId);
    if (t == null) return;
    for (final l in t.lines) {
      if (l.id == lineId) l.note = note.trim();
    }
    _changed();
  }

  /// Buyurtmani bekor qilish - chek yaratilmaydi.
  void cancelOrder(String tableId) {
    final t = tableById(tableId);
    if (t == null) return;
    t.lines = <OrderLine>[];
    t.openedAt = null;
    _changed();
  }

  /// Stolni ko'chirish - butun buyurtma boshqa stolga o'tadi.
  bool moveOrder(String fromId, String toId) {
    final a = tableById(fromId);
    final b = tableById(toId);
    if (a == null || b == null || b.isBusy) return false;
    b.lines = a.lines;
    b.openedAt = a.openedAt;
    a.lines = <OrderLine>[];
    a.openedAt = null;
    _changed();
    return true;
  }

  /// To'lov qabul qilinib, stol yopiladi.
  Future<Receipt> closeTable(
    String tableId, {
    required int discountPercent,
    required String method,
    int cashGiven = 0,
    String note = "",
  }) async {
    final t = tableById(tableId)!;
    final subtotal = t.subtotal;
    final discount = subtotal * discountPercent ~/ 100;
    final service =
        (subtotal - discount) * settings.servicePercent ~/ 100;
    final total = subtotal - discount + service;

    final r = Receipt(
      id: newId(),
      tableId: t.id,
      tableName: t.name,
      zone: t.zone,
      openedAt: t.openedAt ?? DateTime.now(),
      closedAt: DateTime.now(),
      lines: t.lines
          .map(
            (l) => OrderLine(
              id: l.id,
              itemId: l.itemId,
              name: l.name,
              price: l.price,
              qty: l.qty,
              note: l.note,
              addedAt: l.addedAt,
            ),
          )
          .toList(),
      subtotal: subtotal,
      discount: discount,
      service: service,
      total: total,
      method: method,
      cashGiven: cashGiven,
      note: note,
    );

    receipts.insert(0, r);
    await _receiptDb.putAll([r]);
    t.lines = <OrderLine>[];
    t.openedAt = null;
    _changed();
    return r;
  }

  // ------------------------------------------------------------------ menyu

  List<MenuItem> itemsOf(String category) =>
      menu.where((m) => m.category == category).toList();

  void addCategory(String name) {
    final n = name.trim();
    if (n.isEmpty || categories.contains(n)) return;
    categories.add(n);
    _changed();
  }

  void renameCategory(String oldName, String newName) {
    final n = newName.trim();
    if (n.isEmpty) return;
    final i = categories.indexOf(oldName);
    if (i < 0) return;
    categories[i] = n;
    for (final m in menu) {
      if (m.category == oldName) m.category = n;
    }
    _changed();
  }

  void deleteCategory(String name) {
    categories.remove(name);
    menu.removeWhere((m) => m.category == name);
    _changed();
  }

  MenuItem addItem(String name, int price, String category, String icon) {
    final item = MenuItem(
      id: newId(),
      name: name.trim(),
      price: price,
      category: category,
      icon: icon,
    );
    menu.add(item);
    if (!categories.contains(category)) categories.add(category);
    _changed();
    return item;
  }

  void updateItem(
    String id,
    String name,
    int price,
    String category,
    String icon,
  ) {
    for (final m in menu) {
      if (m.id == id) {
        m.name = name.trim();
        m.price = price;
        m.category = category;
        m.icon = icon;
      }
    }
    if (!categories.contains(category)) categories.add(category);
    _changed();
  }

  void deleteItem(String id) {
    menu.removeWhere((m) => m.id == id);
    _changed();
  }

  // --------------------------------------------------------------- hisobot

  List<Receipt> receiptsBetween(DateTime from, DateTime to) => receipts
      .where((r) => r.closedAt.isAfter(from) && r.closedAt.isBefore(to))
      .toList();

  List<Receipt> get todayReceipts {
    final now = DateTime.now();
    return receipts.where((r) => sameDay(r.closedAt, now)).toList();
  }

  int get todayRevenue =>
      todayReceipts.fold(0, (s, r) => s + r.total);

  int get openTablesCount => tables.where((t) => t.isBusy).length;

  int get openTablesTotal =>
      tables.fold(0, (s, t) => s + t.subtotal);

  Future<void> deleteReceipt(String id) async {
    receipts.removeWhere((r) => r.id == id);
    await _receiptDb.delete(id);
    _changed();
  }

  // ------------------------------------------------------------- bulut bilan

  /// Bulutga yuboriladigan holat (cheklar alohida jadvalda).
  Map<String, Object?> stateForRemote() => {
        "tables": tables.map((e) => e.toJson()).toList(),
        "menu": menu.map((e) => e.toJson()).toList(),
        "categories": categories,
        "settings": {
          ...settings.toJson(),
          "pin": _encodePin(settings.pin),
        },
      };

  /// Bulutdagi holatni shu qurilmaga o'rnatadi.
  void applyRemoteState(Map<String, Object?> data, DateTime updatedAt) {
    tables = (data["tables"] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(BarTable.fromJson)
        .toList();
    menu = (data["menu"] as List<Object?>? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(MenuItem.fromJson)
        .toList();
    categories = (data["categories"] as List<Object?>? ?? const [])
        .whereType<String>()
        .toList();
    final st = data["settings"];
    if (st is Map<String, Object?>) {
      settings = AppSettings.fromJson(st);
      settings.pin = _decodePin(settings.pin);
    }
    remoteUpdatedAt = updatedAt;
    _persist();
    notifyListeners();
  }

  /// Bulutdan kelgan cheklarni qo'shadi (mavjudlari tegilmaydi).
  Future<void> mergeRemoteReceipts(List<Receipt> incoming) async {
    final known = receipts.map((r) => r.id).toSet();
    final fresh = incoming.where((r) => !known.contains(r.id)).toList();
    if (fresh.isEmpty) return;
    receipts.addAll(fresh);
    receipts.sort((a, b) => b.closedAt.compareTo(a.closedAt));
    await _receiptDb.putAll(fresh);
    notifyListeners();
  }

  List<Receipt> get unsyncedReceipts =>
      receipts.where((r) => !r.synced).toList();

  Future<void> markReceiptsSynced(Iterable<String> ids) async {
    final set = ids.toSet();
    final changed = <Receipt>[];
    for (final r in receipts) {
      if (set.contains(r.id)) {
        r.synced = true;
        changed.add(r);
      }
    }
    await _receiptDb.putAll(changed);
  }

  void setRemoteUpdatedAt(DateTime at) {
    remoteUpdatedAt = at;
    _persist();
  }

  /// Bu qurilmada haqiqiy ish qilinganmi (yoki hali namuna holatidami).
  bool get hasLocalWork => receipts.isNotEmpty || tables.any((t) => t.isBusy);

  // ------------------------------------------------------- boshlang'ich baza

  void _seed() {
    settings = AppSettings();
    tables = <BarTable>[
      for (var i = 1; i <= 6; i++)
        BarTable(id: newId(), name: "Stol $i", zone: "Zal", seats: 4),
      for (var i = 1; i <= 3; i++)
        BarTable(id: newId(), name: "Terassa $i", zone: "Terassa", seats: 6),
      BarTable(id: newId(), name: "VIP 1", zone: "VIP", seats: 8),
      BarTable(id: newId(), name: "Bar 1", zone: "Bar", seats: 2),
      BarTable(id: newId(), name: "Bar 2", zone: "Bar", seats: 2),
    ];

    categories = <String>[
      "Pivo",
      "Kokteyl",
      "Ichimliklar",
      "Gazaklar",
      "Issiq taomlar",
      "Shirinliklar",
    ];

    const seedMenu = <List<Object>>[
      ["Sarbast 0.5", 22000, "Pivo", "pivo"],
      ["Qibray 0.5", 20000, "Pivo", "pivo"],
      ["Corona Extra", 38000, "Pivo", "pivo"],
      ["Bochka pivo 0.5", 25000, "Pivo", "pivo"],
      ["Bochka pivo 1.0", 45000, "Pivo", "pivo"],
      ["Mojito", 45000, "Kokteyl", "kokteyl"],
      ["Margarita", 55000, "Kokteyl", "kokteyl"],
      ["Long Island", 65000, "Kokteyl", "kokteyl"],
      ["Pina Colada", 58000, "Kokteyl", "kokteyl"],
      ["Coca-Cola 0.5", 12000, "Ichimliklar", "gazli"],
      ["Fanta 0.5", 12000, "Ichimliklar", "gazli"],
      ["Suv 0.5", 5000, "Ichimliklar", "suv"],
      ["Choy", 8000, "Ichimliklar", "choy"],
      ["Kofe", 15000, "Ichimliklar", "kofe"],
      ["Energetik", 18000, "Ichimliklar", "energetik"],
      ["Fistashka", 28000, "Gazaklar", "gazak"],
      ["Yong'oq assorti", 35000, "Gazaklar", "gazak"],
      ["Quritilgan baliq", 30000, "Gazaklar", "baliq"],
      ["Chips", 15000, "Gazaklar", "gazak"],
      ["Kartoshka fri", 25000, "Issiq taomlar", "kartoshka"],
      ["Tovuq qanotchalari", 48000, "Issiq taomlar", "taom"],
      ["Shashlik (1 dona)", 35000, "Issiq taomlar", "kabob"],
      ["Lavash", 32000, "Issiq taomlar", "fastfud"],
      ["Muzqaymoq", 20000, "Shirinliklar", "muzqaymoq"],
      ["Tort bo'lagi", 25000, "Shirinliklar", "shirinlik"],
    ];

    menu = seedMenu
        .map(
          (row) => MenuItem(
            id: newId(),
            name: row[0] as String,
            price: row[1] as int,
            category: row[2] as String,
            icon: row[3] as String,
          ),
        )
        .toList();
  }
}

final AppStore store = AppStore.instance;
