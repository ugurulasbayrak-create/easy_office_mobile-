import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../widgets/glass_background.dart';
import '../widgets/signature_pad.dart';
import 'file_converter_screen.dart';
import 'ocr_scanner_screen.dart';

class PdfToolsScreen extends StatefulWidget {
  const PdfToolsScreen({super.key});

  @override
  State<PdfToolsScreen> createState() => _PdfToolsScreenState();
}

class _PdfToolsScreenState extends State<PdfToolsScreen> {
  bool _isSigned = false;

  void _openSignaturePad() {
    showDialog(
      context: context,
      builder: (ctx) => SignaturePadDialog(
        onSaveSignature: (lines) {
          setState(() {
            _isSigned = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LanguageProvider.tr('signed')),
              backgroundColor: OfficeTheme.pdfColor,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          LanguageProvider.tr('nav_tools'),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: GlassBackground(
        isDark: isDark,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hızlı Araçlar Kart Izgarası
              Row(
                children: [
                  Expanded(
                    child: _buildToolCard(
                      icon: Icons.draw_rounded,
                      color: OfficeTheme.primaryBrand,
                      title: LanguageProvider.tr('digital_signature'),
                      subtitle: LanguageProvider.tr('digital_signature_sub'),
                      onTap: _openSignaturePad,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildToolCard(
                      icon: Icons.document_scanner_rounded,
                      color: OfficeTheme.sheetColor,
                      title: LanguageProvider.tr('ocr_scanner'),
                      subtitle: LanguageProvider.tr('ocr_scanner_sub'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OcrScannerScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildToolCard(
                      icon: Icons.transform_rounded,
                      color: Colors.deepPurpleAccent,
                      title: LanguageProvider.tr('converter_title'),
                      subtitle: 'Word, Excel, PDF, Resim dönüştürücü',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FileConverterScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildToolCard(
                      icon: Icons.compress_rounded,
                      color: OfficeTheme.slideColor,
                      title: LanguageProvider.tr('compress_pdf'),
                      subtitle: 'PDF dosya boyutunu küçültün',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FileConverterScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Text(
                'Aktif Sözleşme Belgesi (Önizleme)',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              // PDF Belge Cam Kartı
              GlassCard(
                isDark: isDark,
                radius: 18,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'HİZMET VE GİZLİLİK SÖZLEŞMESİ',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: OfficeTheme.pdfColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: OfficeTheme.primaryBrand.withValues(alpha: isDark ? 0.3 : 0.15),
                            foregroundColor: isDark ? OfficeTheme.cyanGlow : OfficeTheme.primaryBrand,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _openSignaturePad,
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: Text(_isSigned ? 'Yeniden İmzala' : LanguageProvider.tr('sign_pdf')),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      'İşbu sözleşme Easy Office platformu ile Müşteri arasında gizli ofis verileri ve mobil belge yönetimi için akdedilmiştir.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '1. Tüm belgeler ve taranan OCR verileri cihazda güvenle saklanır.\n2. PDF dönüştürme ve dijital imza damgalama yasal olarak geçerlidir.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // İmza Alanı
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yetkili İmza:',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Alex Morgan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 140,
                          height: 52,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isSigned
                                  ? OfficeTheme.cyanGlow
                                  : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                              width: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: _isSigned
                                ? OfficeTheme.primaryBrand.withValues(alpha: 0.18)
                                : Colors.transparent,
                          ),
                          child: Center(
                            child: _isSigned
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.verified_rounded, size: 16, color: OfficeTheme.cyanGlow),
                                      const SizedBox(width: 4),
                                      Text(
                                        LanguageProvider.tr('signed'),
                                        style: TextStyle(
                                          color: isDark ? OfficeTheme.cyanGlow : OfficeTheme.primaryBrand,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    LanguageProvider.tr('not_signed'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey.shade500 : Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      isDark: isDark,
      radius: 16,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      borderColor: color.withValues(alpha: isDark ? 0.35 : 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: isDark ? 0.35 : 0.2),
                  color.withValues(alpha: isDark ? 0.15 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

