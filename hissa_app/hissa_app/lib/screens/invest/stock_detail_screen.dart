import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/constants.dart';
import '../../app/formatters.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../models/stock.dart';
import '../../providers/market_provider.dart';
import '../../providers/portfolio_provider.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';

class StockDetailScreen extends StatefulWidget {
  final String ticker;
  const StockDetailScreen({super.key, required this.ticker});

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  ChartRange _range = ChartRange.m1;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final market = context.watch<MarketProvider>();
    final portfolio = context.watch<PortfolioProvider>();
    final stock = market.byTicker(widget.ticker);

    if (stock == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(s.t('no_results'))),
      );
    }

    final price = market.priceOf(stock.ticker);
    final dayPct = market.dayChangePctOf(stock.ticker);
    final owned = portfolio.fractionOf(stock.ticker);
    final series = _slice(stock.history, _range.points);
    final color = context.deltaColor(series.last - series.first);

    return Scaffold(
      appBar: AppBar(
        title: Text(stock.ticker, textDirection: TextDirection.ltr),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(child: _SectorTag(sector: stock.sector)),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: K.pagePad.add(const EdgeInsets.only(bottom: 20)),
          children: [
            Row(
              children: [
                TickerLogo(ticker: stock.ticker, size: 50),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stock.name(s.isAr), style: context.tt.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        stock.ticker,
                        textDirection: TextDirection.ltr,
                        style: context.tt.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    '\$${Fmt.price(price)}',
                    key: ValueKey(price),
                    textDirection: TextDirection.ltr,
                    style: context.tt.displaySmall?.copyWith(fontSize: 32),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: DeltaChip(dayPct),
                ),
              ],
            ),
            if (owned > 0) ...[
              const SizedBox(height: 10),
              _OwnedBadge(fraction: owned),
            ],
            const SizedBox(height: 16),
            HissaCard(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              child: Column(
                children: [
                  PriceChart(points: series, color: color, height: 180),
                  const SizedBox(height: 12),
                  RangeTabs(
                    value: _range,
                    onChanged: (r) => setState(() => _range = r),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(s.t('key_stats')),
            const SizedBox(height: 8),
            HissaCard(
              child: Column(
                children: [
                  KeyValueRow(
                    label: s.t('market_cap'),
                    value: '\$${stock.marketCap}',
                  ),
                  KeyValueRow(
                    label: s.t('pe_ratio'),
                    value: stock.pe == null
                        ? s.t('not_available')
                        : stock.pe!.toStringAsFixed(1),
                  ),
                  KeyValueRow(
                    label: s.t('range_52w'),
                    value:
                        '\$${Fmt.price(stock.low52)} — '
                        '\$${Fmt.price(stock.high52)}',
                  ),
                  KeyValueRow(
                    label: s.t('dividend_yield'),
                    value: stock.dividendYield == 0
                        ? '—'
                        : '${stock.dividendYield.toStringAsFixed(2)}%',
                  ),
                  const SizedBox(height: 6),
                  _Range52Bar(
                    low: stock.low52,
                    high: stock.high52,
                    current: price,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionHeader(s.t('about_company')),
            const SizedBox(height: 8),
            HissaCard(
              child: Text(
                stock.description(s.isAr),
                style: context.tt.bodyMedium?.copyWith(height: 1.75),
              ),
            ),
            DemoDataNote(market.asOf),
          ],
        ),
      ),
      bottomNavigationBar: _ActionBar(ticker: stock.ticker, canSell: owned > 0),
    );
  }

  List<double> _slice(List<double> history, int points) {
    final take = points.clamp(2, history.length);
    return history.sublist(history.length - take);
  }
}

class _SectorTag extends StatelessWidget {
  final String sector;
  const _SectorTag({required this.sector});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        context.s.t('sector_$sector'),
        style: context.tt.labelSmall?.copyWith(fontSize: 11),
      ),
    );
  }
}

class _OwnedBadge extends StatelessWidget {
  final double fraction;
  const _OwnedBadge({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pie_chart_rounded, size: 14, color: context.cs.primary),
          const SizedBox(width: 7),
          Text(
            context.s.f('you_own_frac', [Fmt.fraction(fraction)]),
            style: context.tt.labelLarge?.copyWith(
              fontSize: 12.5,
              color: context.cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Where today's price sits inside the 52-week band.
class _Range52Bar extends StatelessWidget {
  final double low;
  final double high;
  final double current;

  const _Range52Bar({
    required this.low,
    required this.high,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final t = high == low
        ? 0.5
        : ((current - low) / (high - low)).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, box) {
        return SizedBox(
          height: 22,
          child: Stack(
            children: [
              Positioned(
                top: 9,
                left: 0,
                right: 0,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        K.loss.withValues(alpha: 0.35),
                        K.amber.withValues(alpha: 0.35),
                        K.gain.withValues(alpha: 0.35),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              PositionedDirectional(
                start: (box.maxWidth - 12) * t,
                top: 4,
                child: Container(
                  width: 12,
                  height: 15,
                  decoration: BoxDecoration(
                    color: context.cs.primary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: context.cs.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionBar extends StatelessWidget {
  final String ticker;
  final bool canSell;

  const _ActionBar({required this.ticker, required this.canSell});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cs.surface,
        border: Border(top: BorderSide(color: context.cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              if (canSell) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/trade/$ticker?mode=sell'),
                    child: Text(context.s.t('sell')),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: canSell ? 1 : 1,
                child: FilledButton(
                  onPressed: () => context.push('/trade/$ticker?mode=buy'),
                  child: Text(context.s.t('buy')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
