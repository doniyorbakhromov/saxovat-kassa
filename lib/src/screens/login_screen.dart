import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter/services.dart";

import "../store.dart";
import "../theme.dart";
import "../utils.dart";

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  /// Nechta xato urinishdan keyin kutish boshlanadi.
  static const int _maxTries = 5;

  String _pin = "";
  bool _error = false;

  int _fails = 0;
  int _blockCount = 0;
  DateTime? _blockedUntil;
  Timer? _blockTicker;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void dispose() {
    _blockTicker?.cancel();
    _shake.dispose();
    super.dispose();
  }

  bool get _blocked =>
      _blockedUntil != null && DateTime.now().isBefore(_blockedUntil!);

  int get _waitLeft => _blockedUntil == null
      ? 0
      : _blockedUntil!.difference(DateTime.now()).inSeconds + 1;

  void _press(String d) {
    if (_blocked || _pin.length >= 8) return;
    setState(() {
      _pin += d;
      _error = false;
    });
    if (_pin.length >= store.settings.pin.length) _submit();
  }

  void _back() {
    if (_blocked || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = false;
    });
  }

  void _submit() {
    if (_blocked) return;
    if (store.login(_pin)) {
      _fails = 0;
      _blockCount = 0;
      return;
    }

    HapticFeedback.heavyImpact();
    _fails++;
    if (_fails >= _maxTries) {
      _fails = 0;
      _blockCount++;
      // 30 s, keyin 1 daq, 2 daq ... ko'pi bilan 5 daqiqa.
      final seconds = (30 * (1 << (_blockCount - 1))).clamp(30, 300);
      _blockedUntil = DateTime.now().add(Duration(seconds: seconds));
      _blockTicker?.cancel();
      _blockTicker = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (!_blocked) {
          t.cancel();
          setState(() => _error = false);
        } else {
          setState(() {});
        }
      });
    }

    setState(() {
      _error = true;
      _pin = "";
    });
    _shake.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 720;

    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent || _blocked) {
            return KeyEventResult.ignored;
          }
          final ch = event.character;
          if (ch != null && ch.length == 1 && "0123456789".contains(ch)) {
            _press(ch);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.backspace) {
            _back();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter) {
            _submit();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: Ink3.bgGrad),
          child: Stack(
            children: [
              const _Glow(
                top: -160,
                left: -120,
                color: Ink3.gold,
                size: 420,
                opacity: 0.10,
              ),
              const _Glow(
                bottom: -180,
                right: -140,
                color: Ink3.violet,
                size: 460,
                opacity: 0.09,
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Logo(compact: compact),
                          SizedBox(height: compact ? 16 : 24),
                          Text(
                            store.settings.venueName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Ink3.text,
                              fontSize: compact ? 22 : 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "KASSA TIZIMI",
                            style: TextStyle(
                              color: Ink3.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                            ),
                          ),
                          SizedBox(height: compact ? 20 : 34),
                          Text(
                            _blocked
                                ? "Juda ko'p urinish. "
                                    "$_waitLeft soniyadan keyin urinib ko'ring"
                                : _error
                                    ? "Parol noto'g'ri. Qaytadan urinib ko'ring"
                                    : "Davom etish uchun parolni kiriting",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: (_error || _blocked)
                                  ? Ink3.red
                                  : Ink3.textDim,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          AnimatedBuilder(
                            animation: _shake,
                            builder: (context, child) {
                              final t = _shake.value;
                              final dx =
                                  math.sin(t * math.pi * 6) * 14 * (1 - t);
                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: child,
                              );
                            },
                            child: _Dots(
                              count: math.max(4, store.settings.pin.length),
                              filled: _pin.length,
                              error: _error,
                            ),
                          ),
                          SizedBox(height: compact ? 22 : 34),
                          Opacity(
                            opacity: _blocked ? 0.4 : 1,
                            child: _Keypad(
                              onDigit: _press,
                              onBack: _back,
                              onEnter: _submit,
                              compact: compact,
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            "${longDate(DateTime.now())}  -  ${clock(DateTime.now())}",
                            style: const TextStyle(
                              color: Ink3.textFaint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _Logo extends StatelessWidget {
  const _Logo({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = compact ? 70.0 : 88.0;
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        gradient: Ink3.goldGrad,
        borderRadius: BorderRadius.circular(s / 3),
        boxShadow: Ink3.glow(Ink3.gold, 0.35),
      ),
      child: Icon(
        Icons.point_of_sale_rounded,
        size: s * 0.46,
        color: const Color(0xFF1A1206),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.count,
    required this.filled,
    required this.error,
  });

  final int count;
  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i < filled;
        final color = error
            ? Ink3.red
            : on
                ? Ink3.gold
                : Ink3.stroke;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: on ? 16 : 13,
          height: on ? 16 : 13,
          decoration: BoxDecoration(
            color: on ? color : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.8),
            boxShadow: on ? Ink3.glow(color, 0.5) : null,
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBack,
    required this.onEnter,
    required this.compact,
  });

  final void Function(String) onDigit;
  final VoidCallback onBack;
  final VoidCallback onEnter;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 10.0 : 14.0;
    Widget key(String label, {IconData? icon, VoidCallback? onTap, Color? c}) {
      return _KeyButton(
        label: label,
        icon: icon,
        color: c,
        compact: compact,
        onTap: onTap ?? () => onDigit(label),
      );
    }

    Widget row(List<Widget> children) => Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(child: children[i]),
              ],
            ],
          ),
        );

    return Column(
      children: [
        row([key("1"), key("2"), key("3")]),
        row([key("4"), key("5"), key("6")]),
        row([key("7"), key("8"), key("9")]),
        row([
          key(
            "",
            icon: Icons.backspace_outlined,
            onTap: onBack,
            c: Ink3.textDim,
          ),
          key("0"),
          key(
            "",
            icon: Icons.arrow_forward_rounded,
            onTap: onEnter,
            c: Ink3.gold,
          ),
        ]),
      ],
    );
  }
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.label,
    required this.onTap,
    required this.compact,
    this.icon,
    this.color,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? color;
  final bool compact;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final isAccent = widget.color == Ink3.gold;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          height: widget.compact ? 56 : 66,
          decoration: BoxDecoration(
            color: isAccent
                ? Ink3.gold.withValues(alpha: 0.14)
                : Ink3.card.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isAccent
                  ? Ink3.gold.withValues(alpha: 0.45)
                  : Ink3.stroke,
            ),
          ),
          alignment: Alignment.center,
          child: widget.icon != null
              ? Icon(widget.icon, color: widget.color ?? Ink3.text, size: 22)
              : Text(
                  widget.label,
                  style: const TextStyle(
                    color: Ink3.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.color,
    required this.size,
    required this.opacity,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
