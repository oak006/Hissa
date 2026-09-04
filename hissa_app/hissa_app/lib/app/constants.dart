import 'package:flutter/material.dart';

/// Every tunable value in the demo lives here. Prices, FX, fees, tier pricing
/// and brand colours — change them in this one file.
class K {
  K._();

  // ---------------------------------------------------------------- brand
  static const navy = Color(0xFF173784);
  static const royal = Color(0xFF2F5FE0);
  static const light = Color(0xFFF5F7FB);
  static const ink = Color(0xFF0F1B33);
  static const grey = Color(0xFF5C6473);
  static const amber = Color(0xFFE8A317);

  /// Standard finance convention — never amber for gains.
  static const gain = Color(0xFF11A66B);
  static const loss = Color(0xFFDD3B3B);

  // dark-theme surfaces
  static const darkBg = Color(0xFF0A1226);
  static const darkSurface = Color(0xFF121C36);
  static const darkCard = Color(0xFF17233F);

  // ------------------------------------------------------------------ fx
  /// EGP per 1 USD. Single source of truth for every conversion in the app.
  static const double fxEgpPerUsd = 48.65;

  /// How long a quoted rate stays "locked" before it re-quotes.
  static const int rateLockSeconds = 60;

  // ---------------------------------------------------------------- fees
  /// Trade commission as a fraction of order value (0.001 == 0.1%).
  static const double commissionRate = 0.001;

  /// Flat per-order fee, in EGP.
  static const double flatFeeEgp = 5.0;

  /// Minimum order, in EGP.
  static const double minOrderEgp = 50.0;

  /// Quick-select chips on the trade screen.
  static const List<double> quickAmountsEgp = [100, 500, 1000, 5000];

  // ----------------------------------------------------------- plan prices
  static const double tierFreeEgp = 0;
  static const double tier2Egp = 150;
  static const double tier3Egp = 250;

  // ------------------------------------------------------------ simulation
  /// Gentle simulated tick so the app feels alive. Kept deliberately subtle.
  static const Duration tickInterval = Duration(seconds: 5);

  /// Maximum nudge per tick, as a fraction (0.003 == ±0.3%).
  static const double tickMagnitude = 0.003;

  /// How far a ticked price may drift from its snapshot close.
  static const double tickMaxDrift = 0.02;

  // ---------------------------------------------------------------- timing
  static const Duration processingDelay = Duration(seconds: 2);
  static const Duration scanDelay = Duration(seconds: 2);
  static const int otpResendSeconds = 30;

  // ----------------------------------------------------------------- shape
  static const double radiusCard = 20;
  static const double radiusChip = 14;
  static const double radiusButton = 16;
  static const EdgeInsets pagePad = EdgeInsets.symmetric(horizontal: 20);
}
