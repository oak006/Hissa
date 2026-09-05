import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/formatters.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../models/holding.dart';
import '../../models/stock.dart';
import '../../providers/market_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/common.dart';

/// The full position list, reached from "View all" on Home.
///
/// Home answers "what do I own?"; this answers "how is each one doing?" —
/// every position with its cost basis, its own profit and loss, and its weight
/// in the portfolio. Sorted by value, so the position that matters most to the
/// total is at the top.
class HoldingsScreen extends StatelessWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final market = context.watch<MarketProvider>();
    final portfolio = context.watch<PortfolioProvider>();

    if (market.loading || !portfolio.ready) {
      return Scaffold(
        appBar: AppBar(title: Text(s.t('holdings'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final invested = portfolio.investedUsd;
    final rows =
        <(Holding, Stock)>[
          for (final h in portfolio.holdings)
            if (market.byTicker(h.ticker) case final stock?) (h, stock),
        ]..sort(
          (a, b) => b.$1
              .valueUsd(market.priceOf(b.$1.ticker))
              .compareTo(a.$1.valueUsd(market.priceOf(a.$1.ticker))),
        );

    return Scaffold(
      appBar: AppBar(title: Text(s.t('holdings'))),
      body: SafeArea(
        top: false,
        child: rows.isEmpty
            ? EmptyState(
                icon: Icons.pie_chart_outline_rounded,
                title: s.t('no_holdings'),
                subtitle: s.t('no_holdings_sub'),
                actionLabel: s.t('browse_stocks'),
                onAction: () => context.go('/invest'),
              )
            : ListView(
                padding: K.pagePad.add(const EdgeInsets.only(bottom: 28)),
                children: [
                  _Summary(
                    investedEgp: invested * K.fxEgpPerUsd,
                    investedUsd: invested,
                    returnEgp: portfolio.totalReturnUsd * K.fxEgpPerUsd,
                    returnPct: portfolio.totalReturnPct,
                    positions: rows.length,
                  ),
                  const SizedBox(height: 18),
                  for (final (holding, stock) in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PositionCard(
                        // A stable handle for tests, and unambiguous: the
                        // ticker itself renders twice per card (logo + row).
                        key: ValueKey('holding-${stock.ticker}'),
                        holding: holding,
                        stock: stock,
                        price: market.priceOf(stock.ticker),
                        dayChangePct: market.dayChangePctOf(stock.ticker),
                        // Weight of this position among the holdings.
                        weight: invested == 0
                            ? 0
                            : holding.valueUsd(market.priceOf(stock.ticker)) /
                                  invested,
                      ),
                    ),
                  DemoDataNote(market.asOf),
                ],
              ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final double investedEgp;
  final double investedUsd;
  final double returnEgp;
  final double returnPct;
  final int positions;

  const _Summary({
    required this.investedEgp,
    required this.investedUsd,
    required this.returnEgp,
    required this.returnPct,
    required this.positions,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return HissaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.t('invested_value'), style: context.tt.bodySmall),
          const SizedBox(height: 5),
          Text(
            Fmt.egp(context, investedEgp),
            style: context.tt.displaySmall?.copyWith(fontSize: 29),
          ),
          const SizedBox(height: 3),
          Text(
            '≈ ${Fmt.usd(context, investedUsd)}',
            style: context.tt.bodySmall?.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.t('total_return'),
                      style: context.tt.labelSmall?.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          Fmt.signedEgp(context, returnEgp),
                          style: context.tt.titleSmall?.copyWith(
                            fontSize: 14,
                            color: context.deltaColor(returnPct),
                          ),
                        ),
                        const SizedBox(width: 6),
                        DeltaText(returnPct, fontSize: 11.5, showArrow: false),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    s.t('positions'),
                    style: context.tt.labelSmall?.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$positions',
                    textDirection: TextDirection.ltr,
                    style: context.tt.titleSmall?.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PositionCard extends StatelessWidget {
  final Holding holding;
  final Stock stock;
  final double price;
  final double dayChangePct;
  final double weight;

  const _PositionCard({
    super.key,
    required this.holding,
    required this.stock,
    required this.price,
    required this.dayChangePct,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final valueUsd = holding.valueUsd(price);
    final gainPct = holding.gainPct(price);

    return HissaCard(
      onTap: () => context.push('/stock/${stock.ticker}'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              TickerLogo(ticker: stock.ticker, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          stock.ticker,
                          textDirection: TextDirection.ltr,
                          style: context.tt.titleSmall?.copyWith(fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.cs.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            Fmt.fraction(holding.fraction),
                            textDirection: TextDirection.ltr,
                            style: context.tt.labelSmall?.copyWith(
                              color: context.cs.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stock.name(s.isAr),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.tt.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Fmt.egp(context, valueUsd * K.fxEgpPerUsd),
                    style: context.tt.titleSmall?.copyWith(fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  DeltaText(dayChangePct, fontSize: 12, showArrow: false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: context.cs.outlineVariant),
          const SizedBox(height: 10),
          Row(
            children: [
              _Stat(
                label: s.t('avg_cost'),
                value: '\$${Fmt.price(holding.avgCostUsd)}',
              ),
              _Stat(
                label: s.t('position_return'),
                value: Fmt.signedUsd(context, holding.gainUsd(price)),
                color: context.deltaColor(gainPct),
                suffix: gainPct,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Allocation(weight: weight),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  /// When set, a signed percentage is shown beside the value.
  final double? suffix;

  const _Stat({
    required this.label,
    required this.value,
    this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.tt.labelSmall?.copyWith(fontSize: 10.5)),
          const SizedBox(height: 3),
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.tt.titleSmall?.copyWith(
                    fontSize: 13.5,
                    color: color,
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 5),
                DeltaText(suffix!, fontSize: 11, showArrow: false),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// How much of the portfolio this one position carries.
class _Allocation extends StatelessWidget {
  final double weight;
  const _Allocation({required this.weight});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.s.t('allocation'),
          style: context.tt.labelSmall?.copyWith(fontSize: 10.5),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: weight.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: context.cs.outlineVariant,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(weight * 100).toStringAsFixed(1)}%',
          textDirection: TextDirection.ltr,
          style: context.tt.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.cs.onSurface,
          ),
        ),
      ],
    );
  }
}
