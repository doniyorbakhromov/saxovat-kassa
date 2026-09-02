import "dart:math";

import "package:flutter/services.dart";

final Random _rnd = Random();

/// Qisqa, takrorlanmaydigan identifikator.
String newId() {
  final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final r = _rnd.nextInt(1679616).toRadixString(36).padLeft(4, "0");
  return "$t$r";
}

String _pad(int n) => n.toString().padLeft(2, "0");

/// 125000 -> "125 000"
String money(int value) {
  final neg = value < 0;
  final digits = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(" ");
    buf.write(digits[i]);
  }
  return "${neg ? "-" : ""}$buf";
}

/// 125000 -> "125 000 so'm"
String sum(int value) => "${money(value)} so'm";

String clock(DateTime d) => "${_pad(d.hour)}:${_pad(d.minute)}";

String dayDate(DateTime d) => "${_pad(d.day)}.${_pad(d.month)}.${d.year}";

String dateTimeFull(DateTime d) => "${dayDate(d)}  ${clock(d)}";

const List<String> _weekdays = [
  "Dushanba",
  "Seshanba",
  "Chorshanba",
  "Payshanba",
  "Juma",
  "Shanba",
  "Yakshanba",
];

const List<String> _months = [
  "yanvar",
  "fevral",
  "mart",
  "aprel",
  "may",
  "iyun",
  "iyul",
  "avgust",
  "sentabr",
  "oktabr",
  "noyabr",
  "dekabr",
];

String longDate(DateTime d) =>
    "${d.day}-${_months[d.month - 1]}, ${_weekdays[d.weekday - 1]}";

/// 95 daqiqa -> "1 soat 35 daq"
String elapsed(Duration d) {
  if (d.inMinutes < 1) return "hozirgina";
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h <= 0) return "$m daq";
  return "$h soat $m daq";
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int asInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String asStr(Object? v, [String fallback = ""]) => v is String ? v : fallback;

/// Matn maydonida raqamlarni "125 000" ko'rinishida ajratib turadi.
class ThousandsFormatter extends TextInputFormatter {
  const ThousandsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r"[^0-9]"), "");
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > 12) digits = digits.substring(0, 12);
    final text = money(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
