import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:saxovat_kassa/src/screens/menu_page.dart";
import "package:saxovat_kassa/src/store.dart";
import "package:saxovat_kassa/src/theme.dart";
import "package:saxovat_kassa/src/widgets/common.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.resetStorageForTest();
    await store.init();
  });

  Future<void> openMenu(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: MenuPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets("kategoriya tanlanganda tahrirlash tugmasi chiqadi", (
    tester,
  ) async {
    await openMenu(tester);

    // Boshida "Hammasi" tanlangan - u tahrirlanmaydi.
    expect(find.byIcon(Icons.edit_rounded), findsNothing);

    await tester.tap(find.widgetWithText(ChipButton, "Pivo").first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
  });

  testWidgets("kategoriya oynasi xatosiz ochiladi", (tester) async {
    await openMenu(tester);

    await tester.tap(find.widgetWithText(ChipButton, "Pivo").first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    // Oynaning uch qismi ham joyida bo'lsin.
    expect(find.text("Kategoriya"), findsOneWidget);
    expect(find.text("Kategoriya nomi"), findsOneWidget);
    expect(find.text("Kategoriyani o'chirish"), findsOneWidget);
    expect(find.text("Saqlash"), findsOneWidget);
    expect(find.text("Bekor qilish"), findsOneWidget);

    // Nechta mahsulot borligi aytilsin.
    final count = store.itemsOf("Pivo").length;
    expect(find.textContaining("$count ta mahsulot"), findsWidgets);
  });

  testWidgets("nomni o'zgartirish mahsulotlarga ham tegadi", (tester) async {
    await openMenu(tester);
    final before = store.itemsOf("Pivo").length;

    await tester.tap(find.widgetWithText(ChipButton, "Pivo").first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, "Pivolar");
    await tester.tap(find.text("Saqlash"));
    await tester.pumpAndSettle();

    expect(store.categories.contains("Pivolar"), isTrue);
    expect(store.categories.contains("Pivo"), isFalse);
    expect(store.itemsOf("Pivolar").length, before);
  });
}
