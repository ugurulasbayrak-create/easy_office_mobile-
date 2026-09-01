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
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: _isDark
                    ? const Color(0xFF091122).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.90),
                border: Border(
                  top: BorderSide(
                    color: _isDark
                        ? Colors.cyanAccent.withValues(alpha: 0.2)
                        : const Color(0xFF0284C7).withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : const Color(0xFF0284C7).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: BottomNavigationBar(
                    currentIndex: _currentNavIdx,
                    onTap: (idx) => setState(() => _currentNavIdx = idx),
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    selectedItemColor: _isDark ? OfficeTheme.cyanGlow : OfficeTheme.primaryBrand,
                    unselectedItemColor: _isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    items: [
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.home_rounded),
                        label: LanguageProvider.tr('nav_home'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.sync_alt_rounded),
                        label: LanguageProvider.tr('nav_converter'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: LanguageProvider.tr('nav_tools'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: LanguageProvider.tr('nav_ai'),
                      ),
                      BottomNavigationBarItem(
                        icon: const Icon(Icons.dashboard_customize_rounded),
                        label: LanguageProvider.tr('nav_templates'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

