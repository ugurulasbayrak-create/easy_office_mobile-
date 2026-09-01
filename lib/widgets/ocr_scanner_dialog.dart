import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/theme.dart';

class OcrScannerDialog extends StatefulWidget {
  final ValueChanged<String> onTextExtracted;

  const OcrScannerDialog({super.key, required this.onTextExtracted});

  @override
  State<OcrScannerDialog> createState() => _OcrScannerDialogState();
}

class _OcrScannerDialogState extends State<OcrScannerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  bool _isProcessing = true;
  String _extractedText = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Simulate AI OCR processing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _extractedText =
              'EASY OFFICE FATURA & HİZMET SÖZLEŞMESİ\n\nTarih: 31/08/2026\nMüşteri: Global Yazılım Ltd.\nToplam Tutar: 14.500,00 ₺\nÖdeme Durumu: Kredi Kartı ile Ödendi\n\nKullanım Şartları: Kamera OCR taraması ile düzenlenebilir formata dönüştürülmüştür.';
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt_rounded, color: OfficeTheme.sheetColor),
                const SizedBox(width: 8),
                Text(
                  LanguageProvider.tr('ocr_scanner'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scanner Viewport
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: OfficeTheme.sheetColor, width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Document Mock Background
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 8, width: 80, color: const Color(0xFF94A3B8)),
                        const SizedBox(height: 6),
                        Container(height: 6, width: 140, color: const Color(0xFFCBD5E1)),
                        const SizedBox(height: 4),
                        Container(height: 6, width: 120, color: const Color(0xFFCBD5E1)),
                        const Spacer(),
                        Container(height: 6, width: 100, color: const Color(0xFF107C41)),
                      ],
                    ),
                  ),

                  // Animated Green Laser Scanner Line
                  if (_isProcessing)
                    AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: 10 + (_scanLineAnimation.value * 160),
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  if (_isProcessing)
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              LanguageProvider.tr('extracting_text'),
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Extracted OCR text preview
            if (!_isProcessing) ...[
              Container(
                padding: const EdgeInsets.all(10),
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _extractedText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(LanguageProvider.tr('cancel')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: OfficeTheme.sheetColor,
                  ),
                  onPressed: _isProcessing
                      ? null
                      : () {
                          widget.onTextExtracted(_extractedText);
                          Navigator.of(context).pop();
                        },
                  icon: const Icon(Icons.note_add_rounded, size: 16),
                  label: Text(LanguageProvider.tr('create_doc_from_scan')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
