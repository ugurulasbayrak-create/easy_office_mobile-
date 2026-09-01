import 'package:flutter/material.dart';

class OfficeTheme {
  // 1. İkon ile Birebir Uyumlu Renk Paleti (Camgöbeği, Derin Gece Mavisi, Neon ve Altın Işıltı)
  static const Color primaryBrand = Color(0xFF0284C7); // Electric Ocean Blue
  static const Color primaryBrandLight = Color(0xFFE0F2FE); // Soft Ice Cyan Light
  static const Color primaryBrandDark = Color(0xFF0369A1); // Deep Sapphire
  static const Color cyanGlow = Color(0xFF38BDF8); // Glowing Cyan
  static const Color deepNavy = Color(0xFF080E1E); // Midnight Deep Glass
  static const Color cardDarkGlass = Color(0x2A1E293B); // Frosted Dark
  static const Color cardLightGlass = Color(0xE6FFFFFF); // Frosted Light
  static const Color borderGlow = Color(0x3338BDF8); // Glass Border Highlight

  static const Color docColor = Color(0xFF0284C7); // Word Cyan/Royal
  static const Color docLight = Color(0xFFE0F2FE);

  static const Color sheetColor = Color(0xFF10B981); // Excel Emerald
  static const Color sheetLight = Color(0xFFD1FAE5);

  static const Color slideColor = Color(0xFFF97316); // PowerPoint Amber/Orange
  static const Color slideLight = Color(0xFFFFEDD5);

  static const Color pdfColor = Color(0xFFEF4444); // PDF Crimson
  static const Color pdfLight = Color(0xFFFEE2E2);

  static const Color aiColor = Color(0xFF8B5CF6); // AI Violet
  static const Color aiGradientStart = Color(0xFF06B6D4);
  static const Color aiGradientEnd = Color(0xFF8B5CF6);

  static const Color goldPro = Color(0xFFF59E0B);
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // İkon #1 ile Uyumlu Ana Parıltı Gradyanı
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF06B6D4), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Arka Plan Cam Efekti Gradyanı (Karanlık Mod)
  static const RadialGradient darkBackgroundGlow = RadialGradient(
    center: Alignment(0.4, -0.6),
    radius: 1.4,
    colors: [
      Color(0xFF112240),
      Color(0xFF0A1224),
      Color(0xFF060B14),
    ],
  );

  // Arka Plan Cam Efekti Gradyanı (Aydınlık Mod)
  static const RadialGradient lightBackgroundGlow = RadialGradient(
    center: Alignment(-0.5, -0.7),
    radius: 1.5,
    colors: [
      Color(0xFFE0F2FE),
      Color(0xFFF0F9FF),
      Color(0xFFF8FAFC),
    ],
  );

  // Cam Kutu Dekoratörü
  static BoxDecoration glassBox({
    required bool isDark,
    double radius = 18,
    Color? borderColor,
    Color? fillColor,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: fillColor ??
          (isDark
              ? const Color(0xFF131D33).withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.88)),
      border: Border.all(
        color: borderColor ??
            (isDark
                ? Colors.cyanAccent.withValues(alpha: 0.22)
                : const Color(0xFF0284C7).withValues(alpha: 0.18)),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0xFF0284C7).withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        color: Colors.white.withValues(alpha: 0.9),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFF8FAFC),
        selectedItemColor: Color(0xFF0284C7),
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBrand,
        brightness: Brightness.dark,
        surface: const Color(0xFF101B30),
      ),
      scaffoldBackgroundColor: const Color(0xFF070C18),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Colors.cyanAccent.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        color: const Color(0xFF121E36).withValues(alpha: 0.85),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF091122),
        selectedItemColor: Color(0xFF38BDF8),
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }
}

