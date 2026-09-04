/// A single instrument from the static snapshot in `assets/data/stocks.json`.
class Stock {
  final String ticker;
  final String nameEn;
  final String nameAr;
  final String sector;
  final double snapshotPrice;
  final double dayChangePct;
  final String marketCap;
  final double? pe;
  final double high52;
  final double low52;
  final double dividendYield;
  final bool popular;
  final String descriptionAr;
  final String descriptionEn;
  final List<double> history;

  const Stock({
    required this.ticker,
    required this.nameEn,
    required this.nameAr,
    required this.sector,
    required this.snapshotPrice,
    required this.dayChangePct,
    required this.marketCap,
    required this.pe,
    required this.high52,
    required this.low52,
    required this.dividendYield,
    required this.popular,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.history,
  });

  factory Stock.fromJson(Map<String, dynamic> j) => Stock(
    ticker: j['ticker'] as String,
    nameEn: j['name_en'] as String,
    nameAr: j['name_ar'] as String,
    sector: j['sector'] as String,
    snapshotPrice: (j['price'] as num).toDouble(),
    dayChangePct: (j['day_change_pct'] as num).toDouble(),
    marketCap: j['market_cap'] as String,
    pe: (j['pe'] as num?)?.toDouble(),
    high52: (j['high_52w'] as num).toDouble(),
    low52: (j['low_52w'] as num).toDouble(),
    dividendYield: (j['dividend_yield'] as num).toDouble(),
    popular: j['popular'] as bool? ?? false,
    descriptionAr: j['description_ar'] as String,
    descriptionEn: j['description_en'] as String,
    history: (j['history'] as List).map((e) => (e as num).toDouble()).toList(),
  );

  String name(bool isAr) => isAr ? nameAr : nameEn;
  String description(bool isAr) => isAr ? descriptionAr : descriptionEn;
  bool get isEtf => sector == 'etf';

  /// Deterministic per-ticker accent, used for the logo placeholder tile.
  int get colorSeed => ticker.codeUnits.fold<int>(0, (a, b) => a + b);
}

/// Chart ranges. The snapshot holds 90 points; each range is a tail slice of
/// it, so every range reads as the same underlying series — zooming in rather
/// than showing unrelated data.
enum ChartRange {
  d1(12, '1d'),
  w1(24, '1w'),
  m1(45, '1m'),
  y1(90, '1y');

  final int points;
  final String id;
  const ChartRange(this.points, this.id);

  String get labelKey => switch (this) {
    ChartRange.d1 => 'range_1d',
    ChartRange.w1 => 'range_1w',
    ChartRange.m1 => 'range_1m',
    ChartRange.y1 => 'range_1y',
  };
}
