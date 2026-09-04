import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hissa_app/app/strings.dart';
import 'package:hissa_app/app/theme.dart';
import 'package:hissa_app/models/plan.dart';
import 'package:hissa_app/providers/app_provider.dart';
import 'package:hissa_app/providers/chat_provider.dart';
import 'package:hissa_app/providers/market_provider.dart';
import 'package:hissa_app/providers/portfolio_provider.dart';
import 'package:hissa_app/providers/subscription_provider.dart';
import 'package:hissa_app/screens/buy/trade_screen.dart';
import 'package:hissa_app/screens/chat/chat_screen.dart';
import 'package:hissa_app/screens/onboarding/otp_screen.dart';
import 'package:hissa_app/widgets/common.dart';
import 'package:hissa_app/widgets/fake_notification.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hissa_app/services/chat_service.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MarketProvider market;
  late PortfolioProvider portfolio;
  late SubscriptionProvider subscription;
  late AppProvider app;
  late ChatProvider chat;

  /// Asset loading is real I/O, so it has to run outside the widget test's
  /// fake-async zone or the await never completes.
  Future<void> boot(WidgetTester tester) async {
    market = MarketProvider();
    await tester.runAsync(() => market.load());
    market.ticker.stop(); // deterministic prices for assertions
    portfolio = PortfolioProvider()..attach(market);
    subscription = SubscriptionProvider();
    app = AppProvider();
    chat = ChatProvider();
  }

  /// The app now opens in English; these tests assert the Arabic copy, so
  /// they switch first. Arabic remains the fully-supported second locale.
  void useArabic() => app.setLocale(const Locale('ar'));

  /// Wraps a screen in the same providers and localisation the real app uses.
  Widget host(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: app),
        ChangeNotifierProvider.value(value: market),
        ChangeNotifierProvider.value(value: portfolio),
        ChangeNotifierProvider.value(value: subscription),
        ChangeNotifierProvider.value(value: chat),
      ],
      child: Consumer<AppProvider>(
        builder: (context, a, _) => MaterialApp(
          locale: a.locale,
          supportedLocales: AppStrings.supported,
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: a.themeMode,
          home: child,
        ),
      ),
    );
  }

  group('buy screen', () {
    testWidgets('shows the fraction, the fees and the total as you type', (
      tester,
    ) async {
      await boot(tester);
      useArabic();
      await tester.pumpWidget(
        host(const TradeScreen(ticker: 'NVDA', isBuy: true)),
      );
      await tester.pump();

      // Nothing entered yet: the confirm button is disabled.
      final confirm = find.widgetWithText(FilledButton, 'أكّد الشراء');
      expect(confirm, findsOneWidget);
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(find.byType(TextField), '1000');
      // Two frames: one to run the fraction AnimatedSwitcher to completion,
      // one for it to drop the outgoing child. Otherwise the old and new
      // values are both mounted.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final price = portfolio.priceOf('NVDA');
      final fraction = (1000 / 48.65) / price;

      expect(find.text(fraction.toStringAsFixed(4)), findsOneWidget);
      expect(find.text('من سهم NVDA واحد'), findsOneWidget);
      expect(find.text('1 USD = 48.65'), findsOneWidget);
      // Commission 1.00, flat fee 5.00, total 1,006.00 — shown in the card
      // and restated in the sticky footer.
      expect(find.text('1.00 ج.م'), findsOneWidget);
      expect(find.text('5.00 ج.م'), findsOneWidget);
      expect(find.text('1,006.00 ج.م'), findsNWidgets(2));

      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    });

    testWidgets('blocks and explains an order over the balance', (
      tester,
    ) async {
      await boot(tester);
      useArabic();
      await tester.pumpWidget(
        host(const TradeScreen(ticker: 'NVDA', isBuy: true)),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '999999');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('رصيدك مش كفاية'), findsOneWidget);
      final confirm = find.widgetWithText(FilledButton, 'أكّد الشراء');
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    });

    testWidgets('the sell variant nets fees off instead of adding them', (
      tester,
    ) async {
      await boot(tester);
      useArabic();
      await tester.pumpWidget(
        host(const TradeScreen(ticker: 'NVDA', isBuy: false)),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), '1000');
      // Two frames: one to run the fraction AnimatedSwitcher to completion,
      // one for it to drop the outgoing child. Otherwise the old and new
      // values are both mounted.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('أكّد البيع'), findsOneWidget);
      expect(find.text('994.00 ج.م'), findsNWidgets(2));
    });
  });

  group('localisation', () {
    testWidgets('opens in English LTR and flips cleanly to Arabic RTL', (
      tester,
    ) async {
      await boot(tester);
      await tester.pumpWidget(
        host(const TradeScreen(ticker: 'NVDA', isBuy: true)),
      );
      await tester.pump();

      expect(app.isAr, isFalse);
      expect(
        Directionality.of(tester.element(find.byType(TradeScreen))),
        TextDirection.ltr,
      );
      expect(find.text('Amount to invest'), findsOneWidget);

      app.toggleLocale();
      await tester.pumpAndSettle();

      expect(
        Directionality.of(tester.element(find.byType(TradeScreen))),
        TextDirection.rtl,
      );
      expect(find.text('المبلغ اللي عايز تستثمره'), findsOneWidget);
    });

    test('the demo opens in English, dark, as Nour', () {
      final a = AppProvider();
      expect(a.locale, const Locale('en'));
      expect(a.themeMode, ThemeMode.dark);
      expect(a.user.name(false), 'Nour');
      expect(a.user.name(true), 'نور');
    });

    test('every string key resolves in both languages', () {
      const ar = AppStrings(Locale('ar'));
      const en = AppStrings(Locale('en'));
      for (final key in [
        'app_name',
        'tagline',
        'buy',
        'sell',
        'nav_home',
        'plans_title',
        'advisor',
        'chat_locked_title',
        'reset_demo',
        'of_one_share',
        'commission',
        'total_debit',
        'rate_locked',
        'trial_banner',
      ]) {
        expect(ar.t(key), isNot(key), reason: 'missing ar: $key');
        expect(en.t(key), isNot(key), reason: 'missing en: $key');
      }
    });

    test('placeholders are filled left to right', () {
      const ar = AppStrings(Locale('ar'));
      expect(ar.f('of_one_share', ['NVDA']), 'من سهم NVDA واحد');
      expect(ar.f('step_of', [2, 3]), 'خطوة 2 من 3');
    });
  });

  group('advisor paywall', () {
    testWidgets('is locked on Free and unlocked by a demo trial', (
      tester,
    ) async {
      await boot(tester);
      useArabic();
      await tester.pumpWidget(host(const ChatScreen()));
      await tester.pump();

      expect(find.text('شوف الباقات'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      subscription.startTrial(PlanTier.tier2);
      await tester.pumpAndSettle();

      expect(find.text('شوف الباقات'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    test('trial flips entitlement in memory and reset clears it', () {
      final sub = SubscriptionProvider();
      expect(sub.canUseAdvisor, isFalse);
      expect(sub.canUseScreeners, isFalse);

      sub.startTrial(PlanTier.tier2);
      expect(sub.canUseAdvisor, isTrue);
      expect(sub.canUseScreeners, isFalse, reason: 'screeners are Tier 3');
      expect(sub.onTrial, isTrue);

      sub.startTrial(PlanTier.tier3);
      expect(sub.canUseScreeners, isTrue);

      sub.reset();
      expect(sub.tier, PlanTier.free);
      expect(sub.canUseAdvisor, isFalse);
    });
  });

  group('chat service', () {
    final service = ChatService();

    test('matches keywords in Arabic and English', () {
      expect(service.reply('يعني إيه ETF؟', isAr: true), contains('سلة أسهم'));
      expect(service.reply('اشرحلي محفظتي', isAr: true), contains('محفظتك'));
      expect(
        service.reply('What is an ETF?', isAr: false),
        contains('basket of stocks'),
      );
    });

    test('falls back politely on an unmatched message', () {
      final reply = service.reply('qwertyuiop', isAr: true);
      expect(reply, contains('ردودي محدودة'));
    });

    test(
      'every suggested prompt matches a scripted answer, not the fallback',
      () {
        for (final (ar, en) in ChatService.suggestions) {
          expect(
            service.reply(ar, isAr: true),
            isNot(contains('ردودي محدودة')),
            reason: 'unmatched suggestion: $ar',
          );
          expect(
            service.reply(en, isAr: false),
            isNot(contains('my answers cover')),
            reason: 'unmatched suggestion: $en',
          );
        }
      },
    );
  });

  group('plans', () {
    test('the comparison table gates the AI advisor on the paid tiers', () {
      final ai = PlanFeature.rows.firstWhere((r) => r.labelKey == 'f_ai');
      expect(ai.cell(PlanTier.free).included, isFalse);
      expect(ai.cell(PlanTier.tier2).included, isTrue);
      expect(ai.cell(PlanTier.tier3).included, isTrue);
    });

    test('pricing comes from the constants file', () {
      expect(Plan.of(PlanTier.free).priceEgp, 0);
      expect(Plan.of(PlanTier.tier2).priceEgp, 150);
      expect(Plan.of(PlanTier.tier3).priceEgp, 250);
      expect(Plan.of(PlanTier.tier3).mostPopular, isTrue);
    });
  });

  group('otp', () {
    testWidgets('a mock notification delivers the code and autofills it', (
      tester,
    ) async {
      await boot(tester);
      await tester.pumpWidget(host(const OtpScreen()));
      await tester.pump();

      // Built, but fully transparent and off-screen — it slides in a beat
      // after the screen settles.
      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(FakeNotification),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, 0.0);

      final verify = find.widgetWithText(FilledButton, 'Verify');
      expect(tester.widget<FilledButton>(verify).onPressed, isNull);

      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 500));

      expect(fade.opacity.value, 1.0, reason: 'banner has slid in');
      final banner = find.textContaining('verification code');
      expect(banner, findsOneWidget);
      expect(find.text('Tap to autofill'), findsOneWidget);

      // The code in the banner is the code that gets filled in.
      final text = tester.widget<Text>(banner).data!;
      final code = RegExp(r'\d{6}').firstMatch(text)!.group(0)!;

      await tester.tap(banner);
      await tester.pump(const Duration(milliseconds: 400));

      for (final digit in code.split('')) {
        expect(find.text(digit), findsWidgets);
      }
      expect(tester.widget<FilledButton>(verify).onPressed, isNotNull);
    });

    testWidgets('the banner renders in Arabic RTL too', (tester) async {
      await boot(tester);
      useArabic();
      await tester.pumpWidget(host(const OtpScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        Directionality.of(tester.element(find.byType(OtpScreen))),
        TextDirection.rtl,
      );
      expect(find.textContaining('كود التأكيد بتاعك'), findsOneWidget);
      expect(find.text('اضغط للملء التلقائي'), findsOneWidget);
    });

    testWidgets('any six digits are accepted', (tester) async {
      await boot(tester);
      await tester.pumpWidget(host(const OtpScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();

      final verify = find.widgetWithText(FilledButton, 'Verify');
      expect(tester.widget<FilledButton>(verify).onPressed, isNotNull);
    });
  });

  group('brand logos', () {
    testWidgets(
      'draws a real mark where one is bundled, the ticker where not',
      (tester) async {
        await boot(tester);
        await tester.pumpWidget(
          host(
            const Column(
              children: [
                TickerLogo(ticker: 'NVDA'),
                TickerLogo(ticker: 'SPY'),
              ],
            ),
          ),
        );
        await tester.pump();

        // NVIDIA has a bundled SVG; SPY is a fund and falls back to its ticker.
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.text('SPY'), findsOneWidget);
        expect(find.text('NVDA'), findsNothing);
      },
    );
  });
}
