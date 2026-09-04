import 'package:flutter/material.dart';

import '../../app/constants.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';

/// Shared chrome for the KYC steps: a step counter, a progress bar, a title
/// block, scrollable content and a pinned primary action.
class OnboardingScaffold extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final String actionLabel;

  /// Null disables the button — the flow always *can* proceed, but the
  /// disabled state has to look real for the demo to be convincing.
  final VoidCallback? onAction;
  final bool loading;
  final Widget? secondary;

  const OnboardingScaffold({
    super.key,
    required this.step,
    this.totalSteps = 3,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.actionLabel,
    required this.onAction,
    this.loading = false,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.f('step_of', [step, totalSteps]),
          style: context.tt.labelMedium?.copyWith(fontSize: 13),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Padding(
            padding: K.pagePad,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: step / totalSteps),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOut,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 4,
                  backgroundColor: context.cs.outlineVariant,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: K.pagePad.add(const EdgeInsets.only(top: 18, bottom: 24)),
          children: [
            Text(title, style: context.tt.headlineSmall),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: context.tt.bodyMedium?.copyWith(
                color: context.muted,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 26),
            child,
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.cs.surface,
          border: Border(top: BorderSide(color: context.cs.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: loading ? null : onAction,
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(actionLabel),
                ),
                if (secondary != null) ...[
                  const SizedBox(height: 4),
                  secondary!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline validation state under a field. Never shows a hard failure — the
/// demo cannot fail — but it does show the *shape* of real validation.
class FieldHint extends StatelessWidget {
  final bool valid;
  final String validText;
  final String invalidText;
  final bool show;

  const FieldHint({
    super.key,
    required this.valid,
    required this.validText,
    required this.invalidText,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox(height: 20);
    final color = valid ? K.gain : context.muted;
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            valid ? validText : invalidText,
            style: context.tt.labelSmall?.copyWith(
              color: color,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
