import 'dart:async';

import 'package:flutter/material.dart';

import '../app/constants.dart';
import '../app/formatters.dart';
import '../app/strings.dart';
import '../app/theme.dart';

/// "locked · 0:58" — the countdown that makes the FX quote feel like a real
/// dealing rate.
///
/// It re-locks itself when it reaches zero (with a brief flash) rather than
/// dead-ending. On stage a presenter should never be blocked by an expired
/// quote mid-sentence; set [autoRenew] to false to show the expired state and
/// a manual refresh instead.
class RateLockBadge extends StatefulWidget {
  final bool autoRenew;
  final bool compact;
  final ValueChanged<int>? onTick;

  const RateLockBadge({
    super.key,
    this.autoRenew = true,
    this.compact = false,
    this.onTick,
  });

  @override
  State<RateLockBadge> createState() => _RateLockBadgeState();
}

class _RateLockBadgeState extends State<RateLockBadge> {
  int _remaining = K.rateLockSeconds;
  bool _flash = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          if (widget.autoRenew) {
            _remaining = K.rateLockSeconds;
            _flash = true;
            Future.delayed(const Duration(milliseconds: 700), () {
              if (mounted) setState(() => _flash = false);
            });
          } else {
            _remaining = 0;
            _timer?.cancel();
          }
        }
      });
      widget.onTick?.call(_remaining);
    });
  }

  void _refresh() {
    setState(() {
      _remaining = K.rateLockSeconds;
      _flash = true;
    });
    _start();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining <= 0;
    final color = expired ? K.amber : context.cs.primary;

    if (expired) {
      return _Pill(
        color: color,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_open_rounded, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              context.s.t('rate_expired'),
              style: context.tt.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _refresh,
              child: Text(
                context.s.t('requote'),
                style: context.tt.labelSmall?.copyWith(
                  color: context.cs.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return AnimatedOpacity(
      opacity: _flash ? 0.45 : 1,
      duration: const Duration(milliseconds: 250),
      child: _Pill(
        color: color,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              widget.compact
                  ? Fmt.clock(_remaining)
                  : context.s.f('rate_locked', [Fmt.clock(_remaining)]),
              textDirection: widget.compact ? TextDirection.ltr : null,
              style: context.tt.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Color color;
  final Widget child;
  const _Pill({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: child,
    );
  }
}
