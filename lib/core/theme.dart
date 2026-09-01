import 'package:flutter/material.dart';

class OfficeTheme {
  // Ultra-Premium Renk Paleti (Deep Navy, Electric Cyan, Emerald Aurora, Royal Indigo, Sunset Gold)
  static const Color primaryBrand = Color(0xFF0284C7); // Electric Ocean Blue
  static const Color primaryBrandLight = Color(0xFFE0F2FE); // Soft Ice Cyan Light
  static const Color primaryBrandDark = Color(0xFF0369A1); // Deep Sapphire
  static const Color cyanGlow = Color(0xFF38BDF8); // Glowing Cyan
  static const Color deepNavy = Color(0xFF080E1E); // Midnight Deep Glass
  static const Color cardDarkGlass = Color(0x2A1E293B); // Frosted Dark
  static const Color cardLightGlass = Color(0xE6FFFFFF); // Frosted Light
  static const Color borderGlow = Color(0x3338BDF8); // Glass Border Highlight

  static const Color docColor = Color(0xFF2563EB); // Word Royal Blue
  static const Color docLight = Color(0xFFDBEAFE);

  static const Color sheetColor = Color(0xFF059669); // Excel Emerald
  static const Color sheetLight = Color(0xFFD1FAE5);

  static const Color slideColor = Color(0xFFEA580C); // PowerPoint Amber/Orange
  static const Color slideLight = Color(0xFFFFEDD5);

  static const Color pdfColor = Color(0xFFDC2626); // PDF Crimson
  static const Color pdfLight = Color(0xFFFEE2E2);

  static const Color aiColor = Color(0xFF7C3AED); // AI Violet
  static const Color aiGradientStart = Color(0xFF06B6D4);
  static const Color aiGradientEnd = Color(0xFF8B5CF6);

  static const Color goldPro = Color(0xFFF59E0B);
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Ana Parıltı Gradyanı
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF06B6D4), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // AI Parıltı Gradyanı
  static const LinearGradient aiBannerGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0C1F3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Arka Plan Cam Efekti Gradyanı (Karanlık Mod)
  static const RadialGradient darkBackgroundGlow = RadialGradient(
    center: Alignment(0.4, -0.6),
    radius: 1.5,
    colors: [
      Color(0xFF101C38),
      Color(0xFF091122),
      Color(0xFF050914),
    ],
  );

  // Arka Plan Cam Efekti Gradyanı (Aydınlık Mod)
  static const RadialGradient lightBackgroundGlow = RadialGradient(
    center: Alignment(-0.5, -0.7),
    radius: 1.6,
    colors: [
      Color(0xFFE2F0FE),
      Color(0xFFF0F7FF),
      Color(0xFFF8FAFC),
    ],
  );

  // Ultra-Lüks Cam Kutu Dekoratörü
  static BoxDecoration glassBox({
    required bool isDark,
    double radius = 20,
    Color? borderColor,
    Color? fillColor,
    bool glow = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: fillColor ??
          (isDark
              ? const Color(0xFF111D36).withValues(alpha: 0.78)
              : Colors.white.withValues(alpha: 0.92)),
      border: Border.all(
        color: borderColor ??
            (isDark
                ? Colors.cyanAccent.withValues(alpha: 0.22)
                : const Color(0xFF0284C7).withValues(alpha: 0.16)),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.45)
              : const Color(0xFF0284C7).withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
        if (glow)
          BoxShadow(
            color: (borderColor ?? cyanGlow).withValues(alpha: 0.25),
            blurRadius: 18,
            spreadRadius: 1,
          ),
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBrand,
        brightness: Brightness.light,
        surface: const Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F7FF),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        color: Colors.white.withValues(alpha: 0.95),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBrand,
        brightness: Brightness.dark,
        surface: const Color(0xFF091122),
      ),
      scaffoldBackgroundColor: const Color(0xFF050914),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.cyanAccent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        color: const Color(0xFF101B33).withValues(alpha: 0.8),
      ),
    );
  }
}
