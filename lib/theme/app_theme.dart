import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color surface;
  final Color card;
  final Color input;
  final Color border;
  
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textHint;
  
  final Color error;
  final Color success;
  final Color primaryOrange;

  const AppColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.input,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textHint,
    required this.error,
    required this.success,
    required this.primaryOrange,
  });

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? input,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textHint,
    Color? error,
    Color? success,
    Color? primaryOrange,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      input: input ?? this.input,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textHint: textHint ?? this.textHint,
      error: error ?? this.error,
      success: success ?? this.success,
      primaryOrange: primaryOrange ?? this.primaryOrange,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      input: Color.lerp(input, other.input, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      primaryOrange: Color.lerp(primaryOrange, other.primaryOrange, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

extension AppColorsX on AppColors {
  /// Convenience alias for primaryOrange
  Color get primary => primaryOrange;
}

class AppTheme {
  // Brand Colors used globally
  static const Color primaryOrange = Color(0xFFF05A19);
  static const Color primaryOrangeDark = Color(0xFFD44D10);
  static const Color primaryOrangeLight = Color(0xFFFF7A3D);
  static const Color errorColor = Color(0xFFFF4D4D);
  static const Color successColor = Color(0xFF4CAF50);

  // --- Dark Mode Colors ---
  static const Color _bgDark = Color(0xFF0D0D0D);
  static const Color _surfDark = Color(0xFF1A1A1A);
  static const Color _cardDark = Color(0xFF242424);
  static const Color _inpDark = Color(0xFF2A2A2A);
  static const Color _bdrDark = Color(0xFF3A3A3A);
  static const Color _tpDark = Color(0xFFF5F5F5);
  static const Color _tsDark = Color(0xFFAAAAAA);
  static const Color _tmDark = Color(0xFF666666);
  static const Color _thDark = Color(0xFF555555);

  // --- Light Mode Colors ---
  static const Color _bgLight = Color(0xFFF5F7FA);
  static const Color _surfLight = Color(0xFFFFFFFF);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _inpLight = Color(0xFFF0F2F5);
  static const Color _bdrLight = Color(0xFFE4E7EB);
  static const Color _tpLight = Color(0xFF1A1D20);
  static const Color _tsLight = Color(0xFF6A727D);
  static const Color _tmLight = Color(0xFFA1A9B3);
  static const Color _thLight = Color(0xFFB0B8C1);

  // Deprecated constants (to keep backwards compatibility during migration if missed)
  static const Color backgroundDark = _bgDark;
  static const Color surfaceDark = _surfDark;
  static const Color cardDark = _cardDark;
  static const Color inputDark = _inpDark;
  static const Color borderDark = _bdrDark;
  static const Color textPrimary = _tpDark;
  static const Color textSecondary = _tsDark;
  static const Color textMuted = _tmDark;
  static const Color textHint = _thDark;

  static const AppColors _darkAppColors = AppColors(
    background: _bgDark,
    surface: _surfDark,
    card: _cardDark,
    input: _inpDark,
    border: _bdrDark,
    textPrimary: _tpDark,
    textSecondary: _tsDark,
    textMuted: _tmDark,
    textHint: _thDark,
    error: errorColor,
    success: successColor,
    primaryOrange: primaryOrange,
  );

  static const AppColors _lightAppColors = AppColors(
    background: _bgLight,
    surface: _surfLight,
    card: _cardLight,
    input: _inpLight,
    border: _bdrLight,
    textPrimary: _tpLight,
    textSecondary: _tsLight,
    textMuted: _tmLight,
    textHint: _thLight,
    error: errorColor,
    success: successColor,
    primaryOrange: primaryOrange,
  );

  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      bg: _bgDark,
      surf: _surfDark,
      tp: _tpDark,
      ts: _tsDark,
      tm: _tmDark,
      th: _thDark,
      inp: _inpDark,
      bdr: _bdrDark,
      card: _cardDark,
      appColors: _darkAppColors,
    );
  }

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      bg: _bgLight,
      surf: _surfLight,
      tp: _tpLight,
      ts: _tsLight,
      tm: _tmLight,
      th: _thLight,
      inp: _inpLight,
      bdr: _bdrLight,
      card: _cardLight,
      appColors: _lightAppColors,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color surf,
    required Color tp,
    required Color ts,
    required Color tm,
    required Color th,
    required Color inp,
    required Color bdr,
    required Color card,
    required AppColors appColors,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: primaryOrange,
      extensions: <ThemeExtension<dynamic>>[appColors],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryOrange,
        onPrimary: Colors.white,
        secondary: primaryOrangeLight,
        onSecondary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        surface: surf,
        onSurface: tp,
      ),
      textTheme: GoogleFonts.beVietnamProTextTheme(
        TextTheme(
          displayLarge: TextStyle(color: tp, fontSize: 32, fontWeight: FontWeight.w800),
          displayMedium: TextStyle(color: tp, fontSize: 28, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(color: tp, fontSize: 24, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: tp, fontSize: 20, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: tp, fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: tp, fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(color: ts, fontSize: 14, fontWeight: FontWeight.w400),
          bodySmall: TextStyle(color: tm, fontSize: 12, fontWeight: FontWeight.w400),
          labelLarge: TextStyle(color: tp, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inp,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: bdr, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: bdr, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 1.5),
        ),
        labelStyle: GoogleFonts.beVietnamPro(color: ts, fontSize: 14),
        hintStyle: GoogleFonts.beVietnamPro(color: th, fontSize: 14),
        errorStyle: GoogleFonts.beVietnamPro(color: errorColor, fontSize: 12),
        prefixIconColor: tm,
        suffixIconColor: tm,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryOrange,
          textStyle: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: tp),
        titleTextStyle: GoogleFonts.beVietnamPro(color: tp, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      dividerTheme: DividerThemeData(color: bdr, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: GoogleFonts.beVietnamPro(color: tp, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
