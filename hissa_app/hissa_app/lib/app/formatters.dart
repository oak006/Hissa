import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'strings.dart';

/// Numerals are Western in both languages — deliberately consistent, and what
/// Egyptian banking apps generally show. The *labels* localise, the digits
/// do not, so a judge reading either language sees the same figures.
class Fmt {
  Fmt._();

  static final _egp = NumberFormat('#,##0.00', 'en_US');
  static final _egpWhole = NumberFormat('#,##0', 'en_US');
  static final _usd = NumberFormat('#,##0.00', 'en_US');
  static final _pct = NumberFormat('#,##0.00', 'en_US');
  static final _date = DateFormat('d MMM yyyy', 'en_US');
  static final _dateTime = DateFormat('d MMM · HH:mm', 'en_US');

  /// `EGP 1,234.50` / `1,234.50 ج.م`
  static String egp(BuildContext c, double v, {bool whole = false}) {
    final n = whole ? _egpWhole.format(v) : _egp.format(v);
    final label = c.s.t('egp');
    return c.s.isAr ? '$n $label' : 'EGP $n';
  }

  static String usd(BuildContext c, double v) {
    final n = _usd.format(v);
    return c.s.isAr ? '\$$n' : '\$$n';
  }

  /// Signed percent, always two decimals: `+1.82%` / `-0.43%`.
  static String pct(double v) {
    final sign = v > 0 ? '+' : (v < 0 ? '-' : '');
    return '$sign${_pct.format(v.abs())}%';
  }

  static String signedEgp(BuildContext c, double v) {
    final sign = v > 0 ? '+' : (v < 0 ? '-' : '');
    return '$sign${egp(c, v.abs())}';
  }

  static String signedUsd(BuildContext c, double v) {
    final sign = v > 0 ? '+' : (v < 0 ? '-' : '');
    return '$sign\$${_usd.format(v.abs())}';
  }

  /// Fractions of a share get four decimals — this number is the product.
  static String fraction(double v) => v.toStringAsFixed(4);

  static String price(double v) => _usd.format(v);

  static String date(DateTime d) => _date.format(d);
  static String dateTime(DateTime d) => _dateTime.format(d);

  /// `0:58`
  static String clock(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
