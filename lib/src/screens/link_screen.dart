import "package:flutter/material.dart";

import "../sync/sync_service.dart";
import "../theme.dart";

/// Qurilmani bulutga ulash - bir marta bajariladi.
class LinkScreen extends StatefulWidget {
  const LinkScreen({super.key});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _passC = TextEditingController();
  bool _busy = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await sync.signIn(_emailC.text, _passC.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: Ink3.bgGrad),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: Ink3.goldGrad,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: Ink3.glow(Ink3.gold, 0.32),
                        ),
                        child: const Icon(
                          Icons.cloud_done_rounded,
                          size: 34,
                          color: Color(0xFF1A1206),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      "QURILMANI ULASH",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Ink3.text,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Ma'lumotlar bulutda saqlanishi uchun kassa hisobiga "
                      "bir marta kiring. Keyingi safar bu oyna chiqmaydi.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Ink3.textDim,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 26),
                    TextField(
                      controller: _emailC,
                      autofocus: true,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passC,
                      obscureText: _hide,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _connect(),
                      decoration: InputDecoration(
                        labelText: "Parol",
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _hide = !_hide),
                          icon: Icon(
                            _hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Ink3.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Ink3.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Ink3.red,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: Ink3.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _busy ? null : _connect,
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Ink3.cardHi,
                          disabledForegroundColor: Ink3.textFaint,
                        ),
                        icon: _busy
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Ink3.textFaint,
                                ),
                              )
                            : const Icon(Icons.link_rounded, size: 20),
                        label: Text(_busy ? "Ulanmoqda..." : "Ulash"),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              await sync.skipLink();
                            },
                      child: const Text(
                        "Hozircha faqat shu qurilmada ishlayman",
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Keyinroq Sozlama bo'limidan ulash mumkin.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Ink3.textFaint, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yuqori panelda turadigan kichik sinxronizatsiya ko'rsatkichi.
class SyncChip extends StatelessWidget {
  const SyncChip({super.key, this.compact = false});

  final bool compact;

  Color get _color => switch (sync.status) {
        SyncStatus.synced => Ink3.green,
        SyncStatus.syncing => Ink3.gold,
        SyncStatus.offline => Ink3.red,
        SyncStatus.signedOut => Ink3.textFaint,
        SyncStatus.disabled => Ink3.textFaint,
      };

  IconData get _icon => switch (sync.status) {
        SyncStatus.synced => Icons.cloud_done_rounded,
        SyncStatus.syncing => Icons.cloud_sync_rounded,
        SyncStatus.offline => Icons.cloud_off_rounded,
        SyncStatus.signedOut => Icons.cloud_off_rounded,
        SyncStatus.disabled => Icons.storage_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final color = _color;
        return Tooltip(
          message: sync.statusText,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: sync.enabled ? () => sync.syncNow() : null,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Ink3.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Ink3.stroke),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon, size: 15, color: color),
                    if (!compact) ...[
                      const SizedBox(width: 7),
                      Text(
                        sync.statusText,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
