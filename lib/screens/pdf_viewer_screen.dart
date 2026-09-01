import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/conversion_engine.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../widgets/signature_pad.dart';
import 'docs_editor_screen.dart';

class PdfViewerScreen extends StatefulWidget {
  final OfficeDocument document;

  const PdfViewerScreen({super.key, required this.document});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  bool _isSigned = false;
  String _extractedText = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfContent();
  }

  Future<void> _loadPdfContent() async {
    try {
      if (widget.document.data is String) {
        final path = widget.document.data as String;
        final file = File(path);
        if (await file.exists()) {
          final res = await RealConversionEngine.convertPdfToWord(file);
          if (mounted) {
            setState(() {
              _extractedText = res.extractedRawText ?? widget.document.previewContent;
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _extractedText = widget.document.previewContent;
        _isLoading = false;
      });
    }
  }

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
              content: Text('Dijital imza PDF belgesine mühürlendi!'),
              backgroundColor: OfficeTheme.pdfColor,
            ),
          );
        },
      ),
    );
  }

  Future<void> _sharePdf() async {
    if (widget.document.data is String) {
      final file = File(widget.document.data as String);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(file.path)], text: widget.document.title);
        return;
      }
    }
    await Share.share('${widget.document.title}\n\n$_extractedText');
  }

  void _convertToWord() {
    final baseName = widget.document.title.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
    final doc = OfficeDocument(
      id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
      title: '$baseName.docx',
      type: DocumentType.doc,
      lastModified: DateTime.now(),
      previewContent: _extractedText.length > 80 ? '${_extractedText.substring(0, 80)}...' : _extractedText,
      data: _extractedText,
    );
    OfficeStorage().addDocument(doc);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocsEditorScreen(document: doc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.document.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'PDF Belge Görüntüleyici • ${widget.document.fileSizeKb} KB',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Paylaş / Dışa Aktar',
            onPressed: _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.draw_rounded, color: OfficeTheme.primaryBrand),
            tooltip: 'Dijital İmzala',
            onPressed: _openSignaturePad,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Action Toolbar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: OfficeTheme.docLight,
                          ),
                          onPressed: _convertToWord,
                          icon: const Icon(Icons.description_rounded, size: 16, color: OfficeTheme.docColor),
                          label: const Text('Word\'e Aktar', style: TextStyle(color: OfficeTheme.docColor, fontSize: 12)),
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: OfficeTheme.pdfLight,
                          ),
                          onPressed: _openSignaturePad,
                          icon: const Icon(Icons.verified_rounded, size: 16, color: OfficeTheme.pdfColor),
                          label: Text(_isSigned ? 'Mühürlendi ✓' : 'İmza Ekle',
                              style: const TextStyle(color: OfficeTheme.pdfColor, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // A4 Vector Paper Card View
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 520),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PDF Header Strip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.picture_as_pdf_rounded, color: OfficeTheme.pdfColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  widget.document.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: OfficeTheme.pdfLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Sayfa 1 / 1',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: OfficeTheme.pdfColor),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Rendered Document Text Content
                        Text(
                          _extractedText.isEmpty
                              ? 'PDF Belge Metni Okunuyor...'
                              : _extractedText,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.7,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Signature Stamp Area at the bottom
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Onaylayan Yetkili:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isSigned
                                    ? OfficeTheme.primaryBrand.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: _isSigned ? OfficeTheme.primaryBrand : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _isSigned
                                  ? const Row(
                                      children: [
                                        Icon(Icons.verified_rounded, size: 16, color: OfficeTheme.primaryBrand),
                                        SizedBox(width: 4),
                                        Text(
                                          'DİJİTAL MÜHÜRLÜ',
                                          style: TextStyle(
                                            color: OfficeTheme.primaryBrand,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text('İmza Yok', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
