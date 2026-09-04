// Generates assets/data/*.json — a STATIC snapshot for the demo.
// Deterministic: seeded PRNG, so re-running produces identical files.
// Run from the project root:  dart run tool/gen_data.dart
import 'dart:convert';
import 'dart:io';

const asOf = '2026-08-28';

class Seed {
  final String ticker;
  final String nameEn;
  final String nameAr;
  final String
  sector; // technology | etf | consumer | financial | communication
  final double price;
  final double dayChangePct;
  final String marketCap;
  final double? pe;
  final double high52;
  final double low52;
  final double divYield;
  final bool popular;
  final String descAr;
  final String descEn;
  const Seed(
    this.ticker,
    this.nameEn,
    this.nameAr,
    this.sector,
    this.price,
    this.dayChangePct,
    this.marketCap,
    this.pe,
    this.high52,
    this.low52,
    this.divYield,
    this.popular,
    this.descAr,
    this.descEn,
  );
}

const seeds = <Seed>[
  Seed(
    'NVDA',
    'NVIDIA Corporation',
    'إنفيديا',
    'technology',
    213.44,
    1.82,
    '5.21T',
    52.4,
    224.80,
    86.62,
    0.02,
    true,
    'إنفيديا هي الشركة الرائدة عالميًا في تصنيع الرقائق ووحدات معالجة الرسوميات التي تشغّل الذكاء الاصطناعي وألعاب الفيديو ومراكز البيانات. تحوّلت من شركة رسوميات إلى العمود الفقري لثورة الذكاء الاصطناعي.',
    'NVIDIA designs the GPUs and AI accelerators that power data centres, gaming and machine learning worldwide.',
  ),
  Seed(
    'AAPL',
    'Apple Inc.',
    'أبل',
    'technology',
    241.86,
    -0.43,
    '3.62T',
    36.1,
    260.10,
    169.21,
    0.42,
    true,
    'أبل من أكبر شركات التكنولوجيا في العالم، تصنع الآيفون والماك والآيباد والساعة الذكية، ولديها قطاع خدمات ضخم ومتنامٍ يشمل التطبيقات والاشتراكات.',
    'Apple makes the iPhone, Mac and iPad, alongside a large and growing services business.',
  ),
  Seed(
    'MSFT',
    'Microsoft Corporation',
    'مايكروسوفت',
    'technology',
    512.30,
    0.67,
    '3.81T',
    34.8,
    555.45,
    385.58,
    0.66,
    true,
    'مايكروسوفت شركة برمجيات وحوسبة سحابية عملاقة، تملك ويندوز وأوفيس ومنصة أزور السحابية، وهي من أكبر المستثمرين في الذكاء الاصطناعي.',
    'Microsoft spans Windows, Office, the Azure cloud platform and a leading position in enterprise AI.',
  ),
  Seed(
    'GOOGL',
    'Alphabet Inc.',
    'ألفابت (جوجل)',
    'communication',
    205.67,
    1.14,
    '2.49T',
    25.3,
    214.30,
    140.53,
    0.41,
    true,
    'ألفابت هي الشركة الأم لجوجل ويوتيوب، وتعتمد إيراداتها بشكل أساسي على الإعلانات، إضافةً إلى الحوسبة السحابية ومشاريع الذكاء الاصطناعي.',
    'Alphabet is the parent of Google and YouTube, with search advertising, cloud and AI research.',
  ),
  Seed(
    'AMZN',
    'Amazon.com, Inc.',
    'أمازون',
    'consumer',
    232.15,
    0.38,
    '2.46T',
    37.2,
    249.15,
    161.38,
    0.0,
    true,
    'أمازون أكبر منصة تجارة إلكترونية في العالم، وتملك أيضًا AWS أكبر مزوّد للخدمات السحابية، وهو المصدر الأكبر لأرباح الشركة.',
    'Amazon runs the world largest e-commerce marketplace plus AWS, the leading cloud provider.',
  ),
  Seed(
    'META',
    'Meta Platforms, Inc.',
    'ميتا',
    'communication',
    748.92,
    -1.06,
    '1.88T',
    27.6,
    796.25,
    479.80,
    0.28,
    true,
    'ميتا هي الشركة المالكة لفيسبوك وإنستجرام وواتساب، وتعتمد على الإعلانات الرقمية، وتستثمر بكثافة في الذكاء الاصطناعي والواقع الافتراضي.',
    'Meta owns Facebook, Instagram and WhatsApp, monetised through digital advertising.',
  ),
  Seed(
    'TSLA',
    'Tesla, Inc.',
    'تسلا',
    'consumer',
    342.18,
    2.44,
    '1.10T',
    71.9,
    488.54,
    214.25,
    0.0,
    true,
    'تسلا شركة سيارات كهربائية وتخزين طاقة، وتعمل كذلك على القيادة الذاتية والروبوتات. سهمها معروف بتقلباته العالية.',
    'Tesla builds electric vehicles and energy storage, with autonomy and robotics programmes.',
  ),
  Seed(
    'AMD',
    'Advanced Micro Devices',
    'إيه إم دي',
    'technology',
    178.55,
    1.97,
    '289B',
    44.7,
    211.38,
    76.48,
    0.0,
    false,
    'إيه إم دي تصنع المعالجات ووحدات الرسوميات، وتنافس إنتل وإنفيديا في أسواق الحواسيب ومراكز البيانات ورقائق الذكاء الاصطناعي.',
    'AMD designs CPUs and GPUs, competing in PCs, data centres and AI accelerators.',
  ),
  Seed(
    'NFLX',
    'Netflix, Inc.',
    'نتفليكس',
    'communication',
    1187.40,
    -0.72,
    '505B',
    44.2,
    1341.15,
    812.60,
    0.0,
    false,
    'نتفليكس أكبر منصة بث ترفيهي بالاشتراك في العالم، وتنتج محتواها الأصلي وتوسّع نموذجها ليشمل الإعلانات.',
    'Netflix is the largest subscription streaming service, expanding into ad-supported plans.',
  ),
  Seed(
    'PLTR',
    'Palantir Technologies',
    'بالانتير',
    'technology',
    158.22,
    3.21,
    '372B',
    214.5,
    190.00,
    62.15,
    0.0,
    false,
    'بالانتير تقدّم منصات تحليل بيانات وذكاء اصطناعي للحكومات والشركات الكبرى. سهم عالي النمو وعالي التقييم والتقلب.',
    'Palantir sells data-analysis and AI platforms to governments and large enterprises.',
  ),
  Seed(
    'SPY',
    'SPDR S&P 500 ETF Trust',
    'صندوق إس آند بي 500',
    'etf',
    648.75,
    0.31,
    '648B',
    null,
    665.20,
    481.80,
    1.18,
    true,
    'صندوق مؤشر يتتبع أكبر 500 شركة أمريكية. شراء وحدة واحدة يعني توزيع أموالك على 500 شركة دفعة واحدة — خيار شائع للمبتدئين.',
    'An index fund tracking the 500 largest US companies — instant broad diversification.',
  ),
  Seed(
    'VOO',
    'Vanguard S&P 500 ETF',
    'فانجارد إس آند بي 500',
    'etf',
    596.30,
    0.29,
    '1.45T',
    null,
    611.40,
    442.75,
    1.24,
    true,
    'صندوق فانجارد لمؤشر إس آند بي 500، يشبه SPY لكن برسوم إدارية أقل، وهو من أكثر الصناديق شعبية للاستثمار طويل الأجل.',
    'Vanguard S&P 500 tracker with a very low expense ratio, popular for long-term investing.',
  ),
  Seed(
    'QQQ',
    'Invesco QQQ Trust',
    'إنفيسكو ناسداك 100',
    'etf',
    578.90,
    0.54,
    '392B',
    null,
    601.30,
    402.39,
    0.51,
    true,
    'صندوق يتتبع أكبر 100 شركة غير مالية في بورصة ناسداك، ويغلب عليه قطاع التكنولوجيا. نمو أعلى وتقلب أعلى من إس آند بي 500.',
    'Tracks the 100 largest non-financial Nasdaq companies — technology heavy.',
  ),
  Seed(
    'VTI',
    'Vanguard Total Stock Market',
    'فانجارد إجمالي السوق',
    'etf',
    322.45,
    0.27,
    '1.82T',
    null,
    331.60,
    239.20,
    1.26,
    false,
    'صندوق يغطي سوق الأسهم الأمريكي بالكامل تقريبًا — أكثر من ثلاثة آلاف شركة كبيرة ومتوسطة وصغيرة في ورقة واحدة.',
    'Covers essentially the entire US stock market in a single fund.',
  ),
  Seed(
    'KO',
    'The Coca-Cola Company',
    'كوكا كولا',
    'consumer',
    71.28,
    0.21,
    '307B',
    25.9,
    76.10,
    60.62,
    2.86,
    false,
    'كوكا كولا من أعرق شركات المشروبات في العالم، وتُعرف بثبات أرباحها وتوزيعاتها النقدية المنتظمة على المساهمين منذ عقود.',
    'A global beverage company known for stable earnings and a long dividend record.',
  ),
  Seed(
    'NKE',
    'NIKE, Inc.',
    'نايكي',
    'consumer',
    78.64,
    -0.88,
    '116B',
    32.4,
    98.15,
    52.28,
    2.05,
    false,
    'نايكي أكبر شركة ملابس وأحذية رياضية في العالم، وتبيع عبر متاجرها ومنصاتها الرقمية في أكثر من 190 دولة.',
    'The largest athletic footwear and apparel brand, selling in over 190 countries.',
  ),
  Seed(
    'DIS',
    'The Walt Disney Company',
    'ديزني',
    'communication',
    118.35,
    0.62,
    '213B',
    21.7,
    126.40,
    80.10,
    0.85,
    false,
    'ديزني إمبراطورية ترفيه تضم الأفلام والاستوديوهات والمنتزهات ومنصة ديزني بلس للبث، إضافةً إلى شبكات رياضية وإعلامية.',
    'Disney spans studios, theme parks, streaming and sports media.',
  ),
  Seed(
    'V',
    'Visa Inc.',
    'فيزا',
    'financial',
    356.70,
    0.44,
    '689B',
    33.5,
    375.50,
    272.85,
    0.66,
    false,
    'فيزا تدير أكبر شبكة مدفوعات إلكترونية في العالم. لا تقرض المال، بل تكسب رسومًا صغيرة على كل عملية دفع تمر عبر شبكتها.',
    'Visa operates the largest electronic payments network, earning fees on each transaction.',
  ),
  Seed(
    'JPM',
    'JPMorgan Chase & Co.',
    'جي بي مورجان تشيس',
    'financial',
    298.40,
    -0.35,
    '826B',
    14.2,
    312.75,
    201.30,
    1.95,
    false,
    'جي بي مورجان أكبر بنك أمريكي من حيث الأصول، ويعمل في الخدمات المصرفية للأفراد والشركات والاستثمار وإدارة الثروات.',
    'The largest US bank by assets, spanning retail, corporate and investment banking.',
  ),
  Seed(
    'MCD',
    'McDonald\'s Corporation',
    'ماكدونالدز',
    'consumer',
    312.85,
    0.18,
    '223B',
    26.8,
    326.30,
    269.45,
    2.29,
    false,
    'ماكدونالدز أكبر سلسلة مطاعم وجبات سريعة عالميًا، ويعتمد نموذجها بشكل كبير على الامتياز التجاري والعقارات.',
    'The largest fast-food chain globally, built on a franchising and real-estate model.',
  ),
];

/// Small deterministic LCG so the generated snapshot never changes between runs.
class Lcg {
  int _s;
  Lcg(int seed) : _s = seed & 0x7fffffff;
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }

  /// Centred noise in [-1, 1].
  double noise() => next() * 2 - 1;
}

/// Builds a 90-point random walk that lands exactly on [end].
List<double> history(String ticker, double end, double vol) {
  final rnd = Lcg(ticker.codeUnits.fold<int>(7, (a, b) => a * 31 + b));
  // Walk backwards from the close, then reverse — guarantees the last point
  // is the quoted price.
  final pts = <double>[end];
  var p = end;
  // Upward drift going forward == downward drift going backward. Kept large
  // enough relative to [vol] that the 90-point window reads as a trend rather
  // than as noise — a stock quoted as up should not chart as a slump.
  final drift = driftFor(ticker) * (0.85 + rnd.next() * 0.3);
  for (var i = 0; i < 89; i++) {
    p = p / (1 + drift + rnd.noise() * vol);
    pts.add(p);
  }
  final out = pts.reversed
      .map((v) => double.parse(v.toStringAsFixed(2)))
      .toList();
  out[out.length - 1] = end;
  return out;
}

/// Per-step volatility. Index funds wobble least, high-beta names most.
double vol(String sector, String ticker) {
  if (sector == 'etf') return 0.0045;
  if (ticker == 'TSLA' || ticker == 'PLTR' || ticker == 'NVDA') return 0.0135;
  if (sector == 'consumer' || sector == 'financial') return 0.006;
  return 0.009;
}

/// Per-step drift, compounded over 90 points. Roughly: 0.003 -> +30% across
/// the window, 0.0011 -> +10%.
double driftFor(String ticker) => switch (ticker) {
  'NVDA' || 'PLTR' || 'AMD' => 0.0034,
  'TSLA' => 0.0016,
  'MSFT' || 'GOOGL' || 'AMZN' || 'META' || 'AAPL' || 'NFLX' => 0.0022,
  'SPY' || 'VOO' || 'QQQ' || 'VTI' => 0.0018,
  _ => 0.0011,
};

void main() {
  final stocks = seeds.map((s) {
    final hist = history(s.ticker, s.price, vol(s.sector, s.ticker));
    return {
      'ticker': s.ticker,
      'name_en': s.nameEn,
      'name_ar': s.nameAr,
      'sector': s.sector,
      'price': s.price,
      'day_change_pct': s.dayChangePct,
      'market_cap': s.marketCap,
      'pe': s.pe,
      'high_52w': s.high52,
      'low_52w': s.low52,
      'dividend_yield': s.divYield,
      'popular': s.popular,
      'description_ar': s.descAr,
      'description_en': s.descEn,
      'history': hist,
    };
  }).toList();

  write('assets/data/stocks.json', {'as_of': asOf, 'stocks': stocks});

  // Demo portfolio: 6 holdings, modest overall gain (~+11%), believable sizes.
  final holdings = [
    {'ticker': 'NVDA', 'fraction': 0.4182, 'avg_cost_usd': 181.40},
    {'ticker': 'AAPL', 'fraction': 0.2650, 'avg_cost_usd': 228.15},
    {'ticker': 'SPY', 'fraction': 0.1930, 'avg_cost_usd': 612.30},
    {'ticker': 'MSFT', 'fraction': 0.0975, 'avg_cost_usd': 486.70},
    {'ticker': 'TSLA', 'fraction': 0.1540, 'avg_cost_usd': 355.80},
    {'ticker': 'KO', 'fraction': 0.8400, 'avg_cost_usd': 68.95},
  ];
  write('assets/data/portfolio.json', {
    'as_of': asOf,
    'cash_egp': 12480.75,
    'cash_usd': 63.40,
    'holdings': holdings,
  });

  final tx = [
    txn(
      't01',
      'buy',
      '2026-08-26T11:42:00',
      'NVDA',
      0.0512,
      500.0,
      10.86,
      'completed',
    ),
    txn(
      't02',
      'deposit',
      '2026-08-24T09:15:00',
      null,
      null,
      5000.0,
      null,
      'completed',
    ),
    txn(
      't03',
      'convert',
      '2026-08-24T09:18:00',
      null,
      null,
      5000.0,
      105.75,
      'completed',
    ),
    txn(
      't04',
      'dividend',
      '2026-08-20T14:00:00',
      'KO',
      null,
      null,
      0.42,
      'completed',
    ),
    txn(
      't05',
      'buy',
      '2026-08-18T13:05:00',
      'SPY',
      0.0310,
      950.0,
      20.10,
      'completed',
    ),
    txn(
      't06',
      'sell',
      '2026-08-12T15:30:00',
      'AAPL',
      0.0420,
      480.0,
      10.15,
      'completed',
    ),
    txn(
      't07',
      'buy',
      '2026-08-05T10:22:00',
      'MSFT',
      0.0428,
      1040.0,
      21.99,
      'completed',
    ),
    txn(
      't08',
      'deposit',
      '2026-08-01T08:40:00',
      null,
      null,
      3000.0,
      null,
      'completed',
    ),
    txn(
      't09',
      'buy',
      '2026-07-28T12:10:00',
      'TSLA',
      0.0684,
      1120.0,
      23.68,
      'completed',
    ),
    txn(
      't10',
      'dividend',
      '2026-07-15T14:00:00',
      'AAPL',
      null,
      null,
      0.07,
      'completed',
    ),
  ];
  write('assets/data/transactions.json', {'as_of': asOf, 'transactions': tx});
}

Map<String, dynamic> txn(
  String id,
  String type,
  String at,
  String? ticker,
  double? fraction,
  double? egp,
  double? usd,
  String status,
) {
  return {
    'id': id,
    'type': type,
    'at': at,
    'ticker': ticker,
    'fraction': fraction,
    'amount_egp': egp,
    'amount_usd': usd,
    'status': status,
  };
}

void write(String path, Object data) {
  final f = File(path)..createSync(recursive: true);
  f.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
  stdout.writeln('wrote $path (${f.lengthSync()} bytes)');
}
