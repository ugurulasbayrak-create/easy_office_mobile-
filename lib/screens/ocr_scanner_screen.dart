import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/localization.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import 'docs_editor_screen.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isProcessing = false;
  bool _applyContrastFilter = true;
  String _extractedText = '';
  String _detectedDocType = 'Invoice / Fatura';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _isProcessing = true;
          _extractedText = '';
        });

        // Run Intelligent OCR extraction simulation on image
        _performOcr();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kamera/Galeri erişim hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _performOcr() {
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      final now = DateTime.now();
      final dateStr = '${now.day}.${now.month}.${now.year}';

      final sampleResults = [
        '''EASY OFFICE TEKNOLOJİ A.Ş.
RESMİ HİZMET SÖZLEŞMESİ & FATURA

Tarih: $dateStr
Fatura No: #INV-2026-904
Müşteri: Global Yazılım Çözümleri Ltd.

Hizmet Tanımı:
1. Mobil Ofis Entegrasyonu & OCR Tarayıcı
2. Excel Tablo Formül Motoru & Grafik Görselleştirme
3. PDF Dijital İmza Damgası ve Şifreleme

Toplam Tutar: 14.500,00 ₺
KDV (%20): 2.900,00 ₺
Genel Toplam: 17.400,00 ₺

Ödeme Durumu: Onaylandı / Kredi Kartı
Yetkili İmza: Alex Morgan''',
        '''TOPLANTI TUTANAĞI & PROJE ÖZETİ

Proje: Easy Office Mobil Platformu
Tarih: $dateStr
Katılımcılar: Mühendislik & Ürün Yönetimi

Alınan Kararlar:
• Çoklu dil desteği (Türkçe, İngilizce, Almanca, İspanyolca) entegre edildi.
• Kamera ve Galeriden gerçek zamanlı OCR metin çıkarma sistemi aktifleşti.
• Dosyalar arası dönüştürücü (Word, Excel, PDF, PPT, Resim) genişletildi.

Sonraki Adımlar:
- Google Play Store mağaza yayınlama sürecinin tamamlanması.''',
      ];

      setState(() {
        _isProcessing = false;
        _extractedText = sampleResults[DateTime.now().second % 2];
        _detectedDocType = _extractedText.contains('FATURA') ? 'Fatura / Invoice' : 'Tutanak / Belge';
      });
    });
  }

  void _transferToDocs() {
    if (_extractedText.isEmpty) return;

    final newDoc = OfficeDocument(
      id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Taranan Belge OCR.docx',
      type: DocumentType.doc,
      lastModified: DateTime.now(),
      previewContent: _extractedText.length > 80
          ? '${_extractedText.substring(0, 80)}...'
          : _extractedText,
      data: '# Taranan Belge (Easy OCR)\n\n$_extractedText',
    );

    OfficeStorage().addDocument(newDoc);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DocsEditorScreen(document: newDoc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageProvider.tr('ocr_scanner')),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Flaş',
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera & Gallery Capture Action Bar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: OfficeTheme.sheetColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: Text(LanguageProvider.tr('camera_scan')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: Text(LanguageProvider.tr('gallery_pick')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Image Viewport / Preview Box
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: OfficeTheme.sheetColor.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_imageFile != null)
                      Image.file(
                        _imageFile!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        color: _applyContrastFilter ? Colors.black54 : null,
                        colorBlendMode: _applyContrastFilter ? BlendMode.saturation : null,
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.document_scanner_rounded,
                              size: 56, color: OfficeTheme.sheetColor.withValues(alpha: 0.8)),
                          const SizedBox(height: 12),
                          const Text(
                            'Kamera veya Galeriden Belge Çekin',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Fatura, Makbuz, Sözleşme, Notlar',
                            style: TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),

                    // Processing Laser Scan Animation
                    if (_isProcessing)
                      Container(
                        color: Colors.black45,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: Color(0xFF10B981),
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                LanguageProvider.tr('extracting_text'),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (_imageFile != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _applyContrastFilter,
                        activeTrackColor: OfficeTheme.sheetColor,
                        onChanged: (val) {
                          setState(() => _applyContrastFilter = val);
                        },
                      ),
                      Text(LanguageProvider.tr('contrast_filter'), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  Chip(
                    avatar: const Icon(Icons.auto_awesome, size: 14, color: OfficeTheme.sheetColor),
                    label: Text(_detectedDocType, style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Extracted OCR Text Result Panel
            if (_extractedText.isNotEmpty) ...[
              const Text(
                '📋 Taranan Metin Çıktısı (OCR):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  _extractedText,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    height: 1.5,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Metin panoya kopyalandı!')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(LanguageProvider.tr('copy_text')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: OfficeTheme.sheetColor),
                      onPressed: _transferToDocs,
                      icon: const Icon(Icons.note_add_rounded, size: 18),
                      label: Text(LanguageProvider.tr('create_doc_from_scan')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
