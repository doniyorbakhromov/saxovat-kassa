import "package:flutter/material.dart";

import "../icons.dart";
import "../models.dart";
import "../store.dart";
import "../theme.dart";
import "../utils.dart";
import "../widgets/common.dart";

/// Dialogdan "o'chirish tanlandi" degan javobni ajratish uchun.
const String _deleteMarker = "__delete__";

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String _cat = "Hammasi";
  String _query = "";

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final wide = MediaQuery.sizeOf(context).width >= 900;
        final pad = wide ? 22.0 : 14.0;
        final cats = ["Hammasi", ...store.categories];
        if (!cats.contains(_cat)) _cat = "Hammasi";

        final q = _query.trim().toLowerCase();
        final items = store.menu.where((m) {
          if (_cat != "Hammasi" && m.category != _cat) return false;
          if (q.isNotEmpty && !m.name.toLowerCase().contains(q)) return false;
          return true;
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: "Mahsulot qidirish...",
                          prefixIcon: Icon(Icons.search_rounded, size: 20),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => showItemDialog(
                        context,
                        category: _cat == "Hammasi"
                            ? (store.categories.isEmpty
                                  ? ""
                                  : store.categories.first)
                            : _cat,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: wide ? 20 : 14,
                          vertical: 14,
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: Text(wide ? "Mahsulot qo'shish" : "Mahsulot"),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
              sliver: const SliverToBoxAdapter(child: _MenuHint()),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 12),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final c in cats) ...[
                        _CatChip(
                          label: c,
                          selected: _cat == c,
                          count: c == "Hammasi"
                              ? store.menu.length
                              : store.itemsOf(c).length,
                          onTap: () => setState(() => _cat = c),
                          onEdit: c == "Hammasi"
                              ? null
                              : () => _editCategory(context, c),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _AddCatChip(onTap: () => _addCategory(context)),
                    ],
                  ),
                ),
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.restaurant_menu_rounded,
                  title: "Mahsulot yo'q",
                  message:
                      "Yangi mahsulot qo'shing va u kassada\n"
                      "darhol paydo bo'ladi.",
                  action: ElevatedButton.icon(
                    onPressed: () => showItemDialog(
                      context,
                      category: _cat == "Hammasi"
                          ? (store.categories.isEmpty
                                ? ""
                                : store.categories.first)
                          : _cat,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text("Mahsulot qo'shish"),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, 28),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 260,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 104,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _ItemCard(item: items[i]),
                    childCount: items.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _addCategory(BuildContext context) async {
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => DialogForm(
        initial: const [""],
        builder: (ctx, f, setLocal) => AlertDialog(
          title: const Text("Yangi kategoriya"),
          content: SizedBox(
            width: 320,
            child: TextField(
              controller: f[0],
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: "Masalan: Vino",
                prefixIcon: Icon(Icons.category_outlined),
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
              child: const Text("Qo'shish"),
            ),
          ],
        ),
      ),
    );
    if (res != null && res.trim().isNotEmpty) store.addCategory(res);
  }

  Future<void> _editCategory(BuildContext context, String name) async {
    final count = store.itemsOf(name).length;

    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => DialogForm(
        initial: [name],
        builder: (ctx, f, setLocal) => AlertDialog(
          title: const Text("Kategoriya"),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: f[0],
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (v) => Navigator.pop(ctx, v),
                    decoration: const InputDecoration(
                      labelText: "Kategoriya nomi",
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 14,
                        color: Ink3.textFaint,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        count == 0
                            ? "Bu kategoriya hozircha bo'sh"
                            : "Ichida $count ta mahsulot bor",
                        style: const TextStyle(
                          color: Ink3.textFaint,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx, _deleteMarker),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Ink3.red,
                      side: BorderSide(color: Ink3.red.withValues(alpha: 0.4)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text("Kategoriyani o'chirish"),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    count == 0
                        ? "Kategoriya ro'yxatdan olib tashlanadi."
                        : "Kategoriya bilan birga $count ta mahsulot ham o'chadi.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Ink3.textFaint,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
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
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, f[0].text),
              child: const Text("Saqlash"),
            ),
          ],
        ),
      ),
    );

    if (res == null || !context.mounted) return;

    if (res == _deleteMarker) {
      final ok = await askConfirm(
        context,
        title: "Kategoriyani o'chirish",
        message: count == 0
            ? "\"$name\" o'chirilsinmi?"
            : "\"$name\" va undagi $count ta mahsulot o'chiriladi. "
                  "Buni ortga qaytarib bo'lmaydi.",
        confirmText: "O'chirish",
        danger: true,
      );
      if (ok) {
        store.deleteCategory(name);
        setState(() => _cat = "Hammasi");
      }
      return;
    }

    final newName = res.trim();
    if (newName.isEmpty || newName == name) return;
    if (store.categories.contains(newName)) {
      toast(context, "Bunday kategoriya allaqachon bor", color: Ink3.red);
      return;
    }
    store.renameCategory(name, newName);
    setState(() => _cat = newName);
  }
}

/// Menyuni qanday boshqarish kerakligini qisqa tushuntiradi.
class _MenuHint extends StatelessWidget {
  const _MenuHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline_rounded, size: 14, color: Ink3.textFaint),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            "Mahsulotni tahrirlash uchun ustiga bosing, o'chirish uchun "
            "savat belgisini. Kategoriyani tanlasangiz, yonida uni "
            "o'zgartirish tugmasi chiqadi.",
            style: TextStyle(
              color: Ink3.textFaint,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({
    required this.label,
    required this.selected,
    required this.count,
    required this.onTap,
    this.onEdit,
  });

  final String label;
  final bool selected;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final chip = ChipButton(
      label: label,
      selected: selected,
      count: count,
      onTap: onTap,
    );
    if (onEdit == null) return chip;

    return GestureDetector(
      onLongPress: onEdit,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip,
          // Tanlangan kategoriya yonida ko'rinadigan tahrirlash tugmasi.
          if (selected) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: "Nomini o'zgartirish yoki o'chirish",
              child: Material(
                color: Ink3.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Ink3.gold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 17,
                      color: Ink3.gold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddCatChip extends StatelessWidget {
  const _AddCatChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Ink3.stroke),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: Ink3.textDim),
              SizedBox(width: 5),
              Text(
                "Kategoriya",
                style: TextStyle(
                  color: Ink3.textDim,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      onTap: () => showItemDialog(context, existing: item),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Ink3.cardHi,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Ink3.stroke),
            ),
            child: Icon(iconFor(item.icon), size: 21, color: Ink3.goldSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Ink3.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sum(item.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Ink3.goldSoft,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Ink3.textFaint, fontSize: 11.5),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Mahsulotni o'chirish",
            onPressed: () async {
              final ok = await askConfirm(
                context,
                title: "Mahsulotni o'chirish",
                message: "\"${item.name}\" menyudan o'chirilsinmi?",
                confirmText: "O'chirish",
                danger: true,
              );
              if (ok) store.deleteItem(item.id);
            },
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Ink3.red.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mahsulot qo'shish / tahrirlash.
Future<void> showItemDialog(
  BuildContext context, {
  MenuItem? existing,
  String category = "",
}) async {
  var cat = existing?.category ?? category;
  var icon = existing?.icon ?? "boshqa";

  await showDialog<void>(
    context: context,
    builder: (ctx) => DialogForm(
      initial: [
        existing?.name ?? "",
        existing == null ? "" : "${existing.price}",
      ],
      builder: (ctx, f, setLocal) {
        final nameC = f[0];
        final priceC = f[1];
        return AlertDialog(
          title: Text(
            existing == null ? "Yangi mahsulot" : "Mahsulotni tahrirlash",
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameC,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: "Nomi",
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceC,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [ThousandsFormatter()],
                    decoration: const InputDecoration(
                      labelText: "Narxi (so'm)",
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _MiniLabel("Kategoriya"),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final c in store.categories)
                        ChipButton(
                          label: c,
                          selected: cat == c,
                          onTap: () => setLocal(() => cat = c),
                        ),
                      _AddCatChip(
                        onTap: () async {
                          final name = await askText(
                            ctx,
                            title: "Yangi kategoriya",
                            hint: "Masalan: Vino",
                            icon: Icons.category_outlined,
                            okText: "Qo'shish",
                          );
                          if (name == null || name.trim().isEmpty) return;
                          store.addCategory(name);
                          setLocal(() => cat = name.trim());
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _MiniLabel("Belgi"),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final k in kIconKeys)
                        GestureDetector(
                          onTap: () => setLocal(() => icon = k),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: icon == k
                                  ? Ink3.gold.withValues(alpha: 0.16)
                                  : Ink3.cardHi,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: icon == k
                                    ? Ink3.gold.withValues(alpha: 0.6)
                                    : Ink3.stroke,
                              ),
                            ),
                            child: Icon(
                              iconFor(k),
                              size: 19,
                              color: icon == k ? Ink3.gold : Ink3.textDim,
                            ),
                          ),
                        ),
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
                final name = nameC.text.trim();
                final price =
                    int.tryParse(
                      priceC.text.replaceAll(RegExp(r"[^0-9]"), ""),
                    ) ??
                    0;
                if (name.isEmpty || price <= 0) {
                  toast(ctx, "Nom va narxni to'g'ri kiriting", color: Ink3.red);
                  return;
                }
                if (cat.trim().isEmpty) {
                  toast(ctx, "Kategoriyani tanlang", color: Ink3.red);
                  return;
                }
                if (existing == null) {
                  store.addItem(name, price, cat, icon);
                } else {
                  store.updateItem(existing.id, name, price, cat, icon);
                }
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? "Qo'shish" : "Saqlash"),
            ),
          ],
        );
      },
    ),
  );
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);

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
