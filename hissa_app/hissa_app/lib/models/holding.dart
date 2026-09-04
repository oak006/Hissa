/// A fraction of a share the demo user owns.
class Holding {
  final String ticker;

  /// Fraction of one share, e.g. 0.4182 — the unit the whole product is about.
  final double fraction;

  /// Weighted average cost per whole share, in USD.
  final double avgCostUsd;

  const Holding({
    required this.ticker,
    required this.fraction,
    required this.avgCostUsd,
  });

  factory Holding.fromJson(Map<String, dynamic> j) => Holding(
    ticker: j['ticker'] as String,
    fraction: (j['fraction'] as num).toDouble(),
    avgCostUsd: (j['avg_cost_usd'] as num).toDouble(),
  );

  double valueUsd(double price) => fraction * price;
  double costUsd() => fraction * avgCostUsd;
  double gainUsd(double price) => valueUsd(price) - costUsd();
  double gainPct(double price) {
    final c = costUsd();
    if (c == 0) return 0;
    return (valueUsd(price) - c) / c * 100;
  }

  Holding copyWith({double? fraction, double? avgCostUsd}) => Holding(
    ticker: ticker,
    fraction: fraction ?? this.fraction,
    avgCostUsd: avgCostUsd ?? this.avgCostUsd,
  );

  /// Adds a buy and re-weights the average cost.
  Holding addBuy(double addedFraction, double priceUsd) {
    final newFraction = fraction + addedFraction;
    if (newFraction <= 0) return copyWith(fraction: 0);
    final newAvg = (costUsd() + addedFraction * priceUsd) / newFraction;
    return Holding(ticker: ticker, fraction: newFraction, avgCostUsd: newAvg);
  }

  /// Removes a sold fraction. Average cost is unchanged by a sale.
  Holding removeSell(double soldFraction) {
    final f = (fraction - soldFraction).clamp(0.0, double.infinity);
    return copyWith(fraction: f);
  }
}
