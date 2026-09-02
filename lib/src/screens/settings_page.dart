import "package:flutter/material.dart";

import "../store.dart";
import "../sync/sync_service.dart";
import "../theme.dart";
import "../utils.dart";
import "../widgets/common.dart";

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([store, sync]),
      builder: (context, _) {
        final wide = MediaQuery.sizeOf(context).width >= 900;
        final pad = wide ? 22.0 : 14.0;

        return ListView(
          padding: EdgeInsets.fromLTRB(pad, 10, pad, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionLabel("Muassasa"),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        children: [
                          _Row(
                            icon: Icons.storefront_rounded,
                            color: Ink3.gold,
                            title: "Muassasa nomi",
                            value: store.settings.venueName,
                            onTap: () => _editName(context),
                          ),
                          const Divider(height: 22),
                          _Row(
                            icon: Icons.room_service_rounded,
                            color: Ink3.blue,
                            title: "Xizmat haqi",
                            value: store.settings.servicePercent == 0
                                ? "Yo'q"
                                : "${store.settings.servicePercent}%",
                            subtitle:
                                "Har bir chekka avtomatik qo'shiladi",
                            onTap: () => _editService(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel("Xavfsizlik"),
                    const SizedBox(height: 12),
                    AppCard(
                      child: _Row(
                        icon: Icons.lock_outline_rounded,
                        color: Ink3.violet,
                        title: "Kirish paroli",
                        value: "*" * store.settings.pin.length,
                        subtitle: "Kassaga kirish uchun raqamli parol",
                        onTap: () => _changePin(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel("Bulut"),
                    const SizedBox(height: 12),
                    const _CloudCard(),
                    const SizedBox(height: 24),
                    const SectionLabel("Ma'lumotlar"),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        children: [
                          _Row(
                            icon: Icons.table_bar_rounded,
                            color: Ink3.green,
                            title: "Stollar",
                            value: "${store.tables.length} ta",
                          ),
                          const Divider(height: 22),
                          _Row(
                            icon: Icons.restaurant_menu_rounded,
                            color: Ink3.gold,
                            title: "Menyu mahsulotlari",
                            value: "${store.menu.length} ta",
                          ),
                          const Divider(height: 22),
                          _Row(
                            icon: Icons.receipt_long_rounded,
                            color: Ink3.blue,
                            title: "Saqlangan cheklar",
                            value: "${store.receipts.length} ta",
                            subtitle: store.receipts.isEmpty
                                ? null
                                : "Oxirgisi: "
                                    "${dateTimeFull(store.receipts.first.closedAt)}",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: Ink3.goldGrad,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.local_bar_rounded,
                              color: Color(0xFF1A1206),
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Kassa tizimi  -  v1.0",
                            style: TextStyle(
                              color: Ink3.textFaint,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            !sync.enabled || !sync.isLinked
                                ? "Ma'lumotlar shu brauzer xotirasida saqlanadi"
                                : "Ma'lumotlar shu qurilmada va bulutda saqlanadi",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Ink3.textFaint,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => confirmLogout(context),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text("Kassadan chiqish"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editName(BuildContext context) async {
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => DialogForm(
        initial: [store.settings.venueName],
        builder: (ctx, f, setLocal) => AlertDialog(
          title: const Text("Muassasa nomi"),
          content: SizedBox(
            width: 340,
            child: TextField(
              controller: f[0],
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.storefront_rounded),
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
    if (res != null) store.setVenueName(res);
  }

  Future<void> _editService(BuildContext context) async {
    final res = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xizmat haqi"),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Har bir chekka qo'shiladigan foiz",
                style: TextStyle(color: Ink3.textDim, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in [0, 5, 10, 12, 15])
                    ChipButton(
                      label: p == 0 ? "Yo'q" : "$p%",
                      selected: store.settings.servicePercent == p,
                      onTap: () => Navigator.pop(ctx, p),
                    ),
                ],
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Yopish"),
          ),
        ],
      ),
    );
    if (res != null) store.setServicePercent(res);
  }

  Future<void> _changePin(BuildContext context) async {
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => DialogForm(
        initial: const ["", "", ""],
        builder: (ctx, f, setLocal) => AlertDialog(
          title: const Text("Parolni o'zgartirish"),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: f[0],
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: "Joriy parol",
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: f[1],
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Yangi parol (4-8 raqam)",
                    prefixIcon: Icon(Icons.password_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: f[2],
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Yangi parolni takrorlang",
                    prefixIcon: Icon(Icons.password_rounded),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      error!,
                      style: const TextStyle(color: Ink3.red, fontSize: 12.5),
                    ),
                  ),
                ],
              ],
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
                final oldP = f[0].text.trim();
                final newP = f[1].text.trim();
                final rep = f[2].text.trim();
                if (oldP != store.settings.pin) {
                  setLocal(() => error = "Joriy parol noto'g'ri");
                  return;
                }
                if (newP.length < 4 ||
                    newP.length > 8 ||
                    int.tryParse(newP) == null) {
                  setLocal(
                    () => error = "Parol 4-8 ta raqamdan iborat bo'lsin",
                  );
                  return;
                }
                if (newP != rep) {
                  setLocal(() => error = "Parollar mos kelmadi");
                  return;
                }
                store.setPin(newP);
                Navigator.pop(ctx);
                toast(ctx, "Parol yangilandi");
              },
              child: const Text("Saqlash"),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bulut holati va qurilmani ulash/uzish.
class _CloudCard extends StatelessWidget {
  const _CloudCard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        if (!sync.enabled) {
          return const AppCard(
            child: _Row(
              icon: Icons.storage_rounded,
              color: Ink3.textFaint,
              title: "Faqat shu qurilmada",
              value: "Yoqilmagan",
              subtitle: "Ma'lumotlar shu brauzer xotirasida saqlanadi",
            ),
          );
        }

        final linked = sync.isLinked;
        final color = switch (sync.status) {
          SyncStatus.synced => Ink3.green,
          SyncStatus.syncing => Ink3.gold,
          SyncStatus.offline => Ink3.red,
          _ => Ink3.textFaint,
        };
        final last = sync.lastSyncAt;

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Row(
                icon: Icons.cloud_done_rounded,
                color: color,
                title: "Holat",
                value: sync.statusText,
                subtitle: last == null
                    ? (linked ? null : "Qurilma hali ulanmagan")
                    : "Oxirgi saqlash: ${clock(last)}",
              ),
              if (linked) ...[
                const Divider(height: 22),
                _Row(
                  icon: Icons.person_outline_rounded,
                  color: Ink3.blue,
                  title: "Hisob",
                  value: sync.email ?? "-",
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (linked)
                    OutlinedButton.icon(
                      onPressed: () => sync.syncNow(),
                      icon: const Icon(Icons.sync_rounded, size: 17),
                      label: const Text("Hozir sinxronlash"),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => sync.askLinkAgain(),
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text("Bulutga ulash"),
                    ),
                  if (linked)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await askConfirm(
                          context,
                          title: "Qurilmani uzish",
                          message:
                              "Bulut bilan bog'lanish uziladi. Ma'lumotlar "
                              "shu qurilmada qoladi, lekin bulutga "
                              "yuborilmaydi.",
                          confirmText: "Uzish",
                          danger: true,
                        );
                        if (ok) await sync.signOut();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Ink3.red,
                        side: BorderSide(
                          color: Ink3.red.withValues(alpha: 0.4),
                        ),
                      ),
                      icon: const Icon(Icons.link_off_rounded, size: 17),
                      label: const Text("Qurilmani uzish"),
                    ),
                ],
              ),
              if (sync.status == SyncStatus.offline) ...[
                const SizedBox(height: 12),
                Text(
                  "Internet tiklanishi bilan o'zgarishlar avtomatik "
                  "yuboriladi. Kassa shu vaqtda ham ishlayveradi.",
                  style: const TextStyle(
                    color: Ink3.textFaint,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Ink3.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Ink3.textFaint,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(
                color: Ink3.textDim,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: Ink3.textFaint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
