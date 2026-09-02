import "package:flutter/material.dart";

class Ink3 {
  Ink3._();

  static const Color bg = Color(0xFF0A0D14);
  static const Color bgSoft = Color(0xFF10141E);
  static const Color card = Color(0xFF161B27);
  static const Color cardHi = Color(0xFF1D2331);
  static const Color stroke = Color(0xFF262E40);
  static const Color strokeSoft = Color(0xFF1E2532);

  static const Color gold = Color(0xFFF3B21B);
  static const Color goldSoft = Color(0xFFFFD36B);
  static const Color green = Color(0xFF32C48D);
  static const Color red = Color(0xFFF05B5B);
  static const Color blue = Color(0xFF5B8DEF);
  static const Color violet = Color(0xFF9B7BFF);

  static const Color text = Color(0xFFEDF0F7);
  static const Color textDim = Color(0xFF8C97AF);
  static const Color textFaint = Color(0xFF5C667C);

  static const LinearGradient goldGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD36B), Color(0xFFF3B21B)],
  );

  static const LinearGradient bgGrad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1119), Color(0xFF0A0D14), Color(0xFF0C1018)],
  );

  static List<BoxShadow> soft([double o = 0.35]) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: o),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> glow(Color c, [double o = 0.30]) => [
        BoxShadow(
          color: c.withValues(alpha: o),
          blurRadius: 26,
          spreadRadius: -6,
          offset: const Offset(0, 8),
        ),
      ];
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Ink3.gold,
    onPrimary: Color(0xFF20180A),
    secondary: Ink3.blue,
    onSecondary: Colors.white,
    error: Ink3.red,
    onError: Colors.white,
    surface: Ink3.card,
    onSurface: Ink3.text,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: Ink3.bg,
    canvasColor: Ink3.bg,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Ink3.text,
      displayColor: Ink3.text,
    ),
    dividerTheme: const DividerThemeData(
      color: Ink3.strokeSoft,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: Ink3.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Ink3.stroke),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Ink3.bgSoft,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Ink3.stroke),
      ),
      titleTextStyle: const TextStyle(
        color: Ink3.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Ink3.bgSoft,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Ink3.cardHi,
      hintStyle: const TextStyle(color: Ink3.textFaint),
      labelStyle: const TextStyle(color: Ink3.textDim),
      prefixIconColor: Ink3.textDim,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Ink3.stroke),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Ink3.stroke),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Ink3.gold, width: 1.6),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Ink3.gold,
        foregroundColor: const Color(0xFF20180A),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Ink3.textDim,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Ink3.text,
        side: const BorderSide(color: Ink3.stroke),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Ink3.cardHi,
      contentTextStyle: const TextStyle(
        color: Ink3.text,
        fontWeight: FontWeight.w600,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Ink3.cardHi,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Ink3.stroke),
      ),
      textStyle: const TextStyle(color: Ink3.text, fontSize: 12),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        Ink3.textFaint.withValues(alpha: 0.5),
      ),
      radius: const Radius.circular(8),
      thickness: const WidgetStatePropertyAll(6),
    ),
  );
}
