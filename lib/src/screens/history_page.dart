import "package:flutter/material.dart";

import "../models.dart";
import "../store.dart";
import "../theme.dart";
import "../utils.dart";
import "../widgets/common.dart";
import "../widgets/receipt_view.dart";

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const _filters = ["Bugun", "Kecha", "7 kun", "Oy", "Hammasi"];
  String _filter = "Bugun";

  List<Receipt> _apply(List<Receipt> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_filter) {
      case "Bugun":
        return all.where((r) => r.closedAt.isAfter(today)).toList();
      case "Kecha":
        final y = today.subtract(const Duration(days: 1));
        return all
            .where((r) =>
                r.closedAt.isAfter(y) && r.closedAt.isBefore(today))
            .toList();
      case "7 kun":
        final d = today.subtract(const Duration(days: 6));
        return all.where((r) => r.closedAt.isAfter(d)).toList();
      case "Oy":
        final d = DateTime(now.year, now.month);
        return all.where((r) => r.closedAt.isAfter(d)).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final wide = MediaQuery.sizeOf(context).width >= 900;
        final pad = wide ? 22.0 : 14.0;
        final list = _apply(store.receipts);

        final total = list.fold(0, (s, r) => s + r.total);
        final cash = list
            .where((r) => r.method == "Naqd")
            .fold(0, (s, r) => s + r.total);
        final card = total - cash;
        final avg = list.isEmpty ? 0 : total ~/ list.length;

        final groups = <String, List<Receipt>>{};
        for (final r in list) {
          groups.putIfAbsent(dayDate(r.closedAt), () => []).add(r);
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 4),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final f in _filters) ...[
                        ChipButton(
                          label: f,
                          selected: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 12, pad, 8),
              sliver: SliverToBoxAdapter(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final perRow = c.maxWidth >= 1180
                        ? 4
                        : c.maxWidth >= 520
                            ? 2
                            : 1;
                    const gap = 12.0;
                    final w = (c.maxWidth - gap * (perRow - 1)) / perRow;
                    final tiles = <Widget>[
                      StatTile(
                        label: "UMUMIY TUSHUM",
                        value: sum(total),
                        icon: Icons.payments_rounded,
                        color: Ink3.green,
                      ),
                      StatTile(
                        label: "CHEKLAR",
                        value: "${list.length} ta",
                        sub: "o'rtacha ${money(avg)}",
                        icon: Icons.receipt_long_rounded,
                        color: Ink3.gold,
                      ),
                      StatTile(
                        label: "NAQD",
                        value: sum(cash),
                        icon: Icons.account_balance_wallet_rounded,
                        color: Ink3.blue,
                      ),
                      StatTile(
                        label: "KARTA / ONLAYN",
                        value: sum(card),
                        icon: Icons.credit_card_rounded,
                        color: Ink3.violet,
                      ),
                    ];
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final t in tiles) SizedBox(width: w, child: t),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (list.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: "Cheklar yo'q",
                  message: "Bu davr uchun yopilgan buyurtmalar topilmadi.",
                ),
              )
            else
              for (final entry in groups.entries) ...[
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 14, pad, 8),
                  sliver: SliverToBoxAdapter(
                    child: SectionLabel(
                      entry.key,
                      trailing: Text(
                        sum(entry.value.fold(0, (s, r) => s + r.total)),
                        style: const TextStyle(
                          color: Ink3.goldSoft,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ReceiptRow(receipt: entry.value[i]),
                      ),
                      childCount: entry.value.length,
                    ),
                  ),
                ),
              ],
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        );
      },
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.receipt});

  final Receipt receipt;

  Color get _methodColor => switch (receipt.method) {
        "Naqd" => Ink3.blue,
        "Karta" => Ink3.violet,
        _ => Ink3.green,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      radius: 16,
      onTap: () => showReceiptDialog(context, receipt),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Ink3.cardHi,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Ink3.stroke),
            ),
            child: const Icon(
              Icons.table_bar_rounded,
              size: 19,
              color: Ink3.textDim,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        receipt.tableName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Ink3.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Pill(receipt.method, color: _methodColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${clock(receipt.closedAt)}  -  ${receipt.itemCount} ta"
                  "  -  ${elapsed(receipt.duration)}",
                  style: const TextStyle(
                    color: Ink3.textFaint,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sum(receipt.total),
                style: const TextStyle(
                  color: Ink3.goldSoft,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (receipt.discount > 0)
                Text(
                  "-${money(receipt.discount)}",
                  style: const TextStyle(color: Ink3.green, fontSize: 11),
                ),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: "Amallar",
            color: Ink3.bgSoft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Ink3.stroke),
            ),
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 17,
              color: Ink3.textFaint,
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: "open",
                child: Text("Chekni ko'rish"),
              ),
              PopupMenuItem(
                value: "delete",
                child: Text(
                  "O'chirish",
                  style: TextStyle(color: Ink3.red),
                ),
              ),
            ],
            onSelected: (v) async {
              if (v == "open") {
                await showReceiptDialog(context, receipt);
              } else if (v == "delete") {
                final ok = await askConfirm(
                  context,
                  title: "Chekni o'chirish",
                  message: "Bu chek hisobotdan butunlay o'chiriladi.",
                  confirmText: "O'chirish",
                  danger: true,
                );
                if (ok) store.deleteReceipt(receipt.id);
              }
            },
          ),
        ],
      ),
    );
  }
}
