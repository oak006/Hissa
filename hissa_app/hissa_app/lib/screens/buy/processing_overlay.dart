import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../widgets/hissa_mark.dart';
import '../../app/theme.dart';

/// Two seconds of "something is happening". Blocks input while the fake order
/// executes so a double-tap on stage cannot fire two trades.
class ProcessingOverlay extends StatelessWidget {
  final String title;
  final String? subtitle;

  const ProcessingOverlay({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 220),
          builder: (context, t, child) => Opacity(opacity: t, child: child),
          child: Container(
            color: (context.isDark ? K.darkBg : Colors.white).withValues(
              alpha: 0.93,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulsingRings(),
                const SizedBox(height: 28),
                Text(title, style: context.tt.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: context.tt.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingRings extends StatefulWidget {
  const _PulsingRings();

  @override
  State<_PulsingRings> createState() => _PulsingRingsState();
}

class _PulsingRingsState extends State<_PulsingRings>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++) _ring(context, i),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: context.cs.primary,
                  shape: BoxShape.circle,
                ),
                child: const Center(child: HissaMark(size: 25)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(BuildContext context, int index) {
    final t = ((_c.value + index / 3) % 1.0);
    return Opacity(
      opacity: (1 - t).clamp(0.0, 1.0) * 0.55,
      child: Container(
        width: 54 + t * 56,
        height: 54 + t * 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: context.cs.primary.withValues(alpha: 0.55),
            width: 1.6,
          ),
        ),
      ),
    );
  }
}

/// Reusable success mark — grows in, then draws the tick.
class SuccessCheck extends StatefulWidget {
  final Color color;
  final double size;
  const SuccessCheck({super.key, this.color = K.gain, this.size = 92});

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final scale = Curves.easeOutBack.transform(
          (_c.value / 0.6).clamp(0.0, 1.0),
        );
        final tick = Curves.easeOut.transform(
          ((_c.value - 0.35) / 0.65).clamp(0.0, 1.0),
        );
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: widget.size * 0.44,
                height: widget.size * 0.44,
                child: CustomPaint(painter: _TickPainter(widget.color, tick)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TickPainter extends CustomPainter {
  final Color color;
  final double progress;
  _TickPainter(this.color, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final p1 = Offset(size.width * 0.06, size.height * 0.52);
    final p2 = Offset(size.width * 0.40, size.height * 0.84);
    final p3 = Offset(size.width * 0.94, size.height * 0.18);

    // Two legs of the tick, drawn in sequence.
    final path = Path()..moveTo(p1.dx, p1.dy);
    if (progress <= 0.45) {
      final t = progress / 0.45;
      path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
    } else {
      final t = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}
