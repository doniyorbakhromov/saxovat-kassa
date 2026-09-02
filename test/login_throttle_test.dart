import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:saxovat_kassa/src/screens/login_screen.dart";
import "package:saxovat_kassa/src/store.dart";
import "package:saxovat_kassa/src/theme.dart";
import "package:shared_preferences/shared_preferences.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.resetStorageForTest();
    await store.init();
    store.logout();
  });

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final d in pin.split("")) {
      await tester.tap(find.widgetWithText(GestureDetector, d).first);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets("besh marta xato terilsa kutish boshlanadi", (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const LoginScreen()),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await typePin(tester, "9999");
      expect(
        find.textContaining("Parol noto'g'ri"),
        findsOneWidget,
        reason: "${i + 1}-urinishdan keyin oddiy xato bo'lishi kerak",
      );
    }

    // Beshinchisi kutishni boshlaydi.
    await typePin(tester, "9999");
    expect(find.textContaining("Juda ko'p urinish"), findsOneWidget);

    // Qulf paytida to'g'ri parol ham qabul qilinmaydi.
    await typePin(tester, "1234");
    expect(store.unlocked, isFalse);
    expect(find.textContaining("Juda ko'p urinish"), findsOneWidget);
  });

  testWidgets("to'g'ri parol kiritilsa kassa ochiladi", (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildAppTheme(), home: const LoginScreen()),
    );
    await tester.pumpAndSettle();

    await typePin(tester, "1234");
    expect(store.unlocked, isTrue);
  });
}
