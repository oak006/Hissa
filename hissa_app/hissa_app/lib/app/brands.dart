import 'package:flutter/material.dart';

/// Per-ticker brand identity for the logo tile.
///
/// Every instrument gets its real brand colour. Where an SVG mark is bundled
/// in `assets/logos/` it is drawn in white on that colour; where one is not
/// (the ETFs, and a handful of companies whose marks are not in the icon set)
/// the ticker itself is drawn instead. Because the tile colour is always
/// authentic, the mixed set still reads as one system.
///
/// The marks are trademarks of their respective owners, used here only to
/// identify the security being quoted.
class Brand {
  /// Tile background.
  final Color color;

  /// Asset name in `assets/logos/`, without the extension. Null falls back to
  /// the ticker monogram.
  final String? asset;

  const Brand(this.color, [this.asset]);

  String? get assetPath => asset == null ? null : 'assets/logos/$asset.svg';

  static const _map = <String, Brand>{
    'NVDA': Brand(Color(0xFF76B900), 'nvidia'),
    'AAPL': Brand(Color(0xFF1D1D1F), 'apple'),
    'GOOGL': Brand(Color(0xFF4285F4), 'google'),
    'META': Brand(Color(0xFF0467DF), 'meta'),
    'TSLA': Brand(Color(0xFFCC0000), 'tesla'),
    'AMD': Brand(Color(0xFFED1C24), 'amd'),
    'NFLX': Brand(Color(0xFFE50914), 'netflix'),
    'PLTR': Brand(Color(0xFF2B2F36), 'palantir'),
    'KO': Brand(Color(0xFFF40009), 'cocacola'),
    'NKE': Brand(Color(0xFF111111), 'nike'),
    'V': Brand(Color(0xFF1A1F71), 'visa'),
    'MCD': Brand(Color(0xFFDA291C), 'mcdonalds'),

    // Marks not available in the bundled icon set — brand colour + ticker.
    'MSFT': Brand(Color(0xFF0067B8)),
    'AMZN': Brand(Color(0xFFE47911)),
    'DIS': Brand(Color(0xFF113CCF)),
    'JPM': Brand(Color(0xFF117ACA)),

    // Funds have no logotype; the ticker is the identity.
    'SPY': Brand(Color(0xFFC8102E)),
    'VOO': Brand(Color(0xFF96151D)),
    'VTI': Brand(Color(0xFF7A2E33)),
    'QQQ': Brand(Color(0xFF003DA5)),
  };

  static Brand of(String ticker) =>
      _map[ticker] ?? const Brand(Color(0xFF2F5FE0));
}
