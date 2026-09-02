import "package:flutter/material.dart";

import "../models.dart";
import "../store.dart";
import "../theme.dart";
import "../utils.dart";

/// Chekni ko'rsatuvchi oyna.
Future<void> showReceiptDialog(
  BuildContext context,
  Receipt r, {
  bool justPaid = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 640),
        child: Container(
          decoration: BoxDecoration(
            color: Ink3.bgSoft,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Ink3.stroke),
            boxShadow: Ink3.soft(0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (justPaid)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Ink3.green.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(23),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Ink3.green,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "To'lov qabul qilindi",
                        style: TextStyle(
                          color: Ink3.green,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (r.method == "Naqd" && r.change > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Qaytim: ${sum(r.change)}",
                          style: const TextStyle(
                            color: Ink3.goldSoft,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              store.settings.venueName,
                              style: const TextStyle(
                                color: Ink3.text,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "${r.tableName}  -  ${r.zone}",
                              style: const TextStyle(
                                color: Ink3.textDim,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateTimeFull(r.closedAt),
                              style: const TextStyle(
                                color: Ink3.textFaint,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _Dashed(),
                      const SizedBox(height: 10),
                      for (final l in r.lines)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.name,
                                      style: const TextStyle(
                                        color: Ink3.text,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "${l.qty} x ${money(l.price)}",
                                      style: const TextStyle(
                                        color: Ink3.textFaint,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                    if (l.note.isNotEmpty)
                                      Text(
                                        l.note,
                                        style: const TextStyle(
                                          color: Ink3.blue,
                                          fontSize: 11.5,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                money(l.total),
                                style: const TextStyle(
                                  color: Ink3.text,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      const _Dashed(),
                      const SizedBox(height: 10),
                      _Line("Oraliq jami", money(r.subtotal)),
                      if (r.discount > 0)
                        _Line(
                          "Chegirma",
                          "-${money(r.discount)}",
                          color: Ink3.green,
                        ),
                      if (r.service > 0)
                        _Line("Xizmat haqi", "+${money(r.service)}"),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "JAMI",
                            style: TextStyle(
                              color: Ink3.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            sum(r.total),
                            style: const TextStyle(
                              color: Ink3.goldSoft,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Line("To'lov turi", r.method),
                      if (r.method == "Naqd" && r.cashGiven > 0) ...[
                        _Line("Berilgan", money(r.cashGiven)),
                        _Line("Qaytim", money(r.change)),
                      ],
                      _Line("Davomiyligi", elapsed(r.duration)),
                      if (r.note.isNotEmpty) _Line("Izoh", r.note),
                      const SizedBox(height: 14),
                      const Center(
                        child: Text(
                          "Tashrifingiz uchun rahmat!",
                          style: TextStyle(
                            color: Ink3.textFaint,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Yopish"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Ink3.textDim, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Ink3.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = (c.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            n,
            (_) => Container(width: 4, height: 1.4, color: Ink3.stroke),
          ),
        );
      },
    );
  }
}
