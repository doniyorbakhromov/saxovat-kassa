import "package:idb_shim/idb_client.dart";

import "../models.dart";
import "idb_factory_stub.dart"
    if (dart.library.js_interop) "idb_factory_web.dart";

/// Cheklar arxivi.
///
/// Cheklar brauzerning IndexedDB bazasida saqlanadi - localStorage'dan
/// farqli o'laroq unda amaliy hajm chegarasi yo'q va yangi chek qo'shilganda
/// butun arxiv emas, faqat o'sha bitta yozuv yoziladi.
class ReceiptDb {
  static const String _dbName = "saxovat_kassa";
  static const String _storeName = "receipts";
  static const String _byClosedAt = "closedAt";

  Database? _db;

  bool get isOpen => _db != null;

  Future<void> open() async {
    if (_db != null) return;
    _db = await openIdbFactory().open(
      _dbName,
      version: 1,
      onUpgradeNeeded: (VersionChangeEvent e) {
        final db = e.database;
        if (!db.objectStoreNames.contains(_storeName)) {
          final store = db.createObjectStore(_storeName, keyPath: "id");
          store.createIndex(_byClosedAt, "closedAt");
        }
      },
    );
  }

  /// Barcha cheklar, yangisidan eskisiga qarab.
  Future<List<Receipt>> loadAll() async {
    final db = _db;
    if (db == null) return <Receipt>[];
    final txn = db.transaction(_storeName, idbModeReadOnly);
    final rows = await txn.objectStore(_storeName).getAll();
    await txn.completed;

    final list = <Receipt>[];
    for (final row in rows) {
      if (row is Map) {
        list.add(Receipt.fromJson(Map<String, Object?>.from(row)));
      }
    }
    list.sort((a, b) => b.closedAt.compareTo(a.closedAt));
    return list;
  }

  Future<void> putAll(Iterable<Receipt> list) async {
    final db = _db;
    if (db == null || list.isEmpty) return;
    final txn = db.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);
    for (final r in list) {
      await store.put(r.toJson());
    }
    await txn.completed;
  }

  Future<void> delete(String id) async {
    final db = _db;
    if (db == null) return;
    final txn = db.transaction(_storeName, idbModeReadWrite);
    await txn.objectStore(_storeName).delete(id);
    await txn.completed;
  }

  Future<void> close() async {
    _db?.close();
    _db = null;
  }

  Future<int> count() async {
    final db = _db;
    if (db == null) return 0;
    final txn = db.transaction(_storeName, idbModeReadOnly);
    final n = await txn.objectStore(_storeName).count();
    await txn.completed;
    return n;
  }
}
