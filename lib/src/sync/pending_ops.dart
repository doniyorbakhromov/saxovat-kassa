import "../utils.dart";

/// Bulutga yuborilishi kerak bo'lgan bitta amal.
class PendingOp {
  PendingOp({
    required this.entity,
    required this.rowId,
    required this.isDelete,
    required this.data,
    required this.at,
  });

  /// Jadval nomi: tables, order_lines, menu_items, categories,
  /// settings, receipts.
  final String entity;
  final String rowId;
  final bool isDelete;
  final Map<String, Object?> data;
  final DateTime at;

  String get key => "$entity:$rowId";

  Map<String, Object?> toJson() => {
        "entity": entity,
        "rowId": rowId,
        "isDelete": isDelete,
        "data": data,
        "at": at.toIso8601String(),
      };

  static PendingOp fromJson(Map<String, Object?> j) => PendingOp(
        entity: asStr(j["entity"]),
        rowId: asStr(j["rowId"]),
        isDelete: j["isDelete"] == true,
        data: (j["data"] as Map?)?.cast<String, Object?>() ??
            <String, Object?>{},
        at: DateTime.tryParse(asStr(j["at"])) ?? DateTime.now(),
      );
}

/// Yuborilmagan amallar navbati.
///
/// Internet uzilganda amallar shu yerda to'planadi va ulanish tiklanishi
/// bilan ketma-ket yuboriladi. Bir qatorga bir nechta o'zgarish tushsa,
/// faqat oxirgisi saqlanadi - eskisini yuborishning ma'nosi yo'q.
class OpQueue {
  final Map<String, PendingOp> _ops = <String, PendingOp>{};

  bool get isEmpty => _ops.isEmpty;
  bool get isNotEmpty => _ops.isNotEmpty;
  int get length => _ops.length;

  /// Jadvallarning yuborilish tartibi.
  ///
  /// Buyurtma qatori o'z stoliga bog'langan, shuning uchun stollar
  /// oldin ketishi shart - aks holda baza qatorni rad etadi.
  static const Map<String, int> _order = {
    "tables": 0,
    "categories": 1,
    "menu_items": 2,
    "order_lines": 3,
    "settings": 4,
    "receipts": 5,
  };

  /// Yuborish tartibida: avval bog'liqlik bo'yicha, keyin vaqt bo'yicha.
  List<PendingOp> get pending {
    final list = _ops.values.toList();
    list.sort((a, b) {
      final byEntity = (_order[a.entity] ?? 9).compareTo(_order[b.entity] ?? 9);
      return byEntity != 0 ? byEntity : a.at.compareTo(b.at);
    });
    return list;
  }

  bool hasRow(String entity, String rowId) =>
      _ops.containsKey("$entity:$rowId");

  void upsert(String entity, String rowId, Map<String, Object?> data) {
    _ops["$entity:$rowId"] = PendingOp(
      entity: entity,
      rowId: rowId,
      isDelete: false,
      data: data,
      at: DateTime.now(),
    );
  }

  void delete(String entity, String rowId) {
    _ops["$entity:$rowId"] = PendingOp(
      entity: entity,
      rowId: rowId,
      isDelete: true,
      data: const <String, Object?>{},
      at: DateTime.now(),
    );
  }

  /// Muvaffaqiyatli yuborilganlarni navbatdan chiqaradi.
  /// Yuborish paytida o'sha qator yana o'zgargan bo'lsa - qoldiriladi.
  void done(Iterable<PendingOp> sent) {
    for (final op in sent) {
      final current = _ops[op.key];
      if (current != null && current.at == op.at) _ops.remove(op.key);
    }
  }

  void clear() => _ops.clear();

  List<Object?> toJson() => _ops.values.map((o) => o.toJson()).toList();

  void loadJson(List<Object?> list) {
    _ops.clear();
    for (final e in list) {
      if (e is Map) {
        final op = PendingOp.fromJson(e.cast<String, Object?>());
        _ops[op.key] = op;
      }
    }
  }
}
