import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../providers/app_provider.dart';
import 'onboarding_scaffold.dart';

/// Four questions, every answer valid. Answering all of them enables the
/// button; nothing here can produce a rejection.
class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  static const _questions = <(String, List<String>)>[
    ('risk_q1', ['risk_q1_a', 'risk_q1_b', 'risk_q1_c']),
    ('risk_q2', ['risk_q2_a', 'risk_q2_b', 'risk_q2_c']),
    ('risk_q3', ['risk_q3_a', 'risk_q3_b', 'risk_q3_c']),
    ('risk_q4', ['risk_q4_a', 'risk_q4_b', 'risk_q4_c']),
  ];

  final Map<int, int> _answers = {};
  bool _submitting = false;

  bool get _complete => _answers.length == _questions.length;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    context.read<AppProvider>().setRiskProfile('risk_balanced');
    setState(() => _submitting = false);
    context.push('/onboarding/done');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return OnboardingScaffold(
      step: 3,
      title: s.t('risk_title'),
      subtitle: s.t('risk_sub'),
      actionLabel: s.t('continue'),
      loading: _submitting,
      onAction: _complete ? _submit : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var q = 0; q < _questions.length; q++) ...[
            if (q > 0) const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  margin: const EdgeInsetsDirectional.only(end: 10, top: 1),
                  decoration: BoxDecoration(
                    color: _answers.containsKey(q)
                        ? K.gain.withValues(alpha: 0.15)
                        : context.cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: _answers.containsKey(q)
                      ? const Icon(Icons.check_rounded, size: 13, color: K.gain)
                      : Text(
                          '${q + 1}',
                          style: context.tt.labelSmall?.copyWith(
                            fontSize: 11,
                            color: context.muted,
                          ),
                        ),
                ),
                Expanded(
                  child: Text(
                    s.t(_questions[q].$1),
                    style: context.tt.titleSmall?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var a = 0; a < _questions[q].$2.length; a++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Option(
                  label: s.t(_questions[q].$2[a]),
                  selected: _answers[q] == a,
                  onTap: () => setState(() => _answers[q] = a),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? context.cs.primary.withValues(alpha: 0.10)
          : context.cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? context.cs.primary : context.cs.outlineVariant,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? context.cs.primary : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? context.cs.primary
                        : context.cs.outlineVariant,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: context.tt.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
