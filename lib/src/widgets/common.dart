import "package:flutter/material.dart";

import "../store.dart";
import "../theme.dart";

/// Umumiy karta konteyneri.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = 20,
    this.shadows,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Ink3.card) : null,
        gradient: gradient,
        borderRadius: r,
        border: Border.all(color: borderColor ?? Ink3.stroke),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          onTap: onTap,
          borderRadius: r,
          hoverColor: Colors.white.withValues(alpha: 0.03),
          splashColor: Ink3.gold.withValues(alpha: 0.06),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Kichik yorliq (status, kategoriya va h.k.).
class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.color = Ink3.textDim,
    this.icon,
    this.filled = false,
    this.fontSize = 11.5,
  });

  final String text;
  final Color color;
  final IconData? icon;
  final bool filled;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Statistik ko'rsatkich kartasi.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sub,
  });

  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Ink3.textDim,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Ink3.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: const TextStyle(
                      color: Ink3.textFaint,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bo'sh holat ko'rinishi.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Ink3.cardHi,
                shape: BoxShape.circle,
                border: Border.all(color: Ink3.stroke),
              ),
              child: Icon(icon, size: 34, color: Ink3.textFaint),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Ink3.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 7),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Ink3.textDim, fontSize: 13.5),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Bo'lim sarlavhasi.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Ink3.textFaint,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Ink3.strokeSoft)),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// Tanlanadigan filtr tugmasi.
class ChipButton extends StatelessWidget {
  const ChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.color = Ink3.gold,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.16) : Ink3.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color.withValues(alpha: 0.55) : Ink3.stroke,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : Ink3.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.22)
                        : Ink3.cardHi,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "$count",
                    style: TextStyle(
                      color: selected ? color : Ink3.textFaint,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tasdiqlash oynasi.
Future<bool> askConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = "Ha",
  String cancelText = "Bekor qilish",
  bool danger = false,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(
        message,
        style: const TextStyle(color: Ink3.textDim, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: danger ? Ink3.red : Ink3.gold,
            foregroundColor: danger ? Colors.white : const Color(0xFF20180A),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return res ?? false;
}

/// Qisqa xabar.
void toast(BuildContext context, String message, {Color? color}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 2),
      content: Row(
        children: [
          Icon(
            color == Ink3.red ? Icons.error_outline : Icons.check_circle,
            color: color ?? Ink3.green,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

/// Tasdiqlab, tizimdan chiqish.
/// Oyna yopilish animatsiyasi tugagach chiqiladi - shunda ekran
/// almashuvi silliq kechadi.
Future<void> confirmLogout(BuildContext context) async {
  final ok = await askConfirm(
    context,
    title: "Kassadan chiqish",
    message: "Rostdan ham tizimdan chiqmoqchimisiz?",
    confirmText: "Chiqish",
  );
  if (!ok) return;
  await Future<void>.delayed(const Duration(milliseconds: 260));
  store.logout();
}

/// Dialog ichidagi matn kontrollerlarini to'g'ri hayot davri bilan boshqaradi.
///
/// `showDialog` future'i oyna yopilish animatsiyasi tugashidan oldin
/// qaytadi. Shuning uchun kontrollerlarni chaqiruvchi funksiyada
/// dispose qilish mumkin emas - ular shu vidjet bilan birga o'chiriladi.
/// [builder] ga kontrollerlar va lokal setState uzatiladi.
class DialogForm extends StatefulWidget {
  const DialogForm({
    super.key,
    required this.initial,
    required this.builder,
  });

  final List<String> initial;
  final Widget Function(
    BuildContext context,
    List<TextEditingController> fields,
    void Function(VoidCallback) setLocal,
  ) builder;

  @override
  State<DialogForm> createState() => _DialogFormState();
}

class _DialogFormState extends State<DialogForm> {
  late final List<TextEditingController> _fields = <TextEditingController>[
    for (final v in widget.initial) TextEditingController(text: v),
  ];

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _fields, setState);
}

/// Bitta matn so'raydigan oddiy oyna.
Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = "",
  String hint = "",
  IconData icon = Icons.edit_outlined,
  String okText = "Saqlash",
  TextCapitalization capitalization = TextCapitalization.sentences,
}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => DialogForm(
      initial: [initial],
      builder: (ctx, f, setLocal) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 320,
          child: TextField(
            controller: f[0],
            autofocus: true,
            textCapitalization: capitalization,
            onSubmitted: (v) => Navigator.pop(ctx, v),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Bekor qilish"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, f[0].text),
            child: Text(okText),
          ),
        ],
      ),
    ),
  );
}
