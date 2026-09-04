import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';

/// Cairo for both locales — it carries a proper Arabic cut and a clean Latin
/// one, so switching language does not change the app's voice.
class AppTheme {
  AppTheme._();

  static TextTheme _text(TextTheme base, Color ink, Color grey) {
    final t = GoogleFonts.cairoTextTheme(base);
    return t.copyWith(
      displaySmall: t.displaySmall?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: t.headlineMedium?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: t.headlineSmall?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: t.titleLarge?.copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: t.titleMedium?.copyWith(
        color: ink,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: t.titleSmall?.copyWith(
        color: ink,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: t.bodyLarge?.copyWith(color: ink),
      bodyMedium: t.bodyMedium?.copyWith(color: ink),
      bodySmall: t.bodySmall?.copyWith(color: grey),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      labelMedium: t.labelMedium?.copyWith(color: grey),
      labelSmall: t.labelSmall?.copyWith(color: grey),
    );
  }

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: K.royal,
          brightness: Brightness.light,
        ).copyWith(
          primary: K.royal,
          onPrimary: Colors.white,
          secondary: K.navy,
          surface: Colors.white,
          onSurface: K.ink,
          surfaceContainerHighest: const Color(0xFFE9EDF6),
          outlineVariant: const Color(0xFFE2E7F0),
        );
    return _base(scheme, K.light, K.ink, K.grey);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: K.royal,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF6E93F0),
          onPrimary: const Color(0xFF07132C),
          secondary: const Color(0xFF9FB8F5),
          surface: K.darkCard,
          onSurface: const Color(0xFFE8ECF6),
          surfaceContainerHighest: const Color(0xFF1E2C4C),
          outlineVariant: const Color(0xFF2A3A5C),
        );
    return _base(
      scheme,
      K.darkBg,
      const Color(0xFFE8ECF6),
      const Color(0xFF97A1B8),
    );
  }

  static ThemeData _base(ColorScheme scheme, Color bg, Color ink, Color grey) {
    final isDark = scheme.brightness == Brightness.dark;
    final text = _text(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ink,
      grey,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: ink),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.radiusCard),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(K.radiusButton),
          ),
          disabledBackgroundColor: isDark
              ? const Color(0xFF26334F)
              : const Color(0xFFD7DEEC),
          disabledForegroundColor: isDark
              ? const Color(0xFF6B7794)
              : const Color(0xFF9AA4B8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(K.radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? K.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusButton),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusButton),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusButton),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusButton),
          borderSide: const BorderSide(color: K.loss),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(K.radiusButton),
          borderSide: const BorderSide(color: K.loss, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? K.darkSurface : Colors.white,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelLarge?.copyWith(color: ink, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.radiusChip),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? K.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? const Color(0xFF23335A) : K.navy,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.radiusButton),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(K.radiusCard),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? K.darkSurface : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.outlineVariant,
      ),
    );
  }
}

/// Convenience accessors used all over the UI.
extension ThemeX on BuildContext {
  ThemeData get th => Theme.of(this);
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Muted label colour that works in both themes.
  Color get muted => isDark ? const Color(0xFF97A1B8) : K.grey;

  /// Page background one step behind the cards.
  Color get pageBg => isDark ? K.darkBg : K.light;

  Color deltaColor(double v) => v > 0 ? K.gain : (v < 0 ? K.loss : muted);
}
