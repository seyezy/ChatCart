import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatCartColors {
  static const brand900 = Color(0xFF075C36);
  static const brand700 = Color(0xFF087746);
  static const brand500 = Color(0xFF08A841);
  static const brand400 = Color(0xFF10B64B);
  static const brand100 = Color(0xFFE1F8E8);
  static const primaryLight = Color(0xFF058139);
  static const primaryDark = Color(0xFF10B64B);
  static const darkBg = Color(0xFF0B1110);
  static const darkSurface = Color(0xFF17201F);
}

class ChatCartTheme {
  static TextTheme _textTheme(Brightness b) => GoogleFonts.interTextTheme(
        ThemeData(brightness: b).textTheme,
      );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: ChatCartColors.primaryLight,
      brightness: Brightness.light,
      primary: ChatCartColors.primaryLight,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      textTheme: _textTheme(Brightness.light),
      inputDecorationTheme: _inputTheme(false),
      elevatedButtonTheme: _buttonTheme(false),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: Colors.white,
        indicatorColor: ChatCartColors.brand100,
        labelTextStyle: WidgetStatePropertyAll(GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600)),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: ChatCartColors.primaryDark,
      brightness: Brightness.dark,
      primary: ChatCartColors.primaryDark,
      surface: ChatCartColors.darkSurface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ChatCartColors.darkBg,
      textTheme: _textTheme(Brightness.dark).apply(
        bodyColor: const Color(0xFFF9FAFB),
        displayColor: const Color(0xFFF9FAFB),
      ),
      cardColor: ChatCartColors.darkSurface,
      dividerColor: const Color(0xFF293331),
      inputDecorationTheme: _inputTheme(true),
      elevatedButtonTheme: _buttonTheme(true),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: const Color(0xFF101817),
        indicatorColor: const Color(0xFF075C36),
        labelTextStyle: WidgetStatePropertyAll(GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600)),
      ),
    );
  }

  static InputDecorationTheme _inputTheme(bool dark) => InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF151E1C) : const Color(0xFFF8FAF9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: dark ? const Color(0xFF737D7B) : const Color(0xFF9CA3AF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dark ? const Color(0xFF293331) : const Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: dark ? const Color(0xFF293331) : const Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: ChatCartColors.brand500, width: 1.4)),
      );

  static ElevatedButtonThemeData _buttonTheme(bool dark) => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          foregroundColor: dark ? const Color(0xFF07110D) : Colors.white,
          backgroundColor: dark ? ChatCartColors.primaryDark : ChatCartColors.primaryLight,
          disabledBackgroundColor: dark ? const Color(0xFF303937) : const Color(0xFFD1D5DB),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
}
