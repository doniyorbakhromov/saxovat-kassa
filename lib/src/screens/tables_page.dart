import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../models.dart";
import "../store.dart";
import "../theme.dart";
import "../utils.dart";
import "../widgets/common.dart";
import "order_screen.dart";

class TablesPage extends StatefulWidget {
  const TablesPage({super.key});

  @override
  State<TablesPage> createState() => _TablesPageState();
}

class _TablesPageState extends State<TablesPage> {
  String _zone = "Hammasi";
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final zones = ["Hammasi", ...store.zones];
        if (!zones.contains(_zone)) _zone = "Hammasi";
        final list = _zone == "Hammasi"
            ? store.tables
            : store.tables.where((t) => t.zone == _zone).toList();

        final wide = MediaQuery.sizeOf(context).width >= 900;
        final pad = wide ? 22.0 : 14.0;

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 10, pad, 0),
              sliver: SliverToBoxAdapter(child: _StatsRow(wide: wide)),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 20, pad, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final z in zones) ...[
                              ChipButton(
                                label: z,
                                selected: _zone == z,
                                count: z == "Hammasi"
                                    ? store.tables.length
                                    : store.tables
                                          .where((t) => t.zone == z)
                                          .length,
                                onTap: () => setState(() => _zone = z),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _AddTableButton(
                      compact: !wide,
                      defaultZone: _zone == "Hammasi" ? "Zal" : _zone,
                    ),
                  ],
                ),
              ),
            ),
            if (list.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.table_bar_rounded,
                  title: "Bu yerda stol yo'q",
                  message:
                      "O'z stollaringizni qo'shing.\n"
                      "Bir vaqtda bir nechtasini ham qo'shsa bo'ladi.",
                  action: ElevatedButton.icon(
                    onPressed: () => showTableDialog(
                      context,
                      zone: _zone == "Hammasi" ? "Zal" : _zone,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text("Stol qo'shish"),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 4, pad, 28),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 252,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 156,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _TableCard(table: list[i]),
                    childCount: list.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      StatTile(
        label: "BAND STOLLAR",
        value: "${store.openTablesCount} / ${store.tables.length}",
        icon: Icons.table_restaurant_rounded,
        color: Ink3.gold,
      ),
      StatTile(
        label: "OCHIQ BUYURTMALAR",
        value: sum(store.openTablesTotal),
        icon: Icons.pending_actions_rounded,
        color: Ink3.blue,
      ),
      StatTile(
        label: "BUGUNGI TUSHUM",
        value: sum(store.todayRevenue),
        icon: Icons.payments_rounded,
        color: Ink3.green,
      ),
      StatTile(
        label: "BUGUNGI CHEKLAR",
        value: "${store.todayReceipts.length} ta",
        icon: Icons.receipt_long_rounded,
        color: Ink3.violet,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 1180
            ? 4
            : c.maxWidth >= 520
            ? 2
            : 1;
        const gap = 12.0;
        final w = (c.maxWidth - gap * (perRow - 1)) / perRow;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _AddTableButton extends StatelessWidget {
  const _AddTableButton({required this.compact, required this.defaultZone});

  final bool compact;
  final String defaultZone;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => showTableDialog(context, zone: defaultZone),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 20,
          vertical: 14,
        ),
      ),
      icon: const Icon(Icons.add_rounded, size: 19),
      label: Text(compact ? "Stol" : "Stol qo'shish"),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table});

  final BarTable table;

  @override
  Widget build(BuildContext context) {
    final busy = table.isBusy;
    final open = table.openedAt;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      radius: 20,
      gradient: busy
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Ink3.gold.withValues(alpha: 0.14), Ink3.card, Ink3.card],
            )
          : null,
      borderColor: busy ? Ink3.gold.withValues(alpha: 0.45) : Ink3.stroke,
      shadows: busy ? Ink3.glow(Ink3.gold, 0.16) : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => OrderScreen(tableId: table.id)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  table.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Ink3.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              _TableMenu(table: table),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 13, color: Ink3.textFaint),
              const SizedBox(width: 4),
              Text(
                table.zone,
                style: const TextStyle(color: Ink3.textFaint, fontSize: 12),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.people_outline, size: 13, color: Ink3.textFaint),
              const SizedBox(width: 4),
              Text(
                "${table.seats}",
                style: const TextStyle(color: Ink3.textFaint, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          if (busy) ...[
            Row(
              children: [
                Pill(
                  open == null
                      ? "Band"
                      : elapsed(DateTime.now().difference(open)),
                  color: Ink3.gold,
                  icon: Icons.schedule_rounded,
                  filled: true,
                ),
                const SizedBox(width: 6),
                Pill(
                  "${table.itemCount} ta",
                  color: Ink3.textDim,
                  fontSize: 11,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                sum(table.subtotal),
                style: const TextStyle(
                  color: Ink3.goldSoft,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ] else ...[
            const Pill(
              "Bo'sh",
              color: Ink3.green,
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 15,
                  color: Ink3.textFaint,
                ),
                SizedBox(width: 6),
                Text(
                  "Buyurtma ochish",
                  style: TextStyle(
                    color: Ink3.textFaint,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TableMenu extends StatelessWidget {
  const _TableMenu({required this.table});

  final BarTable table;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: "Amallar",
      color: Ink3.bgSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Ink3.stroke),
      ),
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: Ink3.textFaint,
      ),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: "edit",
          child: _MenuRow(Icons.edit_outlined, "Tahrirlash"),
        ),
        if (table.isBusy)
          const PopupMenuItem(
            value: "move",
            child: _MenuRow(Icons.swap_horiz_rounded, "Boshqa stolga"),
          ),
        if (!table.isBusy)
          const PopupMenuItem(
            value: "delete",
            child: _MenuRow(
              Icons.delete_outline_rounded,
              "O'chirish",
              color: Ink3.red,
            ),
          ),
      ],
      onSelected: (v) async {
        if (v == "edit") {
          await showTableDialog(context, existing: table);
        } else if (v == "delete") {
          final ok = await askConfirm(
            context,
            title: "Stolni o'chirish",
            message: "\"${table.name}\" o'chirilsinmi?",
            confirmText: "O'chirish",
            danger: true,
          );
          if (ok) store.deleteTable(table.id);
        } else if (v == "move") {
          await _showMoveDialog(context, table);
        }
      },
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, {this.color = Ink3.text});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

Future<void> _showMoveDialog(BuildContext context, BarTable from) async {
  final free = store.tables.where((t) => !t.isBusy && t.id != from.id).toList();
  if (free.isEmpty) {
    toast(context, "Bo'sh stol yo'q", color: Ink3.red);
    return;
  }
  final target = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("${from.name} -> boshqa stolga"),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Buyurtma to'liq ko'chiriladi",
                style: TextStyle(color: Ink3.textDim, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in free)
                  ChipButton(
                    label: t.name,
                    selected: false,
                    onTap: () => Navigator.pop(ctx, t.id),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("Bekor qilish"),
        ),
      ],
    ),
  );
  if (target == null) return;
  final ok = store.moveOrder(from.id, target);
  if (ok && context.mounted) toast(context, "Buyurtma ko'chirildi");
}

/// Stol qo'shish / tahrirlash oynasi.
Future<void> showTableDialog(
  BuildContext context, {
  BarTable? existing,
  String zone = "Zal",
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => DialogForm(
      initial: [
        existing?.name ?? "Stol",
        existing?.zone ?? zone,
        (existing?.seats ?? 4).toString(),
        "1",
      ],
      builder: (ctx, f, setLocal) {
        final nameC = f[0];
        final zoneC = f[1];
        final seatsC = f[2];
        final countC = f[3];
        // Ko'pi bilan 200 ta stol - matn maydoni ham, tugma ham shu chegarada.
        final count = (int.tryParse(countC.text.trim()) ?? 1).clamp(1, 200);
        return AlertDialog(
          title: Text(existing == null ? "Yangi stol" : "Stolni tahrirlash"),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameC,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: existing == null && count > 1
                          ? "Nom boshlanishi"
                          : "Stol nomi",
                      hintText: "Masalan: Stol",
                      prefixIcon: const Icon(Icons.table_bar_rounded),
                      helperText: existing == null && count > 1
                          ? "${nameC.text.trim().isEmpty ? "Stol" : nameC.text.trim()} 1, "
                                "${nameC.text.trim().isEmpty ? "Stol" : nameC.text.trim()} 2 ... "
                                "shaklida $count ta stol qo'shiladi"
                          : null,
                      helperMaxLines: 2,
                    ),
                    onChanged: (_) => setLocal(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: zoneC,
                    decoration: const InputDecoration(
                      labelText: "Zona",
                      hintText: "Zal / Terassa / VIP",
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  if (store.zones.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final z in store.zones)
                            ChipButton(
                              label: z,
                              selected: zoneC.text == z,
                              onTap: () => setLocal(() => zoneC.text = z),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: seatsC,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: const InputDecoration(
                            labelText: "Necha kishilik",
                            prefixIcon: Icon(Icons.people_outline),
                          ),
                        ),
                      ),
                      if (existing == null) ...[
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 118,
                          child: TextField(
                            controller: countC,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            onChanged: (_) => setLocal(() {}),
                            decoration: const InputDecoration(
                              labelText: "Soni",
                              prefixIcon: Icon(Icons.tag_rounded),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
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
              onPressed: () {
                final seats = int.tryParse(seatsC.text.trim()) ?? 4;
                if (existing != null) {
                  store.editTable(existing.id, nameC.text, zoneC.text, seats);
                } else if (count > 1) {
                  final n = store.addTables(
                    nameC.text,
                    zoneC.text,
                    seats,
                    count,
                  );
                  toast(ctx, "$n ta stol qo'shildi");
                } else {
                  store.addTable(nameC.text, zoneC.text, seats);
                }
                Navigator.pop(ctx);
              },
              child: Text(
                existing == null
                    ? (count > 1 ? "$count ta qo'shish" : "Qo'shish")
                    : "Saqlash",
              ),
            ),
          ],
        );
      },
    ),
  );
}
