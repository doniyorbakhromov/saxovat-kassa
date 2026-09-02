import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../store.dart";

/// Kassa belgilangan vaqt davomida tegilmasa, o'zi PIN ekraniga qaytadi.
///
/// Vaqtni sanashda taymer emas, oxirgi harakat vaqti solishtiriladi -
/// shunda brauzer fon rejimida taymerlarni sekinlashtirsa ham qulflash
/// o'z vaqtida ishlaydi. Ochiq buyurtmalar saqlanib qoladi.
class AutoLock extends StatefulWidget {
  const AutoLock({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AutoLock> createState() => _AutoLockState();
}

class _AutoLockState extends State<AutoLock> {
  static const Duration _checkEvery = Duration(seconds: 20);

  DateTime _lastActivity = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _timer = Timer.periodic(_checkEvery, (_) => _check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  /// Klaviatura hodisasini faqat qayd etamiz, ushlab qolmaymiz.
  bool _onKey(KeyEvent event) {
    _bump();
    return false;
  }

  void _bump() => _lastActivity = DateTime.now();

  void _check() {
    final minutes = store.settings.autoLockMinutes;
    if (minutes <= 0 || !store.unlocked) return;
    if (DateTime.now().difference(_lastActivity).inSeconds < minutes * 60) {
      return;
    }

    // Ochiq oyna yoki buyurtma ekrani bo'lsa - avval bosh ekranga qaytamiz,
    // aks holda qulf ostida qolib ketadi.
    widget.navigatorKey.currentState?.popUntil((r) => r.isFirst);
    store.logout();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _bump(),
      onPointerMove: (_) => _bump(),
      onPointerSignal: (_) => _bump(),
      child: widget.child,
    );
  }
}
