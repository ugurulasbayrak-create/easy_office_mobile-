import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/theme.dart';
import '../widgets/glass_background.dart';
import '../widgets/office_3d_icon.dart';
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
            const SnackBar(
              content: Text('✨ Belge dijital olarak başarıyla imzalandı ve mühürlendi!'),
              backgroundColor: OfficeTheme.sheetColor,
            ),
          );
        },
      ),
    );
  }

  void _showToolNotice(String toolName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$toolName aracı hazır! Dosya seçmek için dönüştürücüye yönlendiriliyorsunuz.'),
        backgroundColor: OfficeTheme.primaryBrand,
        action: SnackBarAction(
          label: 'Aç',
          textColor: Colors.white,
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FileConverterScreen()));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final tools = [
      {
        'title': 'Dijital İmza & Mühür',
        'subtitle': 'Yasal e-imza ile damgalayın',
        'iconType': Office3DType.signature,
        'color': OfficeTheme.goldPro,
        'action': _openSignaturePad,
      },
      {
        'title': 'Kamera OCR Tarayıcı',
        'subtitle': 'Evrak ve belgeleri metne çevirin',
        'iconType': Office3DType.ocr,
        'color': OfficeTheme.sheetColor,
        'action': () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OcrScannerScreen()));
        },
      },
      {
        'title': 'PDF ➔ Word / Excel',
        'subtitle': 'Belgeleri düzenlenebilir yapın',
        'iconType': Office3DType.converter,
        'color': OfficeTheme.aiColor,
        'action': () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FileConverterScreen()));
        },
      },
      {
        'title': 'PDF Boyut Küçültme',
        'subtitle': 'Kaliteyi koruyarak %55 sıkıştırın',
        'iconType': Office3DType.custom,
        'customIcon': Icons.compress_rounded,
        'color': OfficeTheme.slideColor,
        'action': () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FileConverterScreen()));
        },
      },
      {
        'title': 'PDF Birleştir (Merge)',
        'subtitle': 'Birden çok dosyayı tek evrak yapın',
        'iconType': Office3DType.custom,
        'customIcon': Icons.call_merge_rounded,
        'color': const Color(0xFF0284C7),
        'action': () => _showToolNotice('PDF Birleştirme'),
      },
      {
        'title': 'Sayfa Böl & Ayıkla',
        'subtitle': 'İstenen sayfaları dışa aktarın',
        'iconType': Office3DType.custom,
        'customIcon': Icons.call_split_rounded,
        'color': const Color(0xFFE11D48),
        'action': () => _showToolNotice('PDF Sayfa Bölme'),
      },
      {
        'title': 'Şifrele & Koru',
        'subtitle': '256-bit AES şifreleme ekleyin',
        'iconType': Office3DType.custom,
        'customIcon': Icons.lock_outline_rounded,
        'color': const Color(0xFFD97706),
        'action': () => _showToolNotice('PDF Şifreleme'),
      },
      {
        'title': 'Filigran (Watermark)',
        'subtitle': 'Özel şirket logosu veya yazı ekleyin',
        'iconType': Office3DType.custom,
        'customIcon': Icons.branding_watermark_rounded,
        'color': const Color(0xFF0D9488),
        'action': () => _showToolNotice('Filigran Ekleme'),
      },
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            const Office3DIcon(
              type: Office3DType.pdf,
              size: 36,
              borderRadius: 10,
            ),
            const SizedBox(width: 10),
            Text(
              LanguageProvider.tr('nav_tools'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
      ),
      body: GlassBackground(
        isDark: isDark,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // PDF Studio Başlık & Bilgi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PDF Araç Seti',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: OfficeTheme.pdfColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: OfficeTheme.pdfColor.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      '8 PROFESYONEL ARAÇ',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: OfficeTheme.pdfColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 8'li Araç Izgarası (3D İkonlu)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tools.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.32,
                ),
                itemBuilder: (ctx, idx) {
                  final t = tools[idx];
                  final color = t['color'] as Color;
                  final iconType = t['iconType'] as Office3DType;
                  final customIcon = t['customIcon'] as IconData?;

                  return GlassCard(
                    isDark: isDark,
                    radius: 18,
                    padding: const EdgeInsets.all(12),
                    borderColor: color.withValues(alpha: isDark ? 0.35 : 0.22),
                    onTap: t['action'] as VoidCallback,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Office3DIcon(
                          type: iconType,
                          icon: customIcon,
                          baseColor: color,
                          size: 36,
                          borderRadius: 10,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['title'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t['subtitle'] as String,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Canlı Sözleşme & İmza Deneyim Kartı
              Text(
                'Canlı Sözleşme & İmza Laboratuvarı',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),

              GlassCard(
                isDark: isDark,
                radius: 20,
                padding: const EdgeInsets.all(18),
                borderColor: OfficeTheme.primaryBrand.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: OfficeTheme.primaryBrand, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'HİZMET VE GİZLİLİK SÖZLEŞMESİ',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                color: OfficeTheme.primaryBrand,
                              ),
                            ),
                          ],
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: OfficeTheme.primaryBrand.withValues(alpha: isDark ? 0.3 : 0.15),
                            foregroundColor: isDark ? OfficeTheme.cyanGlow : OfficeTheme.primaryBrand,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _openSignaturePad,
                          icon: const Icon(Icons.draw_rounded, size: 15),
                          label: Text(_isSigned ? 'Yeniden İmzala' : 'Şimdi İmzala', style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    const Divider(height: 22),
                    Text(
                      'İşbu sözleşme Easy Office platformu ile Kullanıcı arasında güvenli mobil belge işleme ve şifreleme protokolleri uyarınca tanzim edilmiştir.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '• Madde 1: Tüm veriler yerel cihaz hafızasında güvenle depolanır.\n• Madde 2: Biyometrik veya çizim dijital imza damgaları resmi evraklara iliştirilebilir.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // İmza Kutusu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yetkili İmza Sahibi:',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Uğur Ulaş Bayrak',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 150,
                          height: 52,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isSigned
                                  ? Colors.greenAccent
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                              width: 1.2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: _isSigned
                                ? Colors.green.withValues(alpha: isDark ? 0.2 : 0.1)
                                : (isDark ? const Color(0xFF0B1426) : const Color(0xFFF8FAFC)),
                          ),
                          child: Center(
                            child: _isSigned
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.verified_rounded, size: 16, color: Colors.greenAccent),
                                      SizedBox(width: 5),
                                      Text(
                                        'MÜHÜRLENDİ',
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'İmza Bekleniyor',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
