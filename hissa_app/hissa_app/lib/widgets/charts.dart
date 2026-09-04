import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app/constants.dart';
import '../app/formatters.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../models/stock.dart';

/// Tiny inline trend line for list rows. No axes, no touch — just the shape.
class Sparkline extends StatelessWidget {
  final List<double> points;
  final Color color;
  final double width;
  final double height;

  const Sparkline({
    super.key,
    required this.points,
    required this.color,
    this.width = 62,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return SizedBox(width: width, height: height);
    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          minY: points.reduce((a, b) => a < b ? a : b),
          maxY: points.reduce((a, b) => a > b ? a : b),
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i]),
              ],
              isCurved: true,
              curveSmoothness: 0.25,
              color: color,
              barWidth: 1.8,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

/// The main area chart used on Home and on a stock's detail page.
class PriceChart extends StatelessWidget {
  final List<double> points;
  final Color color;
  final double height;

  /// Shown as a tooltip on touch — omitted on the portfolio chart, where the
  /// series is a currency value rather than a share price.
  final bool showTooltip;

  const PriceChart({
    super.key,
    required this.points,
    required this.color,
    this.height = 190,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(child: Text('—', style: context.tt.bodySmall)),
      );
    }

    final min = points.reduce((a, b) => a < b ? a : b);
    final max = points.reduce((a, b) => a > b ? a : b);
    final pad = (max - min) * 0.12 + 0.01;

    return SizedBox(
      height: height,
      child: LineChart(
        duration: const Duration(milliseconds: 350),
        LineChartData(
          minY: min - pad,
          maxY: max + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (max - min) <= 0 ? 1 : (max - min) / 3,
            getDrawingHorizontalLine: (_) => FlLine(
              color: context.cs.outlineVariant.withValues(alpha: 0.6),
              strokeWidth: 1,
              dashArray: const [5, 6],
            ),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: showTooltip,
            getTouchedSpotIndicator: (bar, indexes) => indexes
                .map(
                  (_) => TouchedSpotIndicatorData(
                    FlLine(color: color.withValues(alpha: 0.5), strokeWidth: 1),
                    FlDotData(
                      getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                        radius: 4,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: context.cs.surface,
                      ),
                    ),
                  ),
                )
                .toList(),
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.isDark ? K.darkSurface : K.navy,
              tooltipRoundedRadius: 10,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      '\$${Fmt.price(s.y)}',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        fontFamily: context.tt.labelLarge?.fontFamily,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i]),
              ],
              isCurved: true,
              curveSmoothness: 0.22,
              color: color,
              barWidth: 2.6,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.26),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented 1D / 1W / 1M / 1Y selector.
class RangeTabs extends StatelessWidget {
  final ChartRange value;
  final ValueChanged<ChartRange> onChanged;

  const RangeTabs({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withValues(alpha: 0.05) : K.light,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: ChartRange.values.map((r) {
          final selected = r == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(r),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? context.cs.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: selected && !context.isDark
                      ? [
                          BoxShadow(
                            color: K.navy.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  context.s.t(r.labelKey),
                  textAlign: TextAlign.center,
                  style: context.tt.labelLarge?.copyWith(
                    fontSize: 12.5,
                    color: selected ? context.cs.primary : context.muted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
