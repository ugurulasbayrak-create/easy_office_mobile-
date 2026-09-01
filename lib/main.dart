import 'dart:ui';
import 'package:flutter/material.dart';
import 'core/localization.dart';
import 'core/theme.dart';
import 'screens/ai_copilot_screen.dart';
import 'screens/file_converter_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pdf_tools_screen.dart';
import 'screens/templates_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EasyOfficeMobileApp());
}

class EasyOfficeMobileApp extends StatefulWidget {
  const EasyOfficeMobileApp({super.key});

  @override
  State<EasyOfficeMobileApp> createState() => _EasyOfficeMobileAppState();
}

class _EasyOfficeMobileAppState extends State<EasyOfficeMobileApp> {
  bool _isDark = false;
  int _currentNavIdx = 0;

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentNavIdx = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = LanguageProvider();

    return ListenableBuilder(
      listenable: langProvider,
      builder: (context, _) {
        final screens = [
          HomeScreen(
            onToggleTheme: _toggleTheme,
            isDark: _isDark,
            onNavigateToTab: _navigateToTab,
          ),
          const FileConverterScreen(),
          const PdfToolsScreen(),
          const AiCopilotScreen(),
          const TemplatesScreen(),
        ];

        return MaterialApp(
          title: 'Easy Office Mobile',
          debugShowCheckedModeBanner: false,
          theme: OfficeTheme.lightTheme,
          darkTheme: OfficeTheme.darkTheme,
          themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
          home: Scaffold(
            extendBody: true,
            body: IndexedStack(
              index: _currentNavIdx,
              children: screens,
            ),
            bottomNavigationBar: _buildFloatingGlassNavDock(_isDark),
          ),
        );
      },
    );
  }

  Widget _buildFloatingGlassNavDock(bool isDark) {
    final navItems = [
      {'icon': Icons.home_rounded, 'label': LanguageProvider.tr('nav_home')},
      {'icon': Icons.sync_alt_rounded, 'label': LanguageProvider.tr('nav_converter')},
      {'icon': Icons.picture_as_pdf_rounded, 'label': LanguageProvider.tr('nav_tools')},
      {'icon': Icons.auto_awesome_rounded, 'label': LanguageProvider.tr('nav_ai')},
      {'icon': Icons.dashboard_customize_rounded, 'label': LanguageProvider.tr('nav_templates')},
    ];

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: isDark
              ? const Color(0xFF0C172E).withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.90),
          border: Border.all(
            color: isDark
                ? Colors.cyanAccent.withValues(alpha: 0.25)
                : const Color(0xFF0284C7).withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : const Color(0xFF0284C7).withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (idx) {
                final isSelected = _currentNavIdx == idx;
                final item = navItems[idx];
                final isAiTab = idx == 3;

                return GestureDetector(
                  onTap: () => setState(() => _currentNavIdx = idx),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: isSelected
                        ? BoxDecoration(
                            gradient: isAiTab
                                ? const LinearGradient(
                                    colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                                  )
                                : LinearGradient(
                                    colors: [
                                      OfficeTheme.primaryBrand.withValues(alpha: isDark ? 0.35 : 0.20),
                                      OfficeTheme.cyanGlow.withValues(alpha: isDark ? 0.20 : 0.10),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isAiTab
                                  ? Colors.transparent
                                  : (isDark ? OfficeTheme.cyanGlow.withValues(alpha: 0.6) : OfficeTheme.primaryBrand.withValues(alpha: 0.4)),
                              width: 1,
                            ),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: isSelected ? 22 : 20,
                          color: isSelected
                              ? (isAiTab ? Colors.white : (isDark ? OfficeTheme.cyanGlow : OfficeTheme.primaryBrand))
                              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected
                                ? (isAiTab ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)))
                                : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
