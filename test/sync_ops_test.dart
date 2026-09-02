import "package:flutter_test/flutter_test.dart";
import "package:saxovat_kassa/src/store.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.resetStorageForTest();
    await store.init();
    store.trackOps = true;
    store.ops.clear();
  });

  List<String> keysOf() => store.ops.pending.map((o) => o.key).toList();

  test("bulutga ulanmagan qurilma navbat yig'maydi", () {
    store.trackOps = false;
    store.ops.clear();

    store.addTable("Sinov", "Zal", 4);
    store.addToOrder(store.tables.first.id, store.menu.first);

    expect(store.ops.isEmpty, isTrue);
  });

  test("stol qo'shilsa navbatga tushadi", () {
    final t = store.addTable("Sinov", "Terassa", 6);
    expect(keysOf(), contains("tables:${t.id}"));
  });

  test("zakaz qo'shilganda stol va qator alohida yoziladi", () {
    final t = store.tables.first;
    store.ops.clear();
    store.addToOrder(t.id, store.menu.first);

    final keys = keysOf();
    expect(keys, contains("tables:${t.id}"), reason: "stol ochildi");
    expect(
      keys.where((k) => k.startsWith("order_lines:")).length,
      1,
      reason: "bitta buyurtma qatori",
    );
  });

  test("bir qatorga ko'p o'zgarish - navbatda bitta yozuv", () {
    final t = store.tables.first;
    store.addToOrder(t.id, store.menu.first);
    store.ops.clear();

    final line = t.lines.first;
    store.changeQty(t.id, line.id, 1);
    store.changeQty(t.id, line.id, 1);
    store.changeQty(t.id, line.id, 1);

    expect(
      keysOf().where((k) => k == "order_lines:${line.id}").length,
      1,
      reason: "eski qiymatlarni yuborishning ma'nosi yo'q",
    );
    expect(store.ops.pending.last.data["qty"], line.qty);
  });

  test("qator o'chirilsa navbatda o'chirish turadi", () {
    final t = store.tables.first;
    store.addToOrder(t.id, store.menu.first);
    final lineId = t.lines.first.id;
    store.ops.clear();

    store.removeLine(t.id, lineId);

    final op = store.ops.pending
        .firstWhere((o) => o.key == "order_lines:$lineId");
    expect(op.isDelete, isTrue);
  });

  test("bulutdan kelgan o'zgarish yangi navbat yaratmaydi", () {
    final t = store.tables.first;
    store.ops.clear();

    store.applyRemoteTable({
      "id": t.id,
      "name": "Boshqa nom",
      "zone": "VIP",
      "seats": 8,
      "opened_at": null,
    });

    expect(store.tableById(t.id)!.name, "Boshqa nom");
    expect(store.ops.isEmpty, isTrue, reason: "aks-sado bo'lmasin");
  });

  test("yuborilmagan o'zgarish bulutdagi eski nusxadan ustun", () {
    final t = store.tables.first;
    store.editTable(t.id, "Mahalliy nom", "Zal", 4);

    // Ayni damda bulutdan eski nusxa kelib qoldi.
    store.applyRemoteTable({
      "id": t.id,
      "name": "Eski nom",
      "zone": "Zal",
      "seats": 4,
      "opened_at": null,
    });

    expect(
      store.tableById(t.id)!.name,
      "Mahalliy nom",
      reason: "hali yuborilmagan o'zgarish saqlanib qolishi kerak",
    );
  });

  test("bulutdan kelgan qator to'g'ri stolga tushadi", () {
    final t = store.tables[1];
    store.ops.clear();

    store.applyRemoteLine({
      "id": "boshqa_qurilma_1",
      "table_id": t.id,
      "item_id": "x",
      "name": "Mojito",
      "price": 45000,
      "qty": 2,
      "note": "",
      "added_at": DateTime.now().toUtc().toIso8601String(),
    });

    expect(t.lines.length, 1);
    expect(t.lines.first.name, "Mojito");
    expect(t.subtotal, 90000);
  });

  test("navbat bog'liqlik tartibida yuboriladi", () {
    final t = store.tables.first;
    store.addToOrder(t.id, store.menu.first);
    store.addItem("Yangi ichimlik", 10000, "Pivo", "pivo");

    final order = store.ops.pending.map((o) => o.entity).toList();
    final tableIdx = order.indexOf("tables");
    final lineIdx = order.indexOf("order_lines");

    expect(tableIdx, greaterThanOrEqualTo(0));
    expect(lineIdx, greaterThanOrEqualTo(0));
    expect(
      tableIdx,
      lessThan(lineIdx),
      reason: "stol buyurtma qatoridan oldin yuborilishi kerak",
    );
  });

  test("bir xil jadval amallari ketma-ket turadi (guruhlash uchun)", () {
    store.addTable("A", "Zal", 4);
    store.addTable("B", "Zal", 4);
    store.addItem("X", 1000, "Pivo", "pivo");
    store.addItem("Y", 2000, "Pivo", "pivo");

    // Bir xil jadval amallari uzluksiz bo'lak bo'lib turishi kerak,
    // aks holda ular bitta so'rovga birlashmaydi.
    final entities = store.ops.pending.map((o) => o.entity).toList();
    final blocks = <String>[];
    for (final e in entities) {
      if (blocks.isEmpty || blocks.last != e) blocks.add(e);
    }
    expect(
      blocks.length,
      blocks.toSet().length,
      reason: "har bir jadval bir marta uchrashi kerak: $blocks",
    );
  });

  test("stol yopilganda chek va qator o'chirish navbatga tushadi", () async {
    final t = store.tables.first;
    store.addToOrder(t.id, store.menu.first);
    final lineId = t.lines.first.id;
    store.ops.clear();

    final r = await store.closeTable(
      t.id,
      discountPercent: 0,
      method: "Naqd",
    );

    final keys = keysOf();
    expect(keys, contains("receipts:${r.id}"));
    expect(keys, contains("order_lines:$lineId"));
    expect(
      store.ops.pending.firstWhere((o) => o.key == "order_lines:$lineId")
          .isDelete,
      isTrue,
    );
  });
}
