import 'package:flutter/foundation.dart';

import '../app/constants.dart';
import '../models/holding.dart';
import '../models/stock.dart';
import '../models/transaction.dart';
import 'market_provider.dart';

/// The result of pricing an order. Everything the buy screen displays comes
/// from one of these — computed on every keystroke, so what the user reads is
/// exactly what gets executed.
class TradeQuote {
  final bool isBuy;
  final String ticker;

  /// What the user typed: the order value, in EGP.
  final double amountEgp;
  final double fx;
  final double amountUsd;
  final double sharePriceUsd;
  final double fraction;
  final double commissionEgp;
  final double flatFeeEgp;

  /// Buy: total debited from the wallet. Sell: net proceeds credited.
  final double totalEgp;

  /// Null when the order is placeable; otherwise a strings.dart key.
  final String? errorKey;
  final List<Object> errorArgs;

  const TradeQuote({
    required this.isBuy,
    required this.ticker,
    required this.amountEgp,
    required this.fx,
    required this.amountUsd,
    required this.sharePriceUsd,
    required this.fraction,
    required this.commissionEgp,
    required this.flatFeeEgp,
    required this.totalEgp,
    this.errorKey,
    this.errorArgs = const [],
  });

  double get feesEgp => commissionEgp + flatFeeEgp;
  bool get hasAmount => amountEgp > 0;
  bool get valid => hasAmount && errorKey == null;
}

/// Holdings, balances, transactions — and the trade engine that mutates them.
class PortfolioProvider extends ChangeNotifier {
  MarketProvider? _market;
  bool _hydrated = false;

  List<Holding> _holdings = [];
  List<Txn> _transactions = [];
  double _cashEgp = 0;
  double _cashUsd = 0;

  // Kept so "Reset demo" restores the exact opening state.
  List<Holding> _initialHoldings = const [];
  List<Txn> _initialTransactions = const [];
  double _initialCashEgp = 0;
  double _initialCashUsd = 0;

  bool get ready => _hydrated;
  List<Holding> get holdings =>
      _holdings.where((h) => h.fraction > 0.00005).toList();
  List<Txn> get transactions => List.unmodifiable(_transactions);
  double get cashEgp => _cashEgp;
  double get cashUsd => _cashUsd;

  /// Wired up by `ChangeNotifierProxyProvider` — hydrates once the static
  /// snapshot has finished loading.
  void attach(MarketProvider market) {
    _market = market;
    if (!_hydrated && market.ready) {
      final d = market.data!;
      _initialHoldings = List.of(d.holdings);
      _initialTransactions = List.of(d.transactions);
      _initialCashEgp = d.cashEgp;
      _initialCashUsd = d.cashUsd;
      _holdings = List.of(d.holdings);
      _transactions = List.of(d.transactions);
      _cashEgp = d.cashEgp;
      _cashUsd = d.cashUsd;
      _hydrated = true;
    }
  }

  // ------------------------------------------------------------ valuation

  double priceOf(String ticker) => _market?.priceOf(ticker) ?? 0;

  Holding? holdingOf(String ticker) {
    for (final h in _holdings) {
      if (h.ticker == ticker) return h;
    }
    return null;
  }

  double fractionOf(String ticker) => holdingOf(ticker)?.fraction ?? 0;

  /// Market value of the holdings only, in USD.
  double get investedUsd {
    var sum = 0.0;
    for (final h in _holdings) {
      sum += h.valueUsd(priceOf(h.ticker));
    }
    return sum;
  }

  /// Holdings plus idle cash — the headline number on Home.
  double get totalValueUsd => investedUsd + _cashUsd + _cashEgp / K.fxEgpPerUsd;
  double get totalValueEgp => totalValueUsd * K.fxEgpPerUsd;

  double get costBasisUsd {
    var sum = 0.0;
    for (final h in _holdings) {
      sum += h.costUsd();
    }
    return sum;
  }

  double get totalReturnUsd => investedUsd - costBasisUsd;
  double get totalReturnPct =>
      costBasisUsd == 0 ? 0 : totalReturnUsd / costBasisUsd * 100;

  /// Today's move on the holdings, derived from each stock's day change.
  double get dayChangeUsd {
    var sum = 0.0;
    for (final h in _holdings) {
      final price = priceOf(h.ticker);
      final pct = _market?.dayChangePctOf(h.ticker) ?? 0;
      final prevClose = price / (1 + pct / 100);
      sum += h.fraction * (price - prevClose);
    }
    return sum;
  }

  double get dayChangePct {
    final invested = investedUsd;
    if (invested == 0) return 0;
    final prev = invested - dayChangeUsd;
    if (prev == 0) return 0;
    return dayChangeUsd / prev * 100;
  }

  /// Portfolio value series for the Home chart: today's fractions valued at
  /// each historical close, so the curve is derived from real data rather
  /// than invented.
  List<double> valueSeries(ChartRange range) {
    final market = _market;
    if (market == null || !market.ready) return const [];
    final cash = _cashUsd + _cashEgp / K.fxEgpPerUsd;

    var length = 0;
    for (final h in _holdings) {
      final s = market.byTicker(h.ticker);
      if (s != null) length = length == 0 ? s.history.length : length;
    }
    if (length == 0) return const [];

    final full = List<double>.generate(length, (i) {
      var sum = 0.0;
      for (final h in _holdings) {
        final s = market.byTicker(h.ticker);
        if (s == null || i >= s.history.length) continue;
        sum += h.fraction * s.history[i];
      }
      return sum + cash;
    });

    final take = range.points.clamp(2, full.length);
    return full.sublist(full.length - take);
  }

  // ---------------------------------------------------------------- quotes

  /// Prices an order. Pure — safe to call on every keystroke.
  TradeQuote quote({
    required String ticker,
    required double amountEgp,
    required bool isBuy,
  }) {
    const fx = K.fxEgpPerUsd;
    final price = priceOf(ticker);
    final amountUsd = amountEgp / fx;
    final fraction = price == 0 ? 0.0 : amountUsd / price;
    final commission = amountEgp * K.commissionRate;
    final flat = amountEgp > 0 ? K.flatFeeEgp : 0.0;
    final total = isBuy
        ? amountEgp + commission + flat
        : amountEgp - commission - flat;

    String? errorKey;
    List<Object> args = const [];

    // A one-piastre tolerance. The UI rounds displayed amounts to two
    // decimals, so an exact "all of it" order must not fail its own check.
    const epsilon = 0.01;

    if (amountEgp > 0 && amountEgp < K.minOrderEgp) {
      errorKey = 'min_order';
      args = [K.minOrderEgp];
    } else if (isBuy && total > _cashEgp + epsilon) {
      errorKey = 'insufficient';
    } else if (!isBuy) {
      final ownedEgp = fractionOf(ticker) * price * fx;
      if (amountEgp > ownedEgp + epsilon) errorKey = 'insufficient_shares';
    }

    return TradeQuote(
      isBuy: isBuy,
      ticker: ticker,
      amountEgp: amountEgp,
      fx: fx,
      amountUsd: amountUsd,
      sharePriceUsd: price,
      fraction: fraction,
      commissionEgp: commission,
      flatFeeEgp: flat,
      totalEgp: total,
      errorKey: errorKey,
      errorArgs: args,
    );
  }

  /// Max EGP realisable from a position — powers "Sell all".
  ///
  /// Floored to two decimals rather than rounded: rounding up would produce an
  /// amount fractionally larger than the holding, and "Sell all" would fail
  /// its own validation.
  double sellableEgp(String ticker) {
    final raw = fractionOf(ticker) * priceOf(ticker) * K.fxEgpPerUsd;
    return (raw * 100).floorToDouble() / 100;
  }

  // -------------------------------------------------------------- mutation

  void execute(TradeQuote q) {
    if (!q.valid) return;
    if (q.isBuy) {
      _cashEgp -= q.totalEgp;
      final existing = holdingOf(q.ticker);
      if (existing == null) {
        _holdings.add(
          Holding(
            ticker: q.ticker,
            fraction: q.fraction,
            avgCostUsd: q.sharePriceUsd,
          ),
        );
      } else {
        _holdings[_holdings.indexOf(existing)] = existing.addBuy(
          q.fraction,
          q.sharePriceUsd,
        );
      }
    } else {
      _cashEgp += q.totalEgp;
      final existing = holdingOf(q.ticker);
      if (existing != null) {
        _holdings[_holdings.indexOf(existing)] = existing.removeSell(
          q.fraction,
        );
      }
    }

    _transactions.insert(
      0,
      Txn(
        id: 'x${DateTime.now().microsecondsSinceEpoch}',
        type: q.isBuy ? TxType.buy : TxType.sell,
        at: DateTime.now(),
        ticker: q.ticker,
        fraction: q.fraction,
        amountEgp: q.totalEgp,
        amountUsd: q.amountUsd,
      ),
    );
    notifyListeners();
  }

  void deposit(double egp) {
    _cashEgp += egp;
    _transactions.insert(
      0,
      Txn(
        id: 'd${DateTime.now().microsecondsSinceEpoch}',
        type: TxType.deposit,
        at: DateTime.now(),
        amountEgp: egp,
      ),
    );
    notifyListeners();
  }

  /// EGP -> USD at the locked rate. Returns false if the balance is short.
  bool convert(double egp) {
    if (egp <= 0 || egp > _cashEgp + 0.001) return false;
    final usd = egp / K.fxEgpPerUsd;
    _cashEgp -= egp;
    _cashUsd += usd;
    _transactions.insert(
      0,
      Txn(
        id: 'c${DateTime.now().microsecondsSinceEpoch}',
        type: TxType.convert,
        at: DateTime.now(),
        amountEgp: egp,
        amountUsd: usd,
      ),
    );
    notifyListeners();
    return true;
  }

  void reset() {
    _holdings = List.of(_initialHoldings);
    _transactions = List.of(_initialTransactions);
    _cashEgp = _initialCashEgp;
    _cashUsd = _initialCashUsd;
    notifyListeners();
  }
}
