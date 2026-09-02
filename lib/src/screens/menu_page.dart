import "package:flutter/material.dart";

import "../icons.dart";
import "../models.dart";
import "../store.dart";
import "../theme.dart";
import "../utils.dart";
import "../widgets/common.dart";

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
              padding: EdgeInsets.fromLTRB(pad, 4, pad, 12),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
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
                  message: "Yangi mahsulot qo'shing va u kassada\n"
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
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
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
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => DialogForm(
        initial: [name],
        builder: (ctx, f, setLocal) => AlertDialog(
          title: const Text("Kategoriya"),
          content: SizedBox(
            width: 320,
            child: TextField(
              controller: f[0],
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, "__delete__"),
              style: TextButton.styleFrom(foregroundColor: Ink3.red),
              child: const Text("O'chirish"),
            ),
            const Spacer(),
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
    if (res == null) return;
    if (res == "__delete__") {
      if (!context.mounted) return;
      final ok = await askConfirm(
        context,
        title: "Kategoriyani o'chirish",
        message: "\"$name\" va undagi ${store.itemsOf(name).length} ta "
            "mahsulot o'chiriladi.",
        confirmText: "O'chirish",
        danger: true,
      );
      if (ok) {
        store.deleteCategory(name);
        setState(() => _cat = "Hammasi");
      }
      return;
    }
    store.renameCategory(name, res);
    setState(() => _cat = res.trim());
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
    return GestureDetector(
      onLongPress: onEdit,
      child: Row(
        children: [
          ChipButton(
            label: label,
            selected: selected,
            count: count,
            onTap: onTap,
          ),
          if (selected && onEdit != null)
            IconButton(
              tooltip: "Kategoriyani tahrirlash",
              onPressed: onEdit,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.edit_outlined,
                size: 15,
                color: Ink3.textFaint,
              ),
            ),
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
            child: Icon(
              iconFor(item.icon),
              size: 21,
              color: Ink3.goldSoft,
            ),
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
                  style: const TextStyle(
                    color: Ink3.textFaint,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "O'chirish",
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
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Ink3.textFaint,
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
                final price = int.tryParse(
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
