import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Material 3 dark theme tuned for a finance/crypto aesthetic.
class AppTheme {
  AppTheme._();

  // ── Brand Colors ───────────────────────────────────────────────────────
  static const Color _primaryGold = Color(0xFFF0B90B);
  static const Color _surfaceDark = Color(0xFF12131A);
  static const Color _cardDark = Color(0xFF1A1D2E);
  static const Color _cardBorder = Color(0xFF262A3D);
  static const Color _textPrimary = Color(0xFFF0F0F5);
  static const Color _textSecondary = Color(0xFF8B8CA7);
  static const Color _green = Color(0xFF00D68F);
  static const Color _red = Color(0xFFFF4D6A);

  // Expose for widget use
  static Color get green => _green;
  static Color get red => _red;
  static Color get gold => _primaryGold;
  static Color get cardColor => _cardDark;
  static Color get cardBorderColor => _cardBorder;
  static Color get textSecondary => _textSecondary;

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _surfaceDark,
      colorScheme: ColorScheme.dark(
        primary: _primaryGold,
        onPrimary: Colors.black,
        secondary: _primaryGold.withValues(alpha: 0.8),
        surface: _surfaceDark,
        onSurface: _textPrimary,
        error: _red,
        onError: Colors.white,
      ),
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: _textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: _textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: _textPrimary,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: _textPrimary),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: _textSecondary),
        bodySmall: textTheme.bodySmall?.copyWith(color: _textSecondary),
        labelLarge: textTheme.labelLarge?.copyWith(
          color: _textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _cardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _surfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _cardDark,
        indicatorColor: _primaryGold.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: isSelected ? _primaryGold : _textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? _primaryGold : _textSecondary,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryGold, width: 1.5),
        ),
        labelStyle: const TextStyle(color: _textSecondary),
        hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.6)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _primaryGold.withValues(alpha: 0.1),
        labelStyle: textTheme.labelSmall?.copyWith(color: _primaryGold),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _cardBorder,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _cardDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: _textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
