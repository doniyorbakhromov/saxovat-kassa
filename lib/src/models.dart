import "utils.dart";

/// Menyudagi mahsulot.
class MenuItem {
  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.icon = "boshqa",
    this.active = true,
  });

  final String id;
  String name;
  int price;
  String category;
  String icon;
  bool active;

  Map<String, Object?> toJson() => {
        "id": id,
        "name": name,
        "price": price,
        "category": category,
        "icon": icon,
        "active": active,
      };

  static MenuItem fromJson(Map<String, Object?> j) => MenuItem(
        id: asStr(j["id"], newId()),
        name: asStr(j["name"], "Nomsiz"),
        price: asInt(j["price"]),
        category: asStr(j["category"], "Boshqa"),
        icon: asStr(j["icon"], "boshqa"),
        active: j["active"] != false,
      );
}

/// Stoldagi buyurtmaning bitta qatori.
class OrderLine {
  OrderLine({
    required this.id,
    required this.itemId,
    required this.name,
    required this.price,
    required this.qty,
    required this.addedAt,
    this.note = "",
  });

  final String id;
  final String itemId;
  final String name;
  final int price;
  int qty;
  String note;
  final DateTime addedAt;

  int get total => price * qty;

  Map<String, Object?> toJson() => {
        "id": id,
        "itemId": itemId,
        "name": name,
        "price": price,
        "qty": qty,
        "note": note,
        "addedAt": addedAt.toIso8601String(),
      };

  static OrderLine fromJson(Map<String, Object?> j) => OrderLine(
        id: asStr(j["id"], newId()),
        itemId: asStr(j["itemId"]),
        name: asStr(j["name"], "Nomsiz"),
        price: asInt(j["price"]),
        qty: asInt(j["qty"], 1),
        note: asStr(j["note"]),
        addedAt:
            DateTime.tryParse(asStr(j["addedAt"])) ?? DateTime.now(),
      );
}

/// Bar stoli.
class BarTable {
  BarTable({
    required this.id,
    required this.name,
    this.zone = "Zal",
    this.seats = 4,
    List<OrderLine>? lines,
    this.openedAt,
  }) : lines = lines ?? <OrderLine>[];

  final String id;
  String name;
  String zone;
  int seats;
  List<OrderLine> lines;
  DateTime? openedAt;

  bool get isBusy => openedAt != null;
  int get itemCount => lines.fold(0, (s, l) => s + l.qty);
  int get subtotal => lines.fold(0, (s, l) => s + l.total);

  Map<String, Object?> toJson() => {
        "id": id,
        "name": name,
        "zone": zone,
        "seats": seats,
        "openedAt": openedAt?.toIso8601String(),
        "lines": lines.map((l) => l.toJson()).toList(),
      };

  static BarTable fromJson(Map<String, Object?> j) => BarTable(
        id: asStr(j["id"], newId()),
        name: asStr(j["name"], "Stol"),
        zone: asStr(j["zone"], "Zal"),
        seats: asInt(j["seats"], 4),
        openedAt: DateTime.tryParse(asStr(j["openedAt"])),
        lines: (j["lines"] as List<Object?>? ?? const [])
            .whereType<Map<String, Object?>>()
            .map(OrderLine.fromJson)
            .toList(),
      );
}

/// Yopilgan buyurtma - chek.
class Receipt {
  Receipt({
    required this.id,
    required this.tableId,
    required this.tableName,
    required this.zone,
    required this.openedAt,
    required this.closedAt,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.service,
    required this.total,
    required this.method,
    this.cashGiven = 0,
    this.note = "",
    this.synced = false,
  });

  final String id;
  final String tableId;
  final String tableName;
  final String zone;
  final DateTime openedAt;
  final DateTime closedAt;
  final List<OrderLine> lines;
  final int subtotal;
  final int discount;
  final int service;
  final int total;
  final String method;
  final int cashGiven;
  final String note;

  /// Bulutga yuborilganmi. Faqat shu qurilmada saqlanadi.
  bool synced;

  int get change => cashGiven > total ? cashGiven - total : 0;
  int get itemCount => lines.fold(0, (s, l) => s + l.qty);
  Duration get duration => closedAt.difference(openedAt);

  Map<String, Object?> toJson() => {
        "id": id,
        "tableId": tableId,
        "tableName": tableName,
        "zone": zone,
        "openedAt": openedAt.toIso8601String(),
        "closedAt": closedAt.toIso8601String(),
        "lines": lines.map((l) => l.toJson()).toList(),
        "subtotal": subtotal,
        "discount": discount,
        "service": service,
        "total": total,
        "method": method,
        "cashGiven": cashGiven,
        "note": note,
        "synced": synced,
      };

  /// Supabase `receipts` jadvali uchun qator.
  Map<String, Object?> toRow() => {
        "id": id,
        "table_id": tableId,
        "table_name": tableName,
        "zone": zone,
        "opened_at": openedAt.toUtc().toIso8601String(),
        "closed_at": closedAt.toUtc().toIso8601String(),
        "lines": lines.map((l) => l.toJson()).toList(),
        "subtotal": subtotal,
        "discount": discount,
        "service": service,
        "total": total,
        "method": method,
        "cash_given": cashGiven,
        "note": note,
      };

  static Receipt fromRow(Map<String, Object?> r) {
    final now = DateTime.now();
    return Receipt(
      id: asStr(r["id"], newId()),
      tableId: asStr(r["table_id"]),
      tableName: asStr(r["table_name"], "Stol"),
      zone: asStr(r["zone"], "Zal"),
      openedAt: (DateTime.tryParse(asStr(r["opened_at"])) ?? now).toLocal(),
      closedAt: (DateTime.tryParse(asStr(r["closed_at"])) ?? now).toLocal(),
      lines: (r["lines"] as List<Object?>? ?? const [])
          .whereType<Map<String, Object?>>()
          .map(OrderLine.fromJson)
          .toList(),
      subtotal: asInt(r["subtotal"]),
      discount: asInt(r["discount"]),
      service: asInt(r["service"]),
      total: asInt(r["total"]),
      method: asStr(r["method"], "Naqd"),
      cashGiven: asInt(r["cash_given"]),
      note: asStr(r["note"]),
      synced: true,
    );
  }

  static Receipt fromJson(Map<String, Object?> j) {
    final now = DateTime.now();
    return Receipt(
      id: asStr(j["id"], newId()),
      tableId: asStr(j["tableId"]),
      tableName: asStr(j["tableName"], "Stol"),
      zone: asStr(j["zone"], "Zal"),
      openedAt: DateTime.tryParse(asStr(j["openedAt"])) ?? now,
      closedAt: DateTime.tryParse(asStr(j["closedAt"])) ?? now,
      lines: (j["lines"] as List<Object?>? ?? const [])
          .whereType<Map<String, Object?>>()
          .map(OrderLine.fromJson)
          .toList(),
      subtotal: asInt(j["subtotal"]),
      discount: asInt(j["discount"]),
      service: asInt(j["service"]),
      total: asInt(j["total"]),
      method: asStr(j["method"], "Naqd"),
      cashGiven: asInt(j["cashGiven"]),
      note: asStr(j["note"]),
      synced: j["synced"] == true,
    );
  }
}

/// Kassa sozlamalari.
class AppSettings {
  AppSettings({
    this.venueName = "SAXOVAT BAR",
    this.servicePercent = 0,
    this.pin = "1234",
  });

  String venueName;
  int servicePercent;
  String pin;

  Map<String, Object?> toJson() => {
        "venueName": venueName,
        "servicePercent": servicePercent,
        "pin": pin,
      };

  static AppSettings fromJson(Map<String, Object?> j) => AppSettings(
        venueName: asStr(j["venueName"], "SAXOVAT BAR"),
        servicePercent: asInt(j["servicePercent"]),
        pin: asStr(j["pin"], "1234"),
      );
}
