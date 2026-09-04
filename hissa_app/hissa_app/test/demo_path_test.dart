import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hissa_app/app/constants.dart';
import 'package:hissa_app/app/strings.dart';
import 'package:hissa_app/app/theme.dart';
import 'package:hissa_app/providers/app_provider.dart';
import 'package:hissa_app/providers/chat_provider.dart';
import 'package:hissa_app/providers/market_provider.dart';
import 'package:hissa_app/providers/portfolio_provider.dart';
import 'package:hissa_app/providers/subscription_provider.dart';
import 'package:hissa_app/screens/buy/processing_overlay.dart';
import 'package:hissa_app/screens/buy/trade_screen.dart';
import 'package:hissa_app/screens/buy/trade_success_screen.dart';
import 'package:hissa_app/screens/home/home_screen.dart';
import 'package:hissa_app/screens/invest/stock_detail_screen.dart';
import 'package:provider/provider.dart';

/// Walks the pitch path the presenter will actually run on stage:
/// stock detail -> buy a fraction -> processing -> success -> home.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MarketProvider market;
  late PortfolioProvider portfolio;

  Future<void> pumpApp(WidgetTester tester, String initial) async {
    // A phone-shaped surface: these screens are laid out for one, and the
    // 800x600 default hides content below the fold.
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    market = MarketProvider();
    await tester.runAsync(() => market.load());
    market.ticker.stop();
    portfolio = PortfolioProvider()..attach(market);

    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(
          path: '/stock/:ticker',
          builder: (_, s) =>
              StockDetailScreen(ticker: s.pathParameters['ticker']!),
        ),
        GoRoute(
          path: '/trade/:ticker',
          builder: (_, s) => TradeScreen(
            ticker: s.pathParameters['ticker']!,
            isBuy: s.uri.queryParameters['mode'] != 'sell',
          ),
        ),
        GoRoute(
          path: '/trade-done',
          builder: (_, s) => TradeSuccessScreen(quote: s.extra! as TradeQuote),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider.value(value: market),
          ChangeNotifierProvider.value(value: portfolio),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('ar'),
          supportedLocales: AppStrings.supported,
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('stock detail leads into the buy screen', (tester) async {
    await pumpApp(tester, '/stock/NVDA');

    expect(find.text('إنفيديا'), findsOneWidget);
    expect(find.text('أرقام أساسية'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('عن الشركة'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('عن الشركة'), findsOneWidget);
    // The demo user already holds NVDA, so both actions are offered.
    expect(find.text('شراء'), findsOneWidget);
    expect(find.text('بيع'), findsOneWidget);

    await tester.tap(find.text('شراء'));
    await tester.pumpAndSettle();

    expect(find.byType(TradeScreen), findsOneWidget);
    expect(find.text('المبلغ اللي عايز تستثمره'), findsOneWidget);
  });

  testWidgets('a quick-select chip fills the amount and prices the order', (
    tester,
  ) async {
    await pumpApp(tester, '/trade/NVDA?mode=buy');

    await tester.tap(find.text('1,000 ج.م'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final price = portfolio.priceOf('NVDA');
    final expected = ((1000 / K.fxEgpPerUsd) / price).toStringAsFixed(4);
    expect(find.text(expected), findsOneWidget);
    expect(find.text('1,006.00 ج.م'), findsNWidgets(2));
  });

  testWidgets('confirming runs the processing state, then the success screen', (
    tester,
  ) async {
    await pumpApp(tester, '/trade/NVDA?mode=buy');

    final cashBefore = portfolio.cashEgp;
    final ownedBefore = portfolio.fractionOf('NVDA');

    await tester.enterText(find.byType(TextField), '1000');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('أكّد الشراء'));
    await tester.pump();

    // Two seconds of blocking processing theatre.
    expect(find.byType(ProcessingOverlay), findsOneWidget);
    expect(find.text('جارٍ تنفيذ الأمر…'), findsOneWidget);

    await tester.pump(K.processingDelay);
    await tester.pumpAndSettle();

    expect(find.byType(TradeSuccessScreen), findsOneWidget);
    expect(find.text('تم الشراء'), findsOneWidget);
    expect(find.text('دلوقتي عندك'), findsOneWidget);

    // The trade actually settled into the portfolio.
    final owned = portfolio.fractionOf('NVDA');
    expect(owned, greaterThan(ownedBefore));
    expect(portfolio.cashEgp, closeTo(cashBefore - 1006.0, 1e-6));
    // The success screen states the new total holding, not just the slice.
    expect(find.text(owned.toStringAsFixed(4)), findsOneWidget);

    await tester.tap(find.text('رجوع للرئيسية'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the sell variant offers "sell all" and settles a sale', (
    tester,
  ) async {
    await pumpApp(tester, '/trade/KO?mode=sell');

    final cashBefore = portfolio.cashEgp;
    expect(find.text('بيع الكل'), findsOneWidget);

    await tester.tap(find.text('بيع الكل'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('أكّد البيع'));
    await tester.pump();
    await tester.pump(K.processingDelay);
    await tester.pumpAndSettle();

    expect(find.text('تم البيع'), findsOneWidget);
    expect(portfolio.fractionOf('KO'), lessThan(0.0001));
    expect(portfolio.cashEgp, greaterThan(cashBefore));
  });

  testWidgets('home shows the portfolio in EGP and toggles to USD', (
    tester,
  ) async {
    await pumpApp(tester, '/home');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('استثماراتك'), findsWidgets);
    expect(find.text('قيمة المحفظة'), findsOneWidget);
    // Both currencies are on screen at once — one headline, one secondary.
    expect(find.textContaining('ج.م'), findsWidgets);
    expect(find.textContaining('\$'), findsWidgets);

    await tester.tap(find.text('USD'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('≈'), findsOneWidget);
  });
}
