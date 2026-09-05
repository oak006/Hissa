import 'package:flutter/material.dart';

/// Hand-rolled localisation table. Five screens do not need generated ARB
/// plumbing — but it is a real `LocalizationsDelegate`, so `Directionality`,
/// Material widgets and `intl` all resolve from the same locale.
class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);

  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(Locale('ar'));

  static const delegate = _AppStringsDelegate();
  static const supported = [Locale('ar'), Locale('en')];

  bool get isAr => locale.languageCode == 'ar';

  String t(String key) {
    final row = _table[key];
    if (row == null) return key;
    return (isAr ? row.$1 : row.$2);
  }

  /// `t` with `{}` placeholders filled left to right.
  String f(String key, List<Object> args) {
    var out = t(key);
    for (final a in args) {
      out = out.replaceFirst('{}', '$a');
    }
    return out;
  }

  // (arabic, english)
  static const Map<String, (String, String)> _table = {
    // ------------------------------------------------------------- general
    'app_name': ('حصة', 'Hissa'),
    'tagline': ('امتلك حصتك.', 'Own your share.'),
    'continue': ('متابعة', 'Continue'),
    'next': ('التالي', 'Next'),
    'back': ('رجوع', 'Back'),
    'cancel': ('إلغاء', 'Cancel'),
    'confirm': ('تأكيد', 'Confirm'),
    'done': ('تم', 'Done'),
    'skip': ('تخطي', 'Skip'),
    'close': ('إغلاق', 'Close'),
    'search': ('بحث', 'Search'),
    'egp': ('ج.م', 'EGP'),
    'usd': ('دولار', 'USD'),
    'prices_disclaimer': (
      'الأسعار كما في {} · بيانات توضيحية للعرض',
      'Prices as of {} · illustrative demo data',
    ),
    'demo_data': ('بيانات تجريبية', 'Demo data'),

    // ------------------------------------------------------------ nav bar
    'nav_home': ('الرئيسية', 'Home'),
    'nav_wallet': ('المحفظة', 'Wallet'),
    'nav_invest': ('استثمر', 'Invest'),
    'nav_plans': ('الباقات', 'Plans'),
    'nav_settings': ('الإعدادات', 'Settings'),

    // --------------------------------------------------------- onboarding
    'splash_sub': (
      'استثمر في أكبر شركات العالم — بأي مبلغ.',
      'Invest in the world\'s biggest companies — with any amount.',
    ),
    'get_started': ('ابدأ الآن', 'Get started'),
    'phone_title': ('أدخل رقم موبايلك', 'Enter your mobile number'),
    'phone_sub': (
      'هنبعتلك كود تأكيد من 6 أرقام.',
      'We\'ll send you a 6-digit confirmation code.',
    ),
    'phone_label': ('رقم الموبايل', 'Mobile number'),
    'phone_hint': ('10 1234 5678', '10 1234 5678'),
    'phone_short': ('الرقم لازم يكون 10 أرقام', 'Number must be 10 digits'),
    'phone_ok': ('رقم صحيح', 'Valid number'),
    'send_code': ('إرسال الكود', 'Send code'),
    'otp_title': ('اكتب كود التأكيد', 'Enter the confirmation code'),
    'otp_sub': ('بعتنا الكود على {}', 'We sent the code to {}'),
    'otp_resend_in': ('إعادة الإرسال خلال {}', 'Resend in {}'),
    'otp_resend': ('إعادة إرسال الكود', 'Resend code'),
    'otp_resent': ('تم إرسال كود جديد', 'A new code has been sent'),
    'otp_notif_now': ('الآن', 'now'),
    'otp_notif_body': (
      'كود التأكيد بتاعك هو {} — متشاركهوش مع حد.',
      'Your verification code is {} — do not share it with anyone.',
    ),
    'otp_tap_to_fill': ('اضغط للملء التلقائي', 'Tap to autofill'),
    'verify': ('تأكيد', 'Verify'),
    'id_title': ('صوّر بطاقتك الشخصية', 'Scan your national ID'),
    'id_sub': (
      'حط البطاقة جوه الإطار وتأكد إن البيانات واضحة.',
      'Place your ID inside the frame and keep the details readable.',
    ),
    'id_frame_hint': ('الوجه الأمامي للبطاقة', 'Front side of your ID'),
    'id_capture': ('التقاط', 'Capture'),
    'id_scanning': ('جارٍ قراءة البيانات…', 'Reading your details…'),
    'id_verified': ('تم التحقق من البطاقة', 'ID verified'),
    'risk_title': ('عرّفنا على أهدافك', 'Tell us about your goals'),
    'risk_sub': (
      'أربع أسئلة سريعة عشان نظبط اقتراحاتنا ليك.',
      'Four quick questions so we can tailor our suggestions.',
    ),
    'risk_q1': ('إيه هدفك من الاستثمار؟', 'What is your investment goal?'),
    'risk_q1_a': ('أبني ثروة على المدى الطويل', 'Build long-term wealth'),
    'risk_q1_b': ('أحافظ على قيمة فلوسي', 'Protect my money\'s value'),
    'risk_q1_c': ('أحقق دخل إضافي', 'Generate extra income'),
    'risk_q2': ('هتستثمر لمدة قد إيه؟', 'What is your time horizon?'),
    'risk_q2_a': ('أقل من سنة', 'Less than a year'),
    'risk_q2_b': ('من سنة لخمس سنين', 'One to five years'),
    'risk_q2_c': ('أكتر من خمس سنين', 'More than five years'),
    'risk_q3': (
      'لو محفظتك نزلت 20% في شهر، هتعمل إيه؟',
      'If your portfolio dropped 20% in a month, you would:',
    ),
    'risk_q3_a': ('أبيع فورًا', 'Sell immediately'),
    'risk_q3_b': ('أستنى وأشوف', 'Wait and see'),
    'risk_q3_c': ('أشتري أكتر', 'Buy more'),
    'risk_q4': ('عندك خبرة في الاستثمار؟', 'How much investing experience?'),
    'risk_q4_a': ('دي أول مرة', 'This is my first time'),
    'risk_q4_b': ('خبرة بسيطة', 'A little'),
    'risk_q4_c': ('خبرة كويسة', 'Quite a lot'),
    'kyc_done_title': ('تم تفعيل حسابك', 'Your account is live'),
    'kyc_done_sub': (
      'التحقق اكتمل في أقل من 5 دقايق.',
      'Verified in under 5 minutes.',
    ),
    'kyc_step_phone': ('رقم الموبايل', 'Mobile number'),
    'kyc_step_id': ('البطاقة الشخصية', 'National ID'),
    'kyc_step_risk': ('ملف المخاطر', 'Risk profile'),
    'start_investing': ('ابدأ الاستثمار', 'Start investing'),
    'step_of': ('خطوة {} من {}', 'Step {} of {}'),

    // --------------------------------------------------------------- home
    'greeting': ('أهلاً يا {}', 'Hi {}'),
    'portfolio_value': ('قيمة المحفظة', 'Portfolio value'),
    'todays_change': ('تغيّر اليوم', 'Today'),
    'total_return': ('إجمالي الربح', 'Total return'),
    'deposit': ('إيداع', 'Deposit'),
    'invest': ('استثمر', 'Invest'),
    'auto_invest': ('استثمار تلقائي', 'Auto-invest'),
    'holdings': ('استثماراتك', 'Your holdings'),
    'view_all': ('عرض الكل', 'View all'),
    'invested_value': ('قيمة الاستثمارات', 'Invested value'),
    'positions': ('عدد الأوراق', 'Positions'),
    'avg_cost': ('متوسط التكلفة', 'Average cost'),
    'position_return': ('ربح الصفقة', 'Position return'),
    'allocation': ('الوزن', 'Allocation'),
    'no_holdings': ('لسه مفيش استثمارات', 'No holdings yet'),
    'no_holdings_sub': (
      'ابدأ بأي مبلغ من 50 جنيه.',
      'Start with as little as EGP 50.',
    ),
    'browse_stocks': ('تصفح الأسهم', 'Browse stocks'),
    'trial_active': ('التجربة مفعّلة', 'Trial active'),
    'trial_banner': (
      'تجربة {} مفعّلة — كل المميزات متاحة.',
      '{} trial active — all features unlocked.',
    ),
    'ask_advisor': ('اسأل المستشار', 'Ask the advisor'),
    'range_1d': ('يوم', '1D'),
    'range_1w': ('أسبوع', '1W'),
    'range_1m': ('شهر', '1M'),
    'range_1y': ('سنة', '1Y'),
    'auto_invest_soon': (
      'الاستثمار التلقائي هيتفعل قريب في العرض التجريبي.',
      'Auto-invest is coming soon in this demo.',
    ),

    // ------------------------------------------------------------- wallet
    'wallet_title': ('محفظتك', 'Your wallet'),
    'egp_balance': ('الرصيد بالجنيه', 'EGP balance'),
    'usd_balance': ('الرصيد بالدولار', 'USD balance'),
    'available': ('متاح', 'Available'),
    'convert_title': ('تحويل العملة', 'Convert currency'),
    'you_pay': ('بتدفع', 'You pay'),
    'you_get': ('هتاخد', 'You get'),
    'fx_rate': ('سعر الصرف', 'FX rate'),
    'rate_locked': ('السعر مثبّت · {}', 'Rate locked · {}'),
    'rate_expired': ('انتهى تثبيت السعر', 'Rate lock expired'),
    'requote': ('تحديث السعر', 'Refresh rate'),
    'convert_now': ('حوّل دلوقتي', 'Convert now'),
    'converted': ('تم التحويل بنجاح', 'Converted successfully'),
    'recent_activity': ('آخر الحركات', 'Recent activity'),
    'no_activity': ('مفيش حركات لسه', 'No activity yet'),
    'tx_deposit': ('إيداع', 'Deposit'),
    'tx_convert': ('تحويل عملة', 'Conversion'),
    'tx_buy': ('شراء', 'Buy'),
    'tx_sell': ('بيع', 'Sell'),
    'tx_dividend': ('توزيعات أرباح', 'Dividend'),
    'status_completed': ('مكتملة', 'Completed'),
    'status_pending': ('قيد التنفيذ', 'Pending'),
    'deposit_demo': (
      'تم إضافة 1,000 ج.م لرصيدك التجريبي.',
      'EGP 1,000 added to your demo balance.',
    ),

    // ------------------------------------------------------------- invest
    'invest_title': ('استثمر', 'Invest'),
    'search_hint': ('ابحث عن سهم أو شركة', 'Search a stock or company'),
    'cat_all': ('الكل', 'All'),
    'cat_tech': ('تكنولوجيا', 'Technology'),
    'cat_etf': ('صناديق', 'ETFs'),
    'cat_popular': ('الأكثر شعبية', 'Most popular'),
    'cat_movers': ('الأكثر حركة', 'Top movers'),
    'no_results': ('مفيش نتائج', 'No results'),
    'no_results_sub': (
      'جرّب اسم تاني أو رمز السهم.',
      'Try another name or ticker.',
    ),
    'about_company': ('عن الشركة', 'About'),
    'key_stats': ('أرقام أساسية', 'Key stats'),
    'market_cap': ('القيمة السوقية', 'Market cap'),
    'pe_ratio': ('مكرر الربحية', 'P/E ratio'),
    'range_52w': ('نطاق 52 أسبوع', '52-week range'),
    'dividend_yield': ('عائد التوزيعات', 'Dividend yield'),
    'not_available': ('غير متاح', 'N/A'),
    'sector_technology': ('تكنولوجيا', 'Technology'),
    'sector_etf': ('صندوق مؤشر', 'ETF'),
    'sector_consumer': ('سلع استهلاكية', 'Consumer'),
    'sector_financial': ('خدمات مالية', 'Financials'),
    'sector_communication': ('اتصالات وإعلام', 'Communication'),
    'you_own_frac': ('عندك {} من السهم', 'You own {} of a share'),

    // ---------------------------------------------------------------- buy
    'buy': ('شراء', 'Buy'),
    'sell': ('بيع', 'Sell'),
    'buy_title': ('شراء {}', 'Buy {}'),
    'sell_title': ('بيع {}', 'Sell {}'),
    'amount_to_invest': ('المبلغ اللي عايز تستثمره', 'Amount to invest'),
    'amount_to_sell': ('المبلغ اللي عايز تبيعه', 'Amount to sell'),
    'share_price': ('سعر السهم', 'Share price'),
    'fx_applied': ('سعر الصرف المطبّق', 'FX rate applied'),
    'amount_usd': ('المبلغ بالدولار', 'Amount in USD'),
    'you_receive_frac': ('الكسر اللي هتمتلكه', 'The fraction you get'),
    'you_sell_frac': ('الكسر اللي هتبيعه', 'The fraction you sell'),
    'of_one_share': ('من سهم {} واحد', 'of 1 {} share'),
    'commission': ('عمولة التداول (0.1%)', 'Trade commission (0.1%)'),
    'flat_fee': ('رسوم ثابتة', 'Flat fee'),
    'total_debit': ('الإجمالي المخصوم', 'Total charged'),
    'total_credit': ('صافي المتحصل', 'Net proceeds'),
    'order_summary': ('ملخص الأمر', 'Order summary'),
    'confirm_buy': ('أكّد الشراء', 'Confirm purchase'),
    'confirm_sell': ('أكّد البيع', 'Confirm sale'),
    'processing': ('جارٍ تنفيذ الأمر…', 'Placing your order…'),
    'processing_sub': (
      'بنثبّت سعر الصرف وننفّذ الشراء.',
      'Locking your rate and executing the trade.',
    ),
    'bought_title': ('تم الشراء', 'Purchase complete'),
    'sold_title': ('تم البيع', 'Sale complete'),
    'you_now_own': ('دلوقتي عندك', 'You now own'),
    'sold_amount': ('بعت', 'You sold'),
    'back_home': ('رجوع للرئيسية', 'Back to home'),
    'buy_more': ('اشتري كمان', 'Buy more'),
    'min_order': ('أقل مبلغ للأمر هو {}', 'Minimum order is {}'),
    'insufficient': ('رصيدك مش كفاية', 'Insufficient balance'),
    'insufficient_shares': (
      'مبلغ البيع أكبر من اللي عندك',
      'More than you own',
    ),
    'available_to_sell': ('المتاح للبيع', 'Available to sell'),
    'sell_all': ('بيع الكل', 'Sell all'),
    'transparent_note': (
      'شايف السعر والعمولة قبل ما تأكد — من غير أي مفاجآت.',
      'You see the price and the fee before you confirm — no surprises.',
    ),

    // -------------------------------------------------------------- plans
    'plans_title': ('اختار باقتك', 'Choose your plan'),
    'plans_sub': (
      'ادفع مقابل الأدوات، مش مقابل الوصول للسوق.',
      'Pay for the tools, not for access to the market.',
    ),
    'plan_free': ('مجاني', 'Free'),
    'plan_t2': ('الباقة الثانية', 'Tier 2'),
    'plan_t3': ('الباقة الثالثة', 'Tier 3'),
    'most_popular': ('الأكثر اختيارًا', 'Most popular'),
    'per_month': ('/شهر', '/mo'),
    'monthly_price': ('الاشتراك الشهري', 'Monthly price'),
    'f_fractional': (
      'أسهم وصناديق أمريكية بالكسور',
      'Fractional US stocks & ETFs',
    ),
    'f_recurring': ('استثمار تلقائي متكرر', 'Recurring auto-invest'),
    'f_edu_core': ('حصة تعليم — الكورسات الأساسية', 'Hissa Edu — core courses'),
    'f_commission': ('عمولة التداول', 'Trade commission'),
    'f_ai': ('مستشار حصة الذكي — بالعربي', 'Hissa AI Advisor — in Arabic'),
    'f_analytics': (
      'تحليلات متقدمة وتنبيهات أسعار وقوائم متابعة',
      'Advanced analytics, alerts & watchlists',
    ),
    'f_themed': (
      'محافظ موضوعية وأدوات فرز الأسهم',
      'Themed portfolios & screeners',
    ),
    'f_edu_adv': (
      'حصة تعليم — مسارات متقدمة وشهادات',
      'Hissa Edu — advanced tracks & certificates',
    ),
    'f_support': ('خدمة العملاء', 'Customer support'),
    'v_standard': ('عادية', 'Standard'),
    'v_reduced': ('مخفّضة', 'Reduced'),
    'v_lowest': ('الأقل', 'Lowest'),
    'v_priority': ('أولوية', 'Priority'),
    'start_trial': ('ابدأ التجربة', 'Start demo trial'),
    'current_plan': ('باقتك الحالية', 'Your current plan'),
    'trial_started': ('تم تفعيل تجربة {}', '{} trial activated'),
    'trial_ended': ('تم الرجوع للباقة المجانية', 'Back on the Free plan'),
    'end_trial': ('إنهاء التجربة', 'End trial'),
    'plans_caption': (
      'المجاني يفضل مجاني للأبد — الباقات المدفوعة بتسعّر الأدوات، مش الوصول.',
      'Free stays free forever — paid tiers price the tools, not the access.',
    ),
    'plans_note': (
      'أسماء الباقات وأسعارها مبدئية وقابلة للتعديل.',
      'Tier names and pricing to be finalised.',
    ),

    // --------------------------------------------------------------- chat
    'advisor': ('مستشار حصة الذكي', 'Hissa AI Advisor'),
    'advisor_disclaimer': (
      'معلومات تعليمية فقط — مش نصيحة استثمارية.',
      'Educational information only — not investment advice.',
    ),
    'type_message': ('اكتب سؤالك…', 'Type your question…'),
    'send': ('إرسال', 'Send'),
    'typing': ('بيكتب…', 'typing…'),
    'chat_empty': (
      'اسألني أي حاجة عن محفظتك أو السوق.',
      'Ask me anything about your portfolio or the market.',
    ),
    'chat_locked_title': (
      'المستشار الذكي متاح في الباقات المدفوعة',
      'The AI Advisor is a paid feature',
    ),
    'chat_locked_body': (
      'فعّل الباقة الثانية أو الثالثة عشان تسأل المستشار بالعربي وقت ما تحب.',
      'Activate Tier 2 or Tier 3 to ask the advisor in Arabic, any time.',
    ),
    'see_plans': ('شوف الباقات', 'See plans'),
    'clear_chat': ('مسح المحادثة', 'Clear chat'),

    // ----------------------------------------------------------- settings
    'settings_title': ('الإعدادات', 'Settings'),
    'language': ('اللغة', 'Language'),
    'arabic': ('العربية', 'العربية'),
    'english': ('English', 'English'),
    'theme': ('المظهر', 'Theme'),
    'theme_light': ('فاتح', 'Light'),
    'theme_dark': ('داكن', 'Dark'),
    'theme_system': ('النظام', 'System'),
    'profile': ('الحساب', 'Profile'),
    'plan_status': ('حالة الاشتراك', 'Plan status'),
    'demo_section': ('العرض التجريبي', 'Demo'),
    'reset_demo': ('إعادة ضبط العرض', 'Reset demo'),
    'reset_demo_sub': (
      'يرجّع المحفظة والرصيد والمحادثة لحالتها الأصلية.',
      'Restores the portfolio, balances and chat to their initial state.',
    ),
    'reset_confirm': (
      'هترجع كل البيانات التجريبية للبداية. تمام؟',
      'This restores all demo data to its initial state. Continue?',
    ),
    'reset_done': ('تم إعادة ضبط العرض التجريبي', 'Demo reset'),
    'verified_badge': ('موثّق', 'Verified'),
    'demo_user': ('مستخدم تجريبي', 'Demo user'),
    'about_app': ('عن التطبيق', 'About'),
    'about_body': (
      'حصة — نسخة تجريبية للعرض. كل البيانات ثابتة ومحلية، ومفيش أي اتصال بالإنترنت.',
      'Hissa — pitch demo build. All data is static and local; the app makes no network calls.',
    ),
  };
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppStrings.supported.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

/// `context.s.t('key')` reads better than the full lookup at every call site.
extension StringsX on BuildContext {
  AppStrings get s => AppStrings.of(this);
}
