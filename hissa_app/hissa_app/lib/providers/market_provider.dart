import 'package:flutter/foundation.dart';

import '../models/stock.dart';
import '../services/mock_data_service.dart';
import '../services/price_tick_service.dart';

/// Owns the static snapshot and the gentle live tick on top of it.
class MarketProvider extends ChangeNotifier {
  final MockDataService _service;
  final PriceTickService ticker = PriceTickService();

  MarketProvider([this._service = const MockDataService()]);

  MockData? _data;
  bool _loading = true;
  Object? _error;

  bool get loading => _loading;
  Object? get error => _error;
  bool get ready => _data != null;
  MockData? get data => _data;

  List<Stock> get stocks => _data?.stocks ?? const [];
  String get asOf => _data?.asOf ?? '';

  Future<void> load() async {
    try {
      final d = await _service.load();
      _data = d;
      ticker.seed({for (final s in d.stocks) s.ticker: s.snapshotPrice});
      ticker.start(notifyListeners);
      _error = null;
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Stock? byTicker(String ticker) {
    for (final s in stocks) {
      if (s.ticker == ticker) return s;
    }
    return null;
  }

  /// Live price, i.e. snapshot close plus the simulated drift.
  double priceOf(String ticker) {
    final live = this.ticker.priceOf(ticker);
    if (live != 0) return live;
    return byTicker(ticker)?.snapshotPrice ?? 0;
  }

  double dayChangePctOf(String ticker) {
    final s = byTicker(ticker);
    if (s == null) return 0;
    return this.ticker.dayChangePct(ticker, s.dayChangePct);
  }

  /// Filtered + searched list for the Invest screen.
  List<Stock> query({String search = '', String category = 'all'}) {
    final q = search.trim().toLowerCase();
    var list = stocks.where((s) {
      if (q.isNotEmpty) {
        final hit =
            s.ticker.toLowerCase().contains(q) ||
            s.nameEn.toLowerCase().contains(q) ||
            s.nameAr.contains(search.trim());
        if (!hit) return false;
      }
      return switch (category) {
        'tech' => s.sector == 'technology',
        'etf' => s.sector == 'etf',
        'popular' => s.popular,
        _ => true,
      };
    }).toList();

    if (category == 'movers') {
      list.sort(
        (a, b) => dayChangePctOf(
          b.ticker,
        ).abs().compareTo(dayChangePctOf(a.ticker).abs()),
      );
      list = list.take(10).toList();
    }
    return list;
  }

  void reset() {
    ticker.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }
}
