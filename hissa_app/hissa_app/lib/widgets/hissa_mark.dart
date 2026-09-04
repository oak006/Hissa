import 'package:flutter/material.dart';

/// The Hissa brand assets, derived from `logo.png` by `tool/gen_brand.py`.
///
/// Both are white-on-transparent, so they sit on any background and can be
/// tinted. The same two images back the web loading screen, the Android launch
/// screen and the app icons — one source of truth for the brand, so the
/// handover from loader to app is seamless.

/// The `H` glyph alone, with its rising stroke. Used wherever the brand needs
/// to appear small: the app bar avatar, the mock notification, Settings.
class HissaMark extends StatelessWidget {
  final double size;
  final Color color;

  const HissaMark({super.key, this.size = 44, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/hissa_mark.png',
      height: size,
      // The glyph is slightly taller than wide; height drives the fit.
      fit: BoxFit.contain,
      color: color,
      filterQuality: FilterQuality.medium,
      // A missing asset should never punch a hole in the UI mid-demo.
      errorBuilder: (_, __, ___) => SizedBox(height: size),
    );
  }
}

/// The full `Hissa` lockup. For the splash and anywhere the brand gets room.
class HissaWordmark extends StatelessWidget {
  final double height;
  final Color color;

  const HissaWordmark({super.key, this.height = 56, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/hissa_wordmark.png',
      height: height,
      fit: BoxFit.contain,
      color: color,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => SizedBox(height: height),
    );
  }
}
