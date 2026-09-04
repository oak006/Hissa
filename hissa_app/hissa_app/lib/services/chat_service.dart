import 'dart:math';

/// Canned advisor. Matches the user's message against keyword sets and returns
/// a scripted answer. No model, no network — the typing delay is theatre so
/// the demo reads like a real assistant.
class ChatService {
  final Random _rnd = Random();

  /// Suggested prompt chips shown on an empty chat.
  static const suggestions = <(String, String)>[
    ('ليه السهم ده طالع النهاردة؟', 'Why is this stock up today?'),
    ('اشرحلي محفظتي', 'Explain my portfolio'),
    ('يعني إيه ETF؟', 'What is an ETF?'),
    ('إيه الفرق بين السهم والكسر؟', 'Share vs fraction?'),
    ('أبدأ بكام؟', 'How much should I start with?'),
    ('إيه هي العمولة؟', 'What are the fees?'),
  ];

  static const _rules = <_Rule>[
    _Rule(
      [
        'طالع',
        'نازل',
        'ليه السهم',
        'سبب',
        'ارتفع',
        'انخفض',
        'why',
        'up today',
        'down today',
      ],
      'حركة السهم في يوم واحد بتكون غالبًا نتيجة أخبار عن الشركة، أو نتائج أرباح، أو مزاج السوق ككل. في العرض التجريبي ده الأسعار لقطة ثابتة، فالحركة اللي بتشوفها توضيحية.\n\nالمهم على المدى الطويل مش حركة اليوم، لكن أداء الشركة عبر سنين.',
      'A single day\'s move usually comes from company news, earnings, or overall market mood. In this demo the prices are a fixed snapshot, so the movement you see is illustrative.\n\nWhat matters long term is the company\'s performance over years, not one day.',
    ),
    _Rule(
      ['محفظتي', 'اشرح', 'استثماراتي', 'portfolio', 'my holdings', 'explain'],
      'محفظتك دلوقتي موزّعة على 6 أوراق: تركيز واضح على التكنولوجيا (إنفيديا، أبل، مايكروسوفت)، مع صندوق مؤشر SPY بيديك تنويع على 500 شركة، وسهم دفاعي زي كوكا كولا.\n\nالنقطة اللي تستاهل انتباهك: التكنولوجيا واخدة نسبة كبيرة، فأي هزة في القطاع ده هتبان بوضوح في محفظتك.',
      'Your portfolio holds six positions: a clear technology tilt (NVIDIA, Apple, Microsoft), an S&P 500 tracker for broad diversification, and a defensive name in Coca-Cola.\n\nWorth noting: technology carries a large share, so a sector-wide move shows up strongly in your total.',
    ),
    _Rule(
      ['etf', 'صندوق', 'صناديق', 'مؤشر', 'index fund'],
      'الـ ETF صندوق بيشتري سلة أسهم بدل سهم واحد. لما تشتري وحدة من SPY، فلوسك بتتوزع على 500 شركة أمريكية دفعة واحدة.\n\nالفايدة: تنويع فوري بمبلغ صغير — لو شركة واحدة اتعثرت، تأثيرها على الصندوق محدود. عشان كده الصناديق نقطة بداية شائعة للمستثمر الجديد.',
      'An ETF buys a basket of stocks instead of one. Buying a unit of SPY spreads your money across 500 US companies at once.\n\nThe benefit is instant diversification with a small amount — one company stumbling has a limited effect. That is why ETFs are a common starting point.',
    ),
    _Rule(
      [
        'الفرق بين السهم والكسر',
        'الكسر',
        'كسور',
        'fraction',
        'fractional',
        'difference',
      ],
      'السهم الكامل هو وحدة الملكية الأساسية — سهم إنفيديا الواحد بحوالي 213 دولار. الكسر هو جزء من السهم ده.\n\nلو معاك 500 جنيه، مش هتقدر تشتري سهم كامل، بس تقدر تشتري حوالي 0.048 من السهم. حقوقك نفس الحقوق بالنسبة والتناسب: نفس نسبة المكسب أو الخسارة، ونفس نصيبك من التوزيعات.',
      'A whole share is the base unit of ownership — one NVIDIA share is about \$213. A fraction is a slice of that share.\n\nWith EGP 500 you cannot buy a whole share, but you can buy roughly 0.048 of one. Your rights scale proportionally: the same percentage gain or loss, and a proportional share of any dividend.',
    ),
    _Rule(
      [
        'أبدأ بكام',
        'ابدأ',
        'مبلغ',
        'أقل مبلغ',
        'start with',
        'minimum',
        'how much',
      ],
      'تقدر تبدأ من 50 جنيه. الأهم من المبلغ هو الانتظام: مبلغ صغير كل شهر بيبني أكتر من مبلغ كبير مرة واحدة وبعدين توقف.\n\nنصيحة عملية: ابدأ بمبلغ لو خسرته مش هيأثر على مصاريفك، واستخدم خاصية الاستثمار التلقائي عشان تشتري كل شهر من غير ما تفكر.',
      'You can start from EGP 50. Consistency matters more than size: a small monthly amount compounds better than one large deposit followed by nothing.\n\nA practical rule: start with an amount you could lose without it affecting your expenses, and use auto-invest so the monthly purchase happens without a decision.',
    ),
    _Rule(
      ['عمولة', 'رسوم', 'تكلفة', 'fee', 'fees', 'commission', 'cost'],
      'عمولة التداول 0.1% من قيمة الأمر، زائد رسم ثابت بسيط على كل عملية.\n\nيعني لو اشتريت بـ 1,000 جنيه: العمولة جنيه واحد، زائد الرسم الثابت. كل ده بيتعرض عليك على شاشة الشراء قبل ما تضغط تأكيد — مفيش أي رسوم مخفية.',
      'Trade commission is 0.1% of the order value, plus a small flat fee per order.\n\nOn a EGP 1,000 order that is EGP 1 of commission plus the flat fee. All of it is shown on the buy screen before you confirm — there are no hidden charges.',
    ),
    _Rule(
      ['دولار', 'سعر الصرف', 'تحويل', 'جنيه', 'fx', 'exchange rate', 'dollar'],
      'الأسهم الأمريكية بتتسعّر بالدولار، فأي شراء بيمر بخطوة تحويل من الجنيه.\n\nإحنا بنثبّتلك سعر الصرف لمدة 60 ثانية قبل التنفيذ، وبيتعرض عليك بوضوح قبل التأكيد. كده بتعرف بالظبط بكام اتحوّلت فلوسك.',
      'US stocks are priced in dollars, so every purchase passes through a conversion from EGP.\n\nWe lock the rate for 60 seconds before execution and show it plainly before you confirm, so you know exactly what your money converted at.',
    ),
    _Rule(
      ['مخاطر', 'خطر', 'تنويع', 'أخسر', 'risk', 'diversif', 'lose'],
      'أي استثمار في الأسهم فيه احتمال خسارة — ده جزء أصيل من اللعبة، ومحدش يقدر يلغيه.\n\nاللي تقدر تتحكم فيه: التنويع (متحطش كل فلوسك في سهم واحد)، والمدى الزمني (كل ما تستثمر لفترة أطول، كل ما تأثير التقلبات قل)، وإنك متستثمرش فلوس محتاجها قريب.',
      'Every stock investment carries the possibility of loss — that is inherent, and nobody removes it.\n\nWhat you control: diversification (not everything in one name), time horizon (longer periods smooth volatility), and not investing money you will need soon.',
    ),
    _Rule(
      ['توزيعات', 'أرباح', 'dividend', 'payout'],
      'التوزيعات هي جزء من أرباح الشركة بتوزّعه على المساهمين. لو عندك كسر من السهم، بتاخد نصيبك من التوزيعة بنفس النسبة.\n\nمثال: لو عندك 0.84 من سهم كوكا كولا، بتاخد 84% من قيمة التوزيعة عن السهم الواحد. بتظهرلك في المحفظة كحركة اسمها "توزيعات أرباح".',
      'A dividend is a share of company profits paid to shareholders. If you own a fraction, you receive a proportional share of it.\n\nExample: owning 0.84 of a Coca-Cola share pays 84% of the per-share dividend. It appears in your wallet as a "Dividend" entry.',
    ),
    _Rule(
      ['أهلا', 'السلام', 'مرحبا', 'ازيك', 'hi', 'hello', 'hey', 'salam'],
      'أهلاً بيك 👋 أنا مستشار حصة. أقدر أشرحلك محفظتك، أو أوضح مصطلح مالي، أو أساعدك تفهم الفرق بين الأسهم والصناديق.\n\nاسألني بالعربي عادي.',
      'Hello 👋 I\'m the Hissa advisor. I can walk you through your portfolio, explain a financial term, or clarify the difference between stocks and funds.\n\nAsk me anything.',
    ),
  ];

  static const _fallbackAr =
      'سؤال كويس. في النسخة التجريبية دي ردودي محدودة على مواضيع معينة: محفظتك، الصناديق، كسور الأسهم، الرسوم، وأسعار الصرف.\n\nجرّب تسألني: "اشرحلي محفظتي" أو "يعني إيه ETF؟"';
  static const _fallbackEn =
      'Good question. In this demo build my answers cover a set of topics: your portfolio, ETFs, fractional shares, fees, and exchange rates.\n\nTry asking: "Explain my portfolio" or "What is an ETF?"';

  String reply(String message, {required bool isAr}) {
    final m = message.toLowerCase().trim();
    for (final rule in _rules) {
      if (rule.keywords.any((k) => m.contains(k.toLowerCase()))) {
        return isAr ? rule.ar : rule.en;
      }
    }
    return isAr ? _fallbackAr : _fallbackEn;
  }

  /// Typing delay scaled loosely to answer length, so long answers take
  /// slightly longer — it reads more naturally than a fixed pause.
  Duration typingDelay(String answer) {
    final base = 700 + (answer.length * 4).clamp(0, 1400);
    return Duration(milliseconds: base + _rnd.nextInt(400));
  }
}

class _Rule {
  final List<String> keywords;
  final String ar;
  final String en;
  const _Rule(this.keywords, this.ar, this.en);
}
