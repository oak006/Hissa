import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/holding.dart';
import '../models/stock.dart';
import '../models/transaction.dart';

class MockData {
  final String asOf;
  final List<Stock> stocks;
  final List<Holding> holdings;
  final List<Txn> transactions;
  final double cashEgp;
  final double cashUsd;

  const MockData({
    required this.asOf,
    required this.stocks,
    required this.holdings,
    required this.transactions,
    required this.cashEgp,
    required this.cashUsd,
  });
}

/// Reads the three static JSON assets. This is the only "data source" in the
/// app — there are no network calls anywhere in this build.
class MockDataService {
  const MockDataService();

  Future<MockData> load() async {
    final stocksRaw = await _json('assets/data/stocks.json');
    final portfolioRaw = await _json('assets/data/portfolio.json');
    final txRaw = await _json('assets/data/transactions.json');

    final stocks = (stocksRaw['stocks'] as List)
        .map((e) => Stock.fromJson(e as Map<String, dynamic>))
        .toList();

    final holdings = (portfolioRaw['holdings'] as List)
        .map((e) => Holding.fromJson(e as Map<String, dynamic>))
        .toList();

    final transactions =
        (txRaw['transactions'] as List)
            .map((e) => Txn.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));

    return MockData(
      asOf: stocksRaw['as_of'] as String,
      stocks: stocks,
      holdings: holdings,
      transactions: transactions,
      cashEgp: (portfolioRaw['cash_egp'] as num).toDouble(),
      cashUsd: (portfolioRaw['cash_usd'] as num).toDouble(),
    );
  }

  Future<Map<String, dynamic>> _json(String path) async {
    final raw = await rootBundle.loadString(path);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}
