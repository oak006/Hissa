import 'package:flutter/material.dart';

import '../models/user.dart';

/// Locale, theme and the demo user.
///
/// The app opens in English + dark. Arabic/RTL is fully supported and one tap
/// away in Settings — the toggle flips `Directionality` through
/// `MaterialApp.locale`, and every screen is laid out RTL-first.
class AppProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.dark;
  DemoUser _user = const DemoUser();
  bool _onboarded = false;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  DemoUser get user => _user;
  bool get isAr => _locale.languageCode == 'ar';
  bool get onboarded => _onboarded;

  void setLocale(Locale l) {
    if (_locale == l) return;
    _locale = l;
    notifyListeners();
  }

  void toggleLocale() =>
      setLocale(isAr ? const Locale('en') : const Locale('ar'));

  void setThemeMode(ThemeMode m) {
    if (_themeMode == m) return;
    _themeMode = m;
    notifyListeners();
  }

  void setPhone(String phone) {
    _user = _user.copyWith(phone: phone);
    notifyListeners();
  }

  void setRiskProfile(String key) {
    _user = _user.copyWith(riskProfileKey: key);
    notifyListeners();
  }

  void completeOnboarding() {
    _onboarded = true;
    notifyListeners();
  }

  /// Language and theme are the presenter's stage settings — a demo reset
  /// should not yank them out from under a talk in progress.
  void reset() {
    _user = const DemoUser();
    _onboarded = false;
    notifyListeners();
  }
}
