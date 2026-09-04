import 'package:flutter_test/flutter_test.dart';
import 'package:hissa_app/app/constants.dart';
import 'package:hissa_app/models/stock.dart';
import 'package:hissa_app/providers/market_provider.dart';
import 'package:hissa_app/providers/portfolio_provider.dart';

/// The buy screen is the pitch. These lock down the numbers it displays.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MarketProvider market;
  late PortfolioProvider portfolio;

  setUp(() async {
    market = MarketProvider();
    await market.load();
    // The simulated tick would make every assertion below flaky.
    market.ticker.stop();
    portfolio = PortfolioProvider()..attach(market);
  });

  tearDown(() => market.dispose());

  test('loads the static snapshot', () {
    expect(market.stocks.length, 20);
    expect(market.asOf, isNotEmpty);
    expect(portfolio.holdings.length, 6);
    for (final s in market.stocks) {
      expect(s.history.length, 90, reason: '${s.ticker} history');
      expect(s.history.last, s.snapshotPrice, reason: '${s.ticker} close');
    }
  });

  test('quote breaks a buy down exactly as the screen shows it', () {
    final q = portfolio.quote(ticker: 'NVDA', amountEgp: 1000, isBuy: true);
    final price = portfolio.priceOf('NVDA');

    expect(q.fx, K.fxEgpPerUsd);
    expect(q.amountUsd, closeTo(1000 / K.fxEgpPerUsd, 1e-9));
    expect(q.fraction, closeTo(1000 / K.fxEgpPerUsd / price, 1e-9));
    expect(q.commissionEgp, closeTo(1.0, 1e-9)); // 0.1% of 1,000
    expect(q.flatFeeEgp, K.flatFeeEgp);
    expect(q.totalEgp, closeTo(1006.0, 1e-9)); // 1000 + 1 + 5
    expect(q.valid, isTrue);
  });

  test('a sell nets the fees off the proceeds instead of adding them', () {
    final q = portfolio.quote(ticker: 'NVDA', amountEgp: 1000, isBuy: false);
    expect(q.totalEgp, closeTo(994.0, 1e-9)); // 1000 - 1 - 5
  });

  test('rejects an order below the minimum', () {
    final q = portfolio.quote(ticker: 'AAPL', amountEgp: 10, isBuy: true);
    expect(q.errorKey, 'min_order');
    expect(q.valid, isFalse);
  });

  test('rejects a buy larger than the cash balance', () {
    final q = portfolio.quote(
      ticker: 'AAPL',
      amountEgp: portfolio.cashEgp + 1000,
      isBuy: true,
    );
    expect(q.errorKey, 'insufficient');
    expect(q.valid, isFalse);
  });

  test('rejects selling more than is owned', () {
    final owned = portfolio.sellableEgp('KO');
    final q = portfolio.quote(
      ticker: 'KO',
      amountEgp: owned + 500,
      isBuy: false,
    );
    expect(q.errorKey, 'insufficient_shares');
  });

  test('zero is not an error, it is just an empty form', () {
    final q = portfolio.quote(ticker: 'NVDA', amountEgp: 0, isBuy: true);
    expect(q.errorKey, isNull);
    expect(q.valid, isFalse, reason: 'nothing to confirm yet');
  });

  test('executing a buy adds the fraction and debits the total', () {
    final cashBefore = portfolio.cashEgp;
    final ownedBefore = portfolio.fractionOf('NVDA');

    final q = portfolio.quote(ticker: 'NVDA', amountEgp: 1000, isBuy: true);
    portfolio.execute(q);

    expect(
      portfolio.fractionOf('NVDA'),
      closeTo(ownedBefore + q.fraction, 1e-9),
    );
    expect(portfolio.cashEgp, closeTo(cashBefore - q.totalEgp, 1e-9));
    expect(portfolio.transactions.first.ticker, 'NVDA');
  });

  test('buying a stock not yet held opens a new position', () {
    expect(portfolio.fractionOf('QQQ'), 0);
    final q = portfolio.quote(ticker: 'QQQ', amountEgp: 500, isBuy: true);
    portfolio.execute(q);
    expect(portfolio.fractionOf('QQQ'), closeTo(q.fraction, 1e-9));
    expect(portfolio.holdings.length, 7);
  });

  test('executing a sell removes the fraction and credits the proceeds', () {
    final cashBefore = portfolio.cashEgp;
    final ownedBefore = portfolio.fractionOf('KO');

    final q = portfolio.quote(ticker: 'KO', amountEgp: 200, isBuy: false);
    portfolio.execute(q);

    expect(portfolio.fractionOf('KO'), closeTo(ownedBefore - q.fraction, 1e-9));
    expect(portfolio.cashEgp, closeTo(cashBefore + q.totalEgp, 1e-9));
  });

  test('selling everything closes the position out of the list', () {
    final all = portfolio.sellableEgp('KO');
    final q = portfolio.quote(ticker: 'KO', amountEgp: all, isBuy: false);
    expect(q.valid, isTrue, reason: '"sell all" must not trip its own check');
    portfolio.execute(q);
    expect(portfolio.holdings.any((h) => h.ticker == 'KO'), isFalse);
  });

  test('an invalid quote cannot be executed', () {
    final cashBefore = portfolio.cashEgp;
    final q = portfolio.quote(ticker: 'NVDA', amountEgp: 5, isBuy: true);
    portfolio.execute(q);
    expect(portfolio.cashEgp, cashBefore);
  });

  test('deposit and convert move money the right way', () {
    final egp = portfolio.cashEgp;
    final usd = portfolio.cashUsd;

    portfolio.deposit(1000);
    expect(portfolio.cashEgp, closeTo(egp + 1000, 1e-9));

    expect(portfolio.convert(486.50), isTrue);
    expect(portfolio.cashEgp, closeTo(egp + 1000 - 486.50, 1e-9));
    expect(portfolio.cashUsd, closeTo(usd + 486.50 / K.fxEgpPerUsd, 1e-9));

    expect(portfolio.convert(999999), isFalse, reason: 'over balance');
  });

  test('reset restores the opening demo state', () {
    final cash = portfolio.cashEgp;
    final holdings = portfolio.holdings.length;
    final txns = portfolio.transactions.length;

    portfolio.execute(
      portfolio.quote(ticker: 'NVDA', amountEgp: 2000, isBuy: true),
    );
    portfolio.deposit(5000);
    expect(portfolio.cashEgp, isNot(closeTo(cash, 1e-9)));

    portfolio.reset();

    expect(portfolio.cashEgp, closeTo(cash, 1e-9));
    expect(portfolio.holdings.length, holdings);
    expect(portfolio.transactions.length, txns);
  });

  test('the demo portfolio shows a modest, believable gain', () {
    expect(portfolio.totalReturnPct, greaterThan(0));
    expect(
      portfolio.totalReturnPct,
      lessThan(30),
      reason: 'successful but not implausible',
    );
  });

  test('the home chart series returns one point per range step', () {
    expect(portfolio.valueSeries(ChartRange.m1).length, ChartRange.m1.points);
    expect(portfolio.valueSeries(ChartRange.y1).length, ChartRange.y1.points);
    expect(portfolio.valueSeries(ChartRange.d1).length, ChartRange.d1.points);
  });
}
