import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/formatters.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../models/stock.dart';
import '../../providers/app_provider.dart';
import '../../providers/market_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/rows.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ChartRange _range = ChartRange.m1;
  bool _showEgp = true;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final app = context.watch<AppProvider>();
    final market = context.watch<MarketProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final sub = context.watch<SubscriptionProvider>();

    if (market.loading || !portfolio.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final holdings = portfolio.holdings;
    final series = portfolio.valueSeries(_range);
    final dayPct = portfolio.dayChangePct;

    return Scaffold(
      floatingActionButton: _AdvisorFab(unlocked: sub.canUseAdvisor),
      body: SafeArea(
        child: ListView(
          padding: K.pagePad.add(const EdgeInsets.only(bottom: 90, top: 4)),
          children: [
            _TopBar(name: app.user.name(s.isAr)),
            if (sub.onTrial) ...[
              const SizedBox(height: 14),
              _TrialBanner(planName: s.t(sub.plan.nameKey)),
            ],
            const SizedBox(height: 16),
            _PortfolioCard(
              valueEgp: portfolio.totalValueEgp,
              valueUsd: portfolio.totalValueUsd,
              dayChangeEgp: portfolio.dayChangeUsd * K.fxEgpPerUsd,
              dayChangePct: dayPct,
              totalReturnEgp: portfolio.totalReturnUsd * K.fxEgpPerUsd,
              totalReturnPct: portfolio.totalReturnPct,
              showEgp: _showEgp,
              onToggleCurrency: () => setState(() => _showEgp = !_showEgp),
              series: series,
              range: _range,
              onRange: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 16),
            const _QuickActions(),
            const SizedBox(height: 22),
            SectionHeader(
              s.t('holdings'),
              actionLabel: holdings.isEmpty ? null : s.t('view_all'),
              onAction: () => context.go('/invest'),
            ),
            const SizedBox(height: 4),
            if (holdings.isEmpty)
              EmptyState(
                icon: Icons.pie_chart_outline_rounded,
                title: s.t('no_holdings'),
                subtitle: s.t('no_holdings_sub'),
                actionLabel: s.t('browse_stocks'),
                onAction: () => context.go('/invest'),
              )
            else
              HissaCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < holdings.length; i++) ...[
                      if (i > 0) Divider(color: context.cs.outlineVariant),
                      Builder(
                        builder: (context) {
                          final h = holdings[i];
                          final stock = market.byTicker(h.ticker);
                          if (stock == null) return const SizedBox.shrink();
                          return HoldingRow(
                            stock: stock,
                            holding: h,
                            price: market.priceOf(h.ticker),
                            dayChangePct: market.dayChangePctOf(h.ticker),
                            showEgp: _showEgp,
                            onTap: () => context.push('/stock/${h.ticker}'),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            DemoDataNote(market.asOf),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String name;
  const _TopBar({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.cs.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            name.characters.first,
            style: context.tt.titleMedium?.copyWith(color: context.cs.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.s.f('greeting', [name]),
                style: context.tt.titleMedium,
              ),
              Text(
                context.s.t('tagline'),
                style: context.tt.bodySmall?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context.go('/settings'),
          icon: const Icon(Icons.settings_outlined),
          tooltip: context.s.t('settings_title'),
        ),
      ],
    );
  }
}

class _TrialBanner extends StatelessWidget {
  final String planName;
  const _TrialBanner({required this.planName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: K.amber.withValues(alpha: context.isDark ? 0.18 : 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: K.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 18, color: K.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.s.f('trial_banner', [planName]),
              style: context.tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.isDark ? const Color(0xFFF0C368) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The headline card: value in both currencies, today's move, total return,
/// and the performance curve.
class _PortfolioCard extends StatelessWidget {
  final double valueEgp;
  final double valueUsd;
  final double dayChangeEgp;
  final double dayChangePct;
  final double totalReturnEgp;
  final double totalReturnPct;
  final bool showEgp;
  final VoidCallback onToggleCurrency;
  final List<double> series;
  final ChartRange range;
  final ValueChanged<ChartRange> onRange;

  const _PortfolioCard({
    required this.valueEgp,
    required this.valueUsd,
    required this.dayChangeEgp,
    required this.dayChangePct,
    required this.totalReturnEgp,
    required this.totalReturnPct,
    required this.showEgp,
    required this.onToggleCurrency,
    required this.series,
    required this.range,
    required this.onRange,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final lineColor = context.deltaColor(totalReturnPct);

    return HissaCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s.t('portfolio_value'), style: context.tt.bodySmall),
              const Spacer(),
              _CurrencyToggle(showEgp: showEgp, onToggle: onToggleCurrency),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              showEgp ? Fmt.egp(context, valueEgp) : Fmt.usd(context, valueUsd),
              key: ValueKey('$showEgp${valueEgp.toStringAsFixed(0)}'),
              style: context.tt.displaySmall?.copyWith(fontSize: 32),
            ),
          ),
          const SizedBox(height: 4),
          // The secondary currency, always visible — this is a dual-currency
          // product and hiding one half undersells it.
          Text(
            showEgp
                ? '≈ ${Fmt.usd(context, valueUsd)}'
                : '≈ ${Fmt.egp(context, valueEgp)}',
            style: context.tt.bodySmall?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric(
                label: s.t('todays_change'),
                amount: Fmt.signedEgp(context, dayChangeEgp),
                pct: dayChangePct,
              ),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: context.cs.outlineVariant,
              ),
              _Metric(
                label: s.t('total_return'),
                amount: Fmt.signedEgp(context, totalReturnEgp),
                pct: totalReturnPct,
              ),
            ],
          ),
          const SizedBox(height: 10),
          PriceChart(
            points: series,
            color: lineColor,
            height: 150,
            showTooltip: false,
          ),
          const SizedBox(height: 10),
          RangeTabs(value: range, onChanged: onRange),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String amount;
  final double pct;

  const _Metric({required this.label, required this.amount, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.tt.labelSmall?.copyWith(fontSize: 11)),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              amount,
              style: context.tt.titleSmall?.copyWith(
                fontSize: 14,
                color: context.deltaColor(pct),
              ),
            ),
            const SizedBox(width: 6),
            DeltaText(pct, fontSize: 11.5, showArrow: false),
          ],
        ),
      ],
    );
  }
}

class _CurrencyToggle extends StatelessWidget {
  final bool showEgp;
  final VoidCallback onToggle;

  const _CurrencyToggle({required this.showEgp, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : K.light,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _seg(context, context.s.t('egp'), showEgp),
            _seg(context, 'USD', !showEgp),
          ],
        ),
      ),
    );
  }

  Widget _seg(BuildContext context, String label, bool on) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: on ? context.cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: context.tt.labelSmall?.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: on ? Colors.white : context.muted,
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Row(
      children: [
        Expanded(
          child: _Action(
            icon: Icons.add_rounded,
            label: s.t('deposit'),
            primary: true,
            onTap: () {
              context.read<PortfolioProvider>().deposit(1000);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(s.t('deposit_demo'))));
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Action(
            icon: Icons.trending_up_rounded,
            label: s.t('invest'),
            onTap: () => context.go('/invest'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Action(
            icon: Icons.autorenew_rounded,
            label: s.t('auto_invest'),
            onTap: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(s.t('auto_invest_soon'))),
                );
            },
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? context.cs.primary : context.cs.surface;
    final fg = primary ? Colors.white : context.cs.primary;
    return HissaCard(
      color: bg,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.tt.labelLarge?.copyWith(
              fontSize: 12,
              color: primary ? Colors.white : context.cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Always present — locked on Free, which is what makes the paywall demoable.
class _AdvisorFab extends StatelessWidget {
  final bool unlocked;
  const _AdvisorFab({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.push('/chat'),
      backgroundColor: context.cs.primary,
      foregroundColor: Colors.white,
      icon: Icon(
        unlocked ? Icons.auto_awesome_rounded : Icons.lock_outline_rounded,
        size: 19,
      ),
      label: Text(
        context.s.t('ask_advisor'),
        style: context.tt.labelLarge?.copyWith(
          color: Colors.white,
          fontSize: 13.5,
        ),
      ),
    );
  }
}
