import "package:flutter_test/flutter_test.dart";
import "package:saxovat_kassa/src/store.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.init();
  });

  test("boshlang'ich holatda stollar va menyu mavjud", () {
    expect(store.tables.length, greaterThan(0));
    expect(store.menu.length, greaterThan(0));
    expect(store.openTablesCount, 0);
  });

  test("parol tekshiruvi ishlaydi", () {
    expect(store.login("0000"), isFalse);
    expect(store.login("1234"), isTrue);
    expect(store.unlocked, isTrue);
    store.logout();
    expect(store.unlocked, isFalse);
  });

  test("mahsulot qo'shilganda stol band bo'ladi va summa hisoblanadi", () {
    final t = store.tables.first;
    final item = store.menu.firstWhere((m) => m.price > 0);

    store.addToOrder(t.id, item, qty: 2);
    expect(t.isBusy, isTrue);
    expect(t.itemCount, 2);
    expect(t.subtotal, item.price * 2);

    store.addToOrder(t.id, item);
    expect(t.lines.length, 1, reason: "bir xil mahsulot bitta qatorga qo'shiladi");
    expect(t.itemCount, 3);
  });

  test("miqdor nolga tushsa qator o'chadi va stol bo'shaydi", () {
    final t = store.tables.first;
    final item = store.menu.first;
    store.addToOrder(t.id, item);
    store.changeQty(t.id, t.lines.first.id, -1);
    expect(t.lines, isEmpty);
    expect(t.isBusy, isFalse);
  });

  test("to'lovda chegirma va xizmat haqi to'g'ri hisoblanadi", () {
    store.setServicePercent(10);
    final t = store.tables.first;
    final item = store.addItem("Test mahsulot", 100000, "Pivo", "pivo");
    store.addToOrder(t.id, item);

    final r = store.closeTable(
      t.id,
      discountPercent: 10,
      method: "Naqd",
      cashGiven: 100000,
    );

    expect(r.subtotal, 100000);
    expect(r.discount, 10000);
    expect(r.service, 9000);
    expect(r.total, 99000);
    expect(r.change, 1000);
  });

  test("stol yopilgach chek saqlanadi va stol bo'shaydi", () {
    final t = store.tables.first;
    store.addToOrder(t.id, store.menu.first);
    store.closeTable(t.id, discountPercent: 0, method: "Karta");

    expect(t.isBusy, isFalse);
    expect(t.lines, isEmpty);
    expect(store.receipts.length, 1);
    expect(store.todayReceipts.length, 1);
    expect(store.todayRevenue, store.receipts.first.total);
  });

  test("buyurtmani boshqa stolga ko'chirish", () {
    final a = store.tables[0];
    final b = store.tables[1];
    store.addToOrder(a.id, store.menu.first, qty: 3);

    expect(store.moveOrder(a.id, b.id), isTrue);
    expect(a.isBusy, isFalse);
    expect(b.itemCount, 3);
  });

  test("buyurtmani bekor qilishda chek yaratilmaydi", () {
    final t = store.tables.first;
    store.addToOrder(t.id, store.menu.first);
    store.cancelOrder(t.id);

    expect(t.isBusy, isFalse);
    expect(store.receipts, isEmpty);
  });

  test("ko'p stol qo'shish va nomlar takrorlanmasligi", () {
    final before = store.tables.length;
    final n = store.addTables("Yangi", "Terassa", 4, 5);

    expect(n, 5);
    expect(store.tables.length, before + 5);
    expect(store.tables.last.name, "Yangi 5");

    // Ayni nom bilan yana qo'shsak, mavjudlari o'tkazib yuboriladi.
    store.addTables("Yangi", "Terassa", 4, 3);
    final names = store.tables.map((t) => t.name).toList();
    expect(names.toSet().length, names.length, reason: "nomlar takrorlanmasin");
  });

  test("kategoriya o'chirilsa undagi mahsulotlar ham o'chadi", () {
    final before = store.itemsOf("Pivo").length;
    expect(before, greaterThan(0));
    store.deleteCategory("Pivo");
    expect(store.itemsOf("Pivo"), isEmpty);
    expect(store.categories.contains("Pivo"), isFalse);
  });
}
