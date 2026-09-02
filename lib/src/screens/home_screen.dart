import "dart:async";

import "package:flutter/material.dart";

import "../store.dart";
import "../sync/sync_service.dart";
import "../theme.dart";
import "../utils.dart";
import "../widgets/common.dart";
import "history_page.dart";
import "link_screen.dart";
import "menu_page.dart";
import "settings_page.dart";
import "tables_page.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _dest = <_Dest>[
    _Dest("Stollar", Icons.table_bar_rounded),
    _Dest("Menyu", Icons.restaurant_menu_rounded),
    _Dest("Hisobot", Icons.receipt_long_rounded),
    _Dest("Sozlama", Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final pages = <Widget>[
      const TablesPage(),
      const MenuPage(),
      const HistoryPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: Ink3.bgGrad),
        child: SafeArea(
          child: Row(
            children: [
              if (wide)
                _SideRail(
                  index: _index,
                  items: _dest,
                  onSelect: (i) => setState(() => _index = i),
                ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(wide: wide, title: _dest[_index].label),
                    Expanded(
                      child: IndexedStack(
                        index: _index,
                        sizing: StackFit.expand,
                        children: pages,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : _BottomBar(
              index: _index,
              items: _dest,
              onSelect: (i) => setState(() => _index = i),
            ),
    );
  }
}

class _Dest {
  const _Dest(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.index,
    required this.items,
    required this.onSelect,
  });

  final int index;
  final List<_Dest> items;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      margin: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      decoration: BoxDecoration(
        color: Ink3.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Ink3.strokeSoft),
      ),
      child: Column(
        children: [
          const SizedBox(height: 18),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: Ink3.goldGrad,
              borderRadius: BorderRadius.circular(14),
              boxShadow: Ink3.glow(Ink3.gold, 0.3),
            ),
            child: const Icon(
              Icons.local_bar_rounded,
              color: Color(0xFF1A1206),
              size: 22,
            ),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < items.length; i++)
            _RailItem(
              dest: items[i],
              selected: index == i,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          IconButton(
            tooltip: "Chiqish",
            onPressed: () => confirmLogout(context),
            icon: const Icon(Icons.logout_rounded, color: Ink3.textFaint),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.dest,
    required this.selected,
    required this.onTap,
  });

  final _Dest dest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: selected
                  ? Ink3.gold.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Ink3.gold.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  dest.icon,
                  size: 21,
                  color: selected ? Ink3.gold : Ink3.textFaint,
                ),
                const SizedBox(height: 5),
                Text(
                  dest.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Ink3.gold : Ink3.textFaint,
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

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.index,
    required this.items,
    required this.onSelect,
  });

  final int index;
  final List<_Dest> items;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Ink3.bgSoft,
        border: Border(top: BorderSide(color: Ink3.strokeSoft)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].icon,
                          size: 21,
                          color: index == i ? Ink3.gold : Ink3.textFaint,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: index == i ? Ink3.gold : Ink3.textFaint,
                          ),
                        ),
                      ],
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.wide, required this.title});

  final bool wide;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 22 : 16, 16, wide ? 22 : 16, 6),
      child: Row(
        children: [
          if (!wide) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: Ink3.goldGrad,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_bar_rounded,
                color: Color(0xFF1A1206),
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  wide ? store.settings.venueName : title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Ink3.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  longDate(DateTime.now()),
                  style: const TextStyle(
                    color: Ink3.textFaint,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (sync.enabled) ...[
            SyncChip(compact: !wide),
            const SizedBox(width: 8),
          ],
          const _LiveClock(),
          if (!wide) ...[
            const SizedBox(width: 6),
            IconButton(
              tooltip: "Chiqish",
              onPressed: () => confirmLogout(context),
              icon: const Icon(Icons.logout_rounded, color: Ink3.textFaint),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Ink3.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Ink3.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule_rounded, size: 15, color: Ink3.gold),
          const SizedBox(width: 7),
          Text(
            clock(_now),
            style: const TextStyle(
              color: Ink3.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
