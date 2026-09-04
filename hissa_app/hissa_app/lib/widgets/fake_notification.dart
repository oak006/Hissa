import 'dart:async';

import 'package:flutter/material.dart';

import 'hissa_mark.dart';
import '../app/constants.dart';
import '../app/strings.dart';
import '../app/theme.dart';

/// A mock system notification that slides in over the app.
///
/// Pure theatre for the demo: it is a widget inside our own tree, not a real
/// platform notification. It is what sells the OTP step on stage — the code
/// arrives, the presenter taps it, the field fills itself.
class FakeNotification extends StatefulWidget {
  /// Delay before it slides in.
  final Duration delay;

  /// How long it stays before sliding out. Null keeps it up.
  final Duration? dismissAfter;

  final String title;
  final String body;
  final String? action;

  /// Tapping the banner. Also dismisses it.
  final VoidCallback? onTap;

  const FakeNotification({
    super.key,
    required this.title,
    required this.body,
    this.action,
    this.onTap,
    this.delay = const Duration(milliseconds: 1400),
    this.dismissAfter = const Duration(seconds: 9),
  });

  @override
  State<FakeNotification> createState() => _FakeNotificationState();
}

class _FakeNotificationState extends State<FakeNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 260),
  );
  Timer? _in;
  Timer? _out;

  @override
  void initState() {
    super.initState();
    _in = Timer(widget.delay, () {
      if (!mounted) return;
      _c.forward();
      final after = widget.dismissAfter;
      if (after != null) {
        _out = Timer(after, () {
          if (mounted) _c.reverse();
        });
      }
    });
  }

  void _dismiss() {
    _out?.cancel();
    _c.reverse();
  }

  @override
  void dispose() {
    _in?.cancel();
    _out?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _c,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1.4),
            end: Offset.zero,
          ).animate(curve),
          child: FadeTransition(
            opacity: _c,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: _Banner(
                title: widget.title,
                body: widget.body,
                action: widget.action,
                onTap: () {
                  widget.onTap?.call();
                  _dismiss();
                },
                onDismiss: _dismiss,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final String title;
  final String body;
  final String? action;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _Banner({
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Deliberately not the app's card colour — a notification should read as
    // coming from outside the app.
    final bg = context.isDark
        ? const Color(0xFF23293A).withValues(alpha: 0.97)
        : Colors.white;

    return Material(
      color: bg,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [K.royal, K.navy]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(child: HissaMark(size: 17)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: context.tt.titleSmall?.copyWith(fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.s.t('otp_notif_now'),
                          style: context.tt.labelSmall?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      body,
                      style: context.tt.bodySmall?.copyWith(
                        fontSize: 12.5,
                        height: 1.5,
                        color: context.cs.onSurface,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 13,
                            color: context.cs.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            action!,
                            style: context.tt.labelSmall?.copyWith(
                              color: context.cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                visualDensity: VisualDensity.compact,
                iconSize: 17,
                color: context.muted,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
