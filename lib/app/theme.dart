import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Panduan desain sesuai Tabel 14 (Tahap 2).
class AppColors {
  static const primary = Color(0xFF2E7D6B); // hijau tua
  static const mint = Color(0xFFA8E6CF); // hijau mint
  static const sky = Color(0xFFDCEEFB); // biru muda
  static const orange = Color(0xFFF59E0B); // aksen / menunggu
  static const red = Color(0xFFDC2626); // pembatalan
  static const ink = Color(0xFF14302A);
  static const muted = Color(0xFF5F746F);
  static const line = Color(0xFFDDE8E5);
  static const tint = Color(0xFFF1F8F6);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      secondary: AppColors.orange,
      error: AppColors.red,
      surface: Colors.white,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    // Font Nunito: bulat, ramah, jelas. Isi minimal 16 sp, judul 20-24 sp.
    final text = GoogleFonts.nunitoTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          bodyLarge: GoogleFonts.nunito(fontSize: 17, color: AppColors.ink),
          bodyMedium: GoogleFonts.nunito(fontSize: 16, color: AppColors.ink),
          bodySmall: GoogleFonts.nunito(fontSize: 14, color: AppColors.muted),
          titleLarge: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
          titleMedium: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
          titleSmall: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
          labelLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
        );

    final radius = BorderRadius.circular(12);
    OutlineInputBorder border(Color c, [double w = 1.2]) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c, width: w));

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.tint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: text.bodyMedium?.copyWith(color: AppColors.muted),
        hintStyle: text.bodyMedium?.copyWith(color: AppColors.muted),
        border: border(AppColors.line),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.primary, 2),
        errorBorder: border(AppColors.red),
        focusedErrorBorder: border(AppColors.red, 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: const BorderSide(color: AppColors.line, width: 1.5),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 48),
          textStyle: text.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.mint,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => GoogleFonts.nunito(
              fontSize: 12.5,
              fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
              color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              size: 26,
              color: s.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted,
            )),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
    );
  }
}
