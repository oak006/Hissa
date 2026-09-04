import 'dart:async';
import 'dart:math';

import '../app/constants.dart';

/// Nudges displayed prices every few seconds so the app feels alive on stage.
///
/// Deliberately gentle: each tick moves a price by at most ±0.3%, and a price
/// is never allowed to wander more than ±2% from its snapshot close — the
/// numbers stay recognisably the ones in `stocks.json`, and a stock quoted as
/// "up today" does not silently become "down".
class PriceTickService {
  final Random _rnd = Random(20260828);
  Timer? _timer;

  /// ticker -> current live price
  final Map<String, double> _live = {};

  /// ticker -> snapshot close (the anchor the drift is measured against)
  final Map<String, double> _base = {};

  void seed(Map<String, double> snapshotPrices) {
    _base
      ..clear()
      ..addAll(snapshotPrices);
    _live
      ..clear()
      ..addAll(snapshotPrices);
  }

  double priceOf(String ticker) => _live[ticker] ?? _base[ticker] ?? 0;

  Map<String, double> get prices => Map.unmodifiable(_live);

  /// [onTick] fires after every batch so providers can rebuild once, not
  /// twenty times.
  void start(void Function() onTick) {
    _timer?.cancel();
    _timer = Timer.periodic(K.tickInterval, (_) {
      _step();
      onTick();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _step() {
    for (final ticker in _live.keys.toList()) {
      final base = _base[ticker]!;
      final current = _live[ticker]!;
      final nudge = (_rnd.nextDouble() * 2 - 1) * K.tickMagnitude;
      var next = current * (1 + nudge);

      // Keep it tethered to the snapshot.
      final lo = base * (1 - K.tickMaxDrift);
      final hi = base * (1 + K.tickMaxDrift);
      next = next.clamp(lo, hi);

      _live[ticker] = double.parse(next.toStringAsFixed(2));
    }
  }

  /// Live day-change %, folding the tick drift into the snapshot's day change
  /// so the badge and the price never contradict each other.
  double dayChangePct(String ticker, double snapshotDayChangePct) {
    final base = _base[ticker];
    final live = _live[ticker];
    if (base == null || live == null || base == 0) return snapshotDayChangePct;
    final drift = (live - base) / base * 100;
    return snapshotDayChangePct + drift;
  }

  void reset() {
    _live
      ..clear()
      ..addAll(_base);
  }

  void dispose() => stop();
}
