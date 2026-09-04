import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/formatters.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../models/plan.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/common.dart';

/// Three-column comparison. Free is deliberately de-emphasised; Tier 3 carries
/// the amber "Most popular" badge and a tinted column.
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  /// Width of each plan column. The feature label takes what is left.
  static const double _col = 68;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: K.pagePad.add(const EdgeInsets.only(top: 8, bottom: 28)),
          children: [
            Text(s.t('plans_title'), style: context.tt.headlineSmall),
            const SizedBox(height: 6),
            Text(s.t('plans_sub'), style: context.tt.bodySmall),
            const SizedBox(height: 18),
            HissaCard(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(
                children: [
                  _HeaderRow(current: sub.tier, col: _col),
                  const SizedBox(height: 6),
                  for (var i = 0; i < PlanFeature.rows.length; i++)
                    _FeatureRow(
                      feature: PlanFeature.rows[i],
                      col: _col,
                      striped: i.isOdd,
                      isLast: i == PlanFeature.rows.length - 1,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              s.t('plans_caption'),
              textAlign: TextAlign.center,
              style: context.tt.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 22),
            _TrialActions(sub: sub),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: context.muted,
                ),
                const SizedBox(width: 6),
                Text(
                  s.t('plans_note'),
                  style: context.tt.labelSmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final PlanTier current;
  final double col;

  const _HeaderRow({required this.current, required this.col});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              s.t('monthly_price'),
              style: context.tt.labelSmall?.copyWith(fontSize: 11),
            ),
          ),
        ),
        for (final plan in Plan.all)
          SizedBox(
            width: col,
            child: _PlanHead(plan: plan, isCurrent: plan.tier == current),
          ),
      ],
    );
  }
}

class _PlanHead extends StatelessWidget {
  final Plan plan;
  final bool isCurrent;

  const _PlanHead({required this.plan, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final free = plan.tier == PlanTier.free;
    final highlight = plan.mostPopular;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? K.amber.withValues(alpha: context.isDark ? 0.15 : 0.10)
            : null,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          if (highlight)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: K.amber,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                s.t('most_popular'),
                textAlign: TextAlign.center,
                style: context.tt.labelSmall?.copyWith(
                  color: const Color(0xFF3A2604),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          Text(
            s.t(plan.nameKey),
            textAlign: TextAlign.center,
            maxLines: 2,
            style: context.tt.labelSmall?.copyWith(
              fontSize: 10.5,
              height: 1.2,
              color: free ? context.muted : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan.priceEgp == 0 ? '0' : plan.priceEgp.toStringAsFixed(0),
            textDirection: TextDirection.ltr,
            style: context.tt.titleMedium?.copyWith(
              fontSize: 19,
              color: free
                  ? context.muted
                  : (highlight ? K.amber : context.cs.primary),
            ),
          ),
          Text(
            '${s.t('egp')}${s.t('per_month')}',
            textAlign: TextAlign.center,
            style: context.tt.labelSmall?.copyWith(fontSize: 9, height: 1.2),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 14,
            child: isCurrent
                ? Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: context.cs.primary,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final PlanFeature feature;
  final double col;
  final bool striped;
  final bool isLast;

  const _FeatureRow({
    required this.feature,
    required this.col,
    required this.striped,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      color: striped
          ? (context.isDark
                ? Colors.white.withValues(alpha: 0.025)
                : K.light.withValues(alpha: 0.7))
          : null,
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: Text(
                s.t(feature.labelKey),
                style: feature.emphasised
                    ? context.tt.titleSmall?.copyWith(fontSize: 12.5)
                    : context.tt.bodySmall?.copyWith(
                        fontSize: 12.5,
                        color: context.cs.onSurface,
                      ),
              ),
            ),
          ),
          for (final plan in Plan.all)
            Container(
              width: col,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: plan.mostPopular
                    ? K.amber.withValues(alpha: context.isDark ? 0.15 : 0.10)
                    : null,
                borderRadius: plan.mostPopular && isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(12))
                    : null,
              ),
              child: _CellView(
                cell: feature.cell(plan.tier),
                dim: plan.tier == PlanTier.free,
              ),
            ),
        ],
      ),
    );
  }
}

class _CellView extends StatelessWidget {
  final Cell cell;
  final bool dim;

  const _CellView({required this.cell, required this.dim});

  @override
  Widget build(BuildContext context) {
    if (cell.valueKey != null) {
      return Text(
        context.s.t(cell.valueKey!),
        textAlign: TextAlign.center,
        style: context.tt.labelSmall?.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: dim ? context.muted : context.cs.onSurface,
        ),
      );
    }
    if (cell.included == true) {
      return Icon(
        Icons.check_rounded,
        size: 17,
        color: dim ? context.muted : K.gain,
      );
    }
    return Text(
      '—',
      style: context.tt.bodySmall?.copyWith(
        color: context.muted.withValues(alpha: 0.6),
      ),
    );
  }
}

/// One CTA per paid tier. Tapping flips the in-memory entitlement flag
/// immediately — there is no payment step anywhere.
class _TrialActions extends StatelessWidget {
  final SubscriptionProvider sub;
  const _TrialActions({required this.sub});

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    void start(PlanTier tier) {
      sub.startTrial(tier);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.f('trial_started', [s.t(Plan.of(tier).nameKey)]),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      context.go('/home');
    }

    return Column(
      children: [
        if (sub.onTrial) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: K.gain.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 18, color: K.gain),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${s.t('current_plan')}: ${s.t(sub.plan.nameKey)}',
                    style: context.tt.titleSmall?.copyWith(fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    sub.endTrial();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(s.t('trial_ended'))),
                      );
                  },
                  child: Text(s.t('end_trial')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final plan in Plan.all.where((p) => p.isPaid))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TrialButton(
              plan: plan,
              active: sub.tier == plan.tier,
              onTap: () => start(plan.tier),
            ),
          ),
      ],
    );
  }
}

class _TrialButton extends StatelessWidget {
  final Plan plan;
  final bool active;
  final VoidCallback onTap;

  const _TrialButton({
    required this.plan,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final label = '${s.t('start_trial')} · ${s.t(plan.nameKey)}';
    final price =
        '${Fmt.egp(context, plan.priceEgp, whole: true)}${s.t('per_month')}';

    if (plan.mostPopular) {
      return FilledButton(
        onPressed: active ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: K.amber,
          foregroundColor: const Color(0xFF3A2604),
        ),
        child: _label(context, label, price, const Color(0xFF3A2604)),
      );
    }
    return OutlinedButton(
      onPressed: active ? null : onTap,
      child: _label(context, label, price, context.cs.primary),
    );
  }

  Widget _label(BuildContext context, String label, String price, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.tt.labelLarge?.copyWith(fontSize: 15, color: color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          price,
          style: context.tt.labelSmall?.copyWith(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
