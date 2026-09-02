import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../icons.dart";
import "../models.dart";
import "../store.dart";
import "../theme.dart";
import "../utils.dart";
import "../widgets/common.dart";
import "../widgets/receipt_view.dart";

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, required this.tableId});

  final String tableId;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  String _cat = "Hammasi";
  String _query = "";
  final TextEditingController _searchC = TextEditingController();
  late Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    _searchC.dispose();
    super.dispose();
  }

  List<MenuItem> get _filtered {
    final q = _query.trim().toLowerCase();
    return store.menu.where((m) {
      if (!m.active) return false;
      if (_cat != "Hammasi" && m.category != _cat) return false;
      if (q.isNotEmpty && !m.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final table = store.tableById(widget.tableId);
        if (table == null) {
          return const Scaffold(
            body: Center(child: Text("Stol topilmadi")),
          );
        }
        final wide = MediaQuery.sizeOf(context).width >= 980;

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(gradient: Ink3.bgGrad),
            child: SafeArea(
              child: Column(
                children: [
                  _Header(table: table),
                  Expanded(
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _menuPanel(table)),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 4, 14, 14),
                                child: SizedBox(
                                  width: 392,
                                  child: _CartPanel(table: table),
                                ),
                              ),
                            ],
                          )
                        : _menuPanel(table),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar:
              wide ? null : _MobileCartBar(table: table),
        );
      },
    );
  }

  Widget _menuPanel(BarTable table) {
    final cats = ["Hammasi", ...store.categories];
    if (!cats.contains(_cat)) _cat = "Hammasi";
    final items = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: TextField(
            controller: _searchC,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: "Mahsulot qidirish...",
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _searchC.clear();
                        setState(() => _query = "");
                      },
                    ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final c in cats) ...[
                ChipButton(
                  label: c,
                  selected: _cat == c,
                  onTap: () => setState(() => _cat = c),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: items.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: "Mahsulot topilmadi",
                  message: "Boshqa nom bilan qidirib ko'ring yoki\n"
                      "Menyu bo'limidan yangi mahsulot qo'shing.",
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 186,
                    mainAxisSpacing: 11,
                    crossAxisSpacing: 11,
                    mainAxisExtent: 118,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final qty = table.lines
                        .where((l) => l.itemId == item.id)
                        .fold(0, (s, l) => s + l.qty);
                    return _MenuTile(
                      item: item,
                      qty: qty,
                      onTap: () {
                        store.addToOrder(table.id, item);
                        HapticFeedback.selectionClick();
                      },
                      onLongPress: () => _askQty(context, table, item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _askQty(
    BuildContext context,
    BarTable table,
    MenuItem item,
  ) async {
    var qty = 1;
    final res = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(item.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                sum(item.price),
                style: const TextStyle(color: Ink3.gold, fontSize: 15),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundBtn(
                    icon: Icons.remove_rounded,
                    onTap: () => setLocal(() {
                      if (qty > 1) qty--;
                    }),
                    big: true,
                  ),
                  SizedBox(
                    width: 78,
                    child: Text(
                      "$qty",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Ink3.text,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _RoundBtn(
                    icon: Icons.add_rounded,
                    onTap: () => setLocal(() => qty++),
                    big: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                sum(item.price * qty),
                style: const TextStyle(
                  color: Ink3.goldSoft,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Bekor qilish"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, qty),
              child: const Text("Qo'shish"),
            ),
          ],
        ),
      ),
    );
    if (res != null && res > 0) {
      store.addToOrder(table.id, item, qty: res);
    }
  }
}

// ------------------------------------------------------------------ header

class _Header extends StatelessWidget {
  const _Header({required this.table});

  final BarTable table;

  @override
  Widget build(BuildContext context) {
    final open = table.openedAt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Ink3.text),
            tooltip: "Orqaga",
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  table.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Ink3.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      table.zone,
                      style: const TextStyle(
                        color: Ink3.textFaint,
                        fontSize: 12,
                      ),
                    ),
                    if (open != null) ...[
                      const Text(
                        "  -  ",
                        style:
                            TextStyle(color: Ink3.textFaint, fontSize: 12),
                      ),
                      Text(
                        "${clock(open)} dan beri "
                        "(${elapsed(DateTime.now().difference(open))})",
                        style: const TextStyle(
                          color: Ink3.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (table.isBusy)
            IconButton(
              tooltip: "Buyurtmani bekor qilish",
              onPressed: () async {
                final ok = await askConfirm(
                  context,
                  title: "Buyurtmani bekor qilish",
                  message:
                      "${table.name} dagi barcha mahsulotlar o'chiriladi. "
                      "Chek saqlanmaydi.",
                  confirmText: "Ha, bekor qilinsin",
                  danger: true,
                );
                if (ok) store.cancelOrder(table.id);
              },
              icon: const Icon(Icons.delete_sweep_rounded, color: Ink3.red),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- menu tile

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.item,
    required this.qty,
    required this.onTap,
    required this.onLongPress,
  });

  final MenuItem item;
  final int qty;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final active = qty > 0;
    final r = BorderRadius.circular(17);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? Ink3.gold.withValues(alpha: 0.10) : Ink3.card,
        borderRadius: r,
        border: Border.all(
          color: active ? Ink3.gold.withValues(alpha: 0.5) : Ink3.stroke,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: r,
          hoverColor: Colors.white.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: active
                            ? Ink3.gold.withValues(alpha: 0.16)
                            : Ink3.cardHi,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        iconFor(item.icon),
                        size: 17,
                        color: active ? Ink3.gold : Ink3.textDim,
                      ),
                    ),
                    const Spacer(),
                    if (active)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: Ink3.goldGrad,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "$qty",
                          style: const TextStyle(
                            color: Color(0xFF20180A),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Ink3.text,
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  money(item.price),
                  style: const TextStyle(
                    color: Ink3.goldSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- cart panel

class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.table, this.sheet = false});

  final BarTable table;
  final bool sheet;

  @override
  Widget build(BuildContext context) {
    final sp = store.settings.servicePercent;
    final subtotal = table.subtotal;
    final service = subtotal * sp ~/ 100;
    final total = subtotal + service;

    return Container(
      decoration: BoxDecoration(
        color: Ink3.card.withValues(alpha: sheet ? 0 : 0.75),
        borderRadius: BorderRadius.circular(sheet ? 0 : 22),
        border: sheet ? null : Border.all(color: Ink3.stroke),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  size: 19,
                  color: Ink3.gold,
                ),
                const SizedBox(width: 9),
                const Text(
                  "Buyurtma",
                  style: TextStyle(
                    color: Ink3.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 9),
                Pill("${table.itemCount} ta", color: Ink3.gold, filled: true),
                const Spacer(),
                if (table.lines.isNotEmpty)
                  IconButton(
                    tooltip: "Tozalash",
                    onPressed: () async {
                      final ok = await askConfirm(
                        context,
                        title: "Buyurtmani tozalash",
                        message: "Barcha mahsulotlar o'chiriladi.",
                        confirmText: "Tozalash",
                        danger: true,
                      );
                      if (ok) store.cancelOrder(table.id);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 19,
                      color: Ink3.textFaint,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: table.lines.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_basket_outlined,
                    title: "Buyurtma bo'sh",
                    message: "Chapdagi menyudan mahsulot tanlang",
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    itemCount: table.lines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) =>
                        _LineTile(table: table, line: table.lines[i]),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              children: [
                _TotalRow("Oraliq jami", money(subtotal)),
                if (sp > 0)
                  _TotalRow("Xizmat haqi ($sp%)", "+${money(service)}"),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "JAMI",
                      style: TextStyle(
                        color: Ink3.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          sum(total),
                          style: const TextStyle(
                            color: Ink3.goldSoft,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: table.lines.isEmpty
                        ? null
                        : () => showPaymentDialog(context, table),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Ink3.gold,
                      disabledBackgroundColor: Ink3.cardHi,
                      disabledForegroundColor: Ink3.textFaint,
                    ),
                    icon: const Icon(Icons.payments_rounded, size: 20),
                    label: const Text(
                      "TO'LOV VA STOLNI YOPISH",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
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

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Ink3.textDim, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Ink3.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({required this.table, required this.line});

  final BarTable table;
  final OrderLine line;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(line.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => store.removeLine(table.id, line.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: Ink3.red.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Ink3.red),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 10, 10, 10),
        decoration: BoxDecoration(
          color: Ink3.cardHi.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Ink3.strokeSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Ink3.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  money(line.total),
                  style: const TextStyle(
                    color: Ink3.goldSoft,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (line.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  line.note,
                  style: const TextStyle(
                    color: Ink3.blue,
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 7),
            Row(
              children: [
                Text(
                  "${money(line.price)} x ${line.qty}",
                  style: const TextStyle(
                    color: Ink3.textFaint,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _noteDialog(context),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: Ink3.textFaint,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _RoundBtn(
                  icon: Icons.remove_rounded,
                  onTap: () => store.changeQty(table.id, line.id, -1),
                ),
                SizedBox(
                  width: 34,
                  child: Text(
                    "${line.qty}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Ink3.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _RoundBtn(
                  icon: Icons.add_rounded,
                  onTap: () => store.changeQty(table.id, line.id, 1),
                  accent: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _noteDialog(BuildContext context) async {
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => DialogForm(
        initial: [line.note],
        builder: (ctx, f, setLocal) => AlertDialog(
          title: const Text("Izoh"),
          content: SizedBox(
            width: 320,
            child: TextField(
              controller: f[0],
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Masalan: muzsiz, achchiq emas...",
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
              child: const Text("Saqlash"),
            ),
          ],
        ),
      ),
    );
    if (res != null) store.setLineNote(table.id, line.id, res);
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({
    required this.icon,
    required this.onTap,
    this.accent = false,
    this.big = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool accent;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final s = big ? 48.0 : 30.0;
    return Material(
      color: accent ? Ink3.gold.withValues(alpha: 0.16) : Ink3.card,
      borderRadius: BorderRadius.circular(big ? 16 : 9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(big ? 16 : 9),
        child: Container(
          width: s,
          height: s,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(big ? 16 : 9),
            border: Border.all(
              color: accent ? Ink3.gold.withValues(alpha: 0.5) : Ink3.stroke,
            ),
          ),
          child: Icon(
            icon,
            size: big ? 24 : 17,
            color: accent ? Ink3.gold : Ink3.textDim,
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------ mobil pastki panel

class _MobileCartBar extends StatelessWidget {
  const _MobileCartBar({required this.table});

  final BarTable table;

  @override
  Widget build(BuildContext context) {
    final sp = store.settings.servicePercent;
    final total = table.subtotal + (table.subtotal * sp ~/ 100);

    return Container(
      decoration: const BoxDecoration(
        color: Ink3.bgSoft,
        border: Border(top: BorderSide(color: Ink3.stroke)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${table.itemCount} ta mahsulot",
                      style: const TextStyle(
                        color: Ink3.textDim,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sum(total),
                      style: const TextStyle(
                        color: Ink3.goldSoft,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _openSheet(context),
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text("Buyurtma"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: table.lines.isEmpty
                    ? null
                    : () => showPaymentDialog(context, table),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: Ink3.cardHi,
                  disabledForegroundColor: Ink3.textFaint,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                ),
                child: const Text("To'lov"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Ink3.bgSoft,
      builder: (ctx) => ListenableBuilder(
        listenable: store,
        builder: (ctx, _) {
          final t = store.tableById(table.id);
          if (t == null) return const SizedBox.shrink();
          return SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.82,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Ink3.stroke,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Expanded(child: _CartPanel(table: t, sheet: true)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ----------------------------------------------------------- to'lov oynasi

Future<void> showPaymentDialog(BuildContext context, BarTable table) async {
  var discount = 0;
  var method = "Naqd";

  Receipt? made;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => DialogForm(
      initial: const [""],
      builder: (ctx, f, setLocal) {
        final cashC = f[0];
        final sp = store.settings.servicePercent;
        final subtotal = table.subtotal;
        final disc = subtotal * discount ~/ 100;
        final service = (subtotal - disc) * sp ~/ 100;
        final total = subtotal - disc + service;
        final cash =
            int.tryParse(cashC.text.replaceAll(RegExp(r"[^0-9]"), "")) ?? 0;
        final change = cash - total;
        final notEnough = cash > 0 && cash < total;

        void quick(int v) {
          cashC.text = money(v);
          setLocal(() {});
        }

        int roundUp(int base) => ((total + base - 1) ~/ base) * base;

        return AlertDialog(
          insetPadding: const EdgeInsets.all(18),
          title: Row(
            children: [
              const Icon(Icons.payments_rounded, color: Ink3.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text("To'lov  -  ${table.name}")),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Ink3.gold.withValues(alpha: 0.16),
                          Ink3.gold.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Ink3.gold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "TO'LANADIGAN SUMMA",
                          style: TextStyle(
                            color: Ink3.textDim,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            sum(total),
                            style: const TextStyle(
                              color: Ink3.goldSoft,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${table.itemCount} ta mahsulot"
                          "${disc > 0 ? "  -  chegirma ${money(disc)}" : ""}"
                          "${service > 0 ? "  -  xizmat ${money(service)}" : ""}",
                          style: const TextStyle(
                            color: Ink3.textFaint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _Label("Chegirma"),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final d in [0, 5, 10, 15, 20, 30])
                        ChipButton(
                          label: d == 0 ? "Yo'q" : "$d%",
                          selected: discount == d,
                          onTap: () => setLocal(() => discount = d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _Label("To'lov turi"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final m in const <(String, IconData)>[
                        ("Naqd", Icons.account_balance_wallet_rounded),
                        ("Karta", Icons.credit_card_rounded),
                        ("Click/Payme", Icons.phone_iphone_rounded),
                      ]) ...[
                        Expanded(
                          child: _MethodBtn(
                            label: m.$1,
                            icon: m.$2,
                            selected: method == m.$1,
                            onTap: () => setLocal(() => method = m.$1),
                          ),
                        ),
                        if (m.$1 != "Click/Payme") const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  if (method == "Naqd") ...[
                    const SizedBox(height: 18),
                    const _Label("Mijoz bergan pul"),
                    const SizedBox(height: 8),
                    TextField(
                      controller: cashC,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [ThousandsFormatter()],
                      onChanged: (_) => setLocal(() {}),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        hintText: money(total),
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                        errorText: notEnough ? "Summa yetarli emas" : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        ChipButton(
                          label: "Aniq",
                          selected: cash == total,
                          onTap: () => quick(total),
                        ),
                        for (final b in [10000, 50000, 100000])
                          ChipButton(
                            label: money(roundUp(b)),
                            selected: cash == roundUp(b),
                            onTap: () => quick(roundUp(b)),
                          ),
                      ],
                    ),
                    if (cash >= total && cash > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Ink3.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Ink3.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Qaytim",
                              style: TextStyle(
                                color: Ink3.textDim,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              sum(change),
                              style: const TextStyle(
                                color: Ink3.green,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Bekor qilish"),
            ),
            ElevatedButton.icon(
              onPressed: notEnough
                  ? null
                  : () async {
                      made = await store.closeTable(
                        table.id,
                        discountPercent: discount,
                        method: method,
                        cashGiven: method == "Naqd"
                            ? (cash == 0 ? total : cash)
                            : total,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Ink3.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Ink3.cardHi,
                disabledForegroundColor: Ink3.textFaint,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 19),
              label: const Text("Yakunlash"),
            ),
          ],
        );
      },
    ),
  );

  final receipt = made;
  if (receipt == null || !context.mounted) return;

  await showReceiptDialog(context, receipt, justPaid: true);
  if (context.mounted) Navigator.of(context).maybePop();
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Ink3.textFaint,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MethodBtn extends StatelessWidget {
  const _MethodBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? Ink3.gold.withValues(alpha: 0.15) : Ink3.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? Ink3.gold.withValues(alpha: 0.55)
                  : Ink3.stroke,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Ink3.gold : Ink3.textDim,
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Ink3.gold : Ink3.textDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
