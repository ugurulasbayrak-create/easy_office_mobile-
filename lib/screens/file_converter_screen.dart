import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/conversion_engine.dart';
import '../core/localization.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../widgets/glass_background.dart';
import 'docs_editor_screen.dart';
import 'pdf_viewer_screen.dart';
import 'sheets_editor_screen.dart';
import 'slides_editor_screen.dart';

class SelectedConversionFile {
  final String filePath;
  final String fileName;
  final String fileSize;
  final File realFile;
  final bool isExternal;

  SelectedConversionFile({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.realFile,
    required this.isExternal,
  });
}

class FileConverterScreen extends StatefulWidget {
  const FileConverterScreen({super.key});

  @override
  State<FileConverterScreen> createState() => _FileConverterScreenState();
}

class _FileConverterScreenState extends State<FileConverterScreen> {
  int _selectedModeIdx = 0;
  bool _isConverting = false;
  double _conversionProgress = 0.0;
  String _conversionStepText = '';

  // AI Zenginleştirme Durumları
  bool _isAiEnhanceEnabled = true;
  bool _aiAutoSummary = true;
  bool _aiAutoFormulas = true;
  bool _aiTranslateTr = false;

  // Her mod için bağımsız dosya ve sonuç saklama haritası
  final Map<String, SelectedConversionFile> _filesByMode = {};
  final Map<String, ConversionResult> _resultsByMode = {};

  final List<Map<String, dynamic>> _convertModes = [
    {
      'id': 'pdf_to_sheet',
      'title': 'PDF ➔ Excel (XLSX)',
      'shortName': 'PDF ➔ Excel',
      'from': 'PDF Tablosu / Fatura (.pdf)',
      'to': 'Düzenlenebilir Excel (.xlsx)',
      'icon': Icons.table_view_rounded,
      'color': OfficeTheme.sheetColor,
      'extensions': ['pdf'],
      'fileType': FileType.custom,
      'targetType': DocumentType.sheet,
      'sourceType': DocumentType.pdf,
    },
    {
      'id': 'pdf_to_doc',
      'title': 'PDF ➔ Word (DOCX)',
      'shortName': 'PDF ➔ Word',
      'from': 'PDF Belgesi (.pdf)',
      'to': 'Düzenlenebilir Word (.docx)',
      'icon': Icons.description_rounded,
      'color': OfficeTheme.docColor,
      'extensions': ['pdf'],
      'fileType': FileType.custom,
      'targetType': DocumentType.doc,
      'sourceType': DocumentType.pdf,
    },
    {
      'id': 'doc_to_pdf',
      'title': 'Word (DOCX) ➔ PDF',
      'shortName': 'Word ➔ PDF',
      'from': 'Word (.docx, .doc, .txt, .md)',
      'to': 'Vektörel PDF (.pdf)',
      'icon': Icons.picture_as_pdf_rounded,
      'color': OfficeTheme.primaryBrand,
      'extensions': ['docx', 'doc', 'txt', 'rtf', 'md'],
      'fileType': FileType.custom,
      'targetType': DocumentType.pdf,
      'sourceType': DocumentType.doc,
    },
    {
      'id': 'sheet_to_pdf',
      'title': 'Excel (XLSX) ➔ PDF',
      'shortName': 'Excel ➔ PDF',
      'from': 'Excel Tablosu (.xlsx, .xls, .csv)',
      'to': 'Vektörel Tablo PDF (.pdf)',
      'icon': Icons.table_chart_rounded,
      'color': OfficeTheme.sheetColor,
      'extensions': ['xlsx', 'xls', 'csv'],
      'fileType': FileType.custom,
      'targetType': DocumentType.pdf,
      'sourceType': DocumentType.sheet,
    },
    {
      'id': 'sheet_to_csv',
      'title': 'Excel ➔ CSV Tablosu',
      'shortName': 'Excel ➔ CSV',
      'from': 'Excel (.xlsx, .xls)',
      'to': 'Virgülle Ayrılmış (.csv)',
      'icon': Icons.tune_rounded,
      'color': OfficeTheme.sheetColor,
      'extensions': ['xlsx', 'xls'],
      'fileType': FileType.custom,
      'targetType': DocumentType.doc,
      'sourceType': DocumentType.sheet,
    },
    {
      'id': 'csv_to_sheet',
      'title': 'CSV ➔ Excel (XLSX)',
      'shortName': 'CSV ➔ Excel',
      'from': 'CSV Metin Tablosu (.csv)',
      'to': 'Formüllü Excel (.xlsx)',
      'icon': Icons.grid_view_rounded,
      'color': OfficeTheme.sheetColor,
      'extensions': ['csv', 'txt'],
      'fileType': FileType.custom,
      'targetType': DocumentType.sheet,
      'sourceType': DocumentType.doc,
    },
    {
      'id': 'pdf_to_slide',
      'title': 'PDF ➔ PowerPoint (PPTX)',
      'shortName': 'PDF ➔ Sunum',
      'from': 'PDF Sayfaları (.pdf)',
      'to': 'PowerPoint Slaytları (.pptx)',
      'icon': Icons.co_present_rounded,
      'color': OfficeTheme.slideColor,
      'extensions': ['pdf'],
      'fileType': FileType.custom,
      'targetType': DocumentType.slide,
      'sourceType': DocumentType.pdf,
    },
    {
      'id': 'slide_to_pdf',
      'title': 'PowerPoint ➔ PDF',
      'shortName': 'Sunum ➔ PDF',
      'from': 'PowerPoint (.pptx, .ppt)',
      'to': 'Sunum PDF Kitapçığı (.pdf)',
      'icon': Icons.slideshow_rounded,
      'color': OfficeTheme.slideColor,
      'extensions': ['pptx', 'ppt'],
      'fileType': FileType.custom,
      'targetType': DocumentType.pdf,
      'sourceType': DocumentType.slide,
    },
    {
      'id': 'pdf_to_txt',
      'title': 'PDF ➔ Düz Metin (TXT)',
      'shortName': 'PDF ➔ Metin',
      'from': 'PDF (.pdf)',
      'to': 'Düz Metin (.txt)',
      'icon': Icons.text_snippet_rounded,
      'color': const Color(0xFF64748B),
      'extensions': ['pdf'],
      'fileType': FileType.custom,
      'targetType': DocumentType.doc,
      'sourceType': DocumentType.pdf,
    },
    {
      'id': 'img_to_pdf',
      'title': 'Fotoğraf / Tarama ➔ PDF',
      'shortName': 'Görsel ➔ PDF',
      'from': 'Fotoğraf / Belge (.jpg, .png)',
      'to': 'A4 PDF Evrak (.pdf)',
      'icon': Icons.add_photo_alternate_rounded,
      'color': OfficeTheme.pdfColor,
      'extensions': ['jpg', 'jpeg', 'png', 'webp'],
      'fileType': FileType.image,
      'targetType': DocumentType.pdf,
      'sourceType': DocumentType.doc,
    },
    {
      'id': 'pdf_compress',
      'title': 'PDF Boyut Küçültme (Sıkıştır)',
      'shortName': 'PDF Sıkıştır',
      'from': 'Büyük PDF Belgesi (.pdf)',
      'to': 'Hafifletilmiş PDF (.pdf)',
      'icon': Icons.compress_rounded,
      'color': const Color(0xFF0D9488),
      'extensions': ['pdf'],
      'fileType': FileType.custom,
      'targetType': DocumentType.pdf,
      'sourceType': DocumentType.pdf,
    },
  ];

  SelectedConversionFile? get _currentSelectedFile {
    final modeId = _convertModes[_selectedModeIdx]['id'] as String;
    return _filesByMode[modeId];
  }

  ConversionResult? get _currentResult {
    final modeId = _convertModes[_selectedModeIdx]['id'] as String;
    return _resultsByMode[modeId];
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickFromPhoneStorage() async {
    final mode = _convertModes[_selectedModeIdx];
    final modeId = mode['id'] as String;
    final exts = (mode['extensions'] as List<String>);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: mode['fileType'] as FileType,
        allowedExtensions: mode['fileType'] == FileType.custom ? exts : null,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final sizeBytes = await file.length();
        final sizeStr = _formatFileSize(sizeBytes);
        final name = result.files.single.name;

        setState(() {
          _filesByMode[modeId] = SelectedConversionFile(
            filePath: path,
            fileName: name,
            fileSize: sizeStr,
            realFile: file,
            isExternal: true,
          );
          _conversionProgress = 0.0;
          _resultsByMode.remove(modeId);
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya seçildi: $name ($sizeStr)'),
            backgroundColor: OfficeTheme.primaryBrand,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dosya seçilemedi: $e')),
      );
    }
  }

  Future<void> _pickFromCamera() async {
    final modeId = _convertModes[_selectedModeIdx]['id'] as String;
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final file = File(photo.path);
        final sizeBytes = await file.length();
        final sizeStr = _formatFileSize(sizeBytes);
        final name = 'Kamera_Tarama_${DateTime.now().millisecondsSinceEpoch}.jpg';

        setState(() {
          _filesByMode[modeId] = SelectedConversionFile(
            filePath: photo.path,
            fileName: name,
            fileSize: sizeStr,
            realFile: file,
            isExternal: true,
          );
          _conversionProgress = 0.0;
          _resultsByMode.remove(modeId);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamera açılamadı: $e')),
      );
    }
  }

  void _showInAppDocSelector() {
    final mode = _convertModes[_selectedModeIdx];
    final modeId = mode['id'] as String;
    final targetSourceType = mode['sourceType'] as DocumentType?;
    final docs = OfficeStorage().documents;

    final compatibleDocs = targetSourceType != null
        ? docs.where((d) => d.type == targetSourceType).toList()
        : docs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Easy Belgelerimden Seç (${mode['shortName']})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (compatibleDocs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Bu modla uyumlu (${mode['from']}) kayıtlı belge bulunamadı.\nTelefon hafızasından dosya seçebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: compatibleDocs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (c, i) {
                      final d = compatibleDocs[i];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: d.brandColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(d.icon, color: d.brandColor, size: 20),
                        ),
                        title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${d.typeLabel} • ${d.fileSizeKb} KB', style: const TextStyle(fontSize: 11)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () async {
                          final tempDir = await getTemporaryDirectory();
                          final ext = d.type == DocumentType.doc
                              ? 'docx'
                              : d.type == DocumentType.sheet
                                  ? 'xlsx'
                                  : d.type == DocumentType.slide
                                      ? 'pptx'
                                      : 'pdf';
                          final uniqueTime = DateTime.now().millisecondsSinceEpoch;
                          final tempFile = File('${tempDir.path}/${d.title}_$uniqueTime.$ext');

                          if (d.data is String) {
                            final srcPath = d.data as String;
                            final srcFile = File(srcPath);
                            if (await srcFile.exists()) {
                              await srcFile.copy(tempFile.path);
                            } else {
                              await tempFile.writeAsString(srcPath);
                            }
                          } else if (d.data is List<int>) {
                            await tempFile.writeAsBytes(d.data as List<int>);
                          } else {
                            await tempFile.writeAsString(d.previewContent);
                          }

                          setState(() {
                            _filesByMode[modeId] = SelectedConversionFile(
                              filePath: tempFile.path,
                              fileName: '${d.title}.$ext',
                              fileSize: '${d.fileSizeKb} KB',
                              realFile: tempFile,
                              isExternal: false,
                            );
                            _conversionProgress = 0.0;
                            _resultsByMode.remove(modeId);
                          });

                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startConversion() async {
    final selected = _currentSelectedFile;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce dönüştürülecek bir dosya seçin!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isConverting = true;
      _conversionProgress = 0.15;
      _conversionStepText = 'Kaynak dosya baytları analiz ediliyor...';
    });

    final mode = _convertModes[_selectedModeIdx];
    final modeId = mode['id'] as String;

    try {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _conversionProgress = 0.50;
        _conversionStepText = 'İçerik, tablolar ve vektör sayfalar işleniyor...';
      });

      ConversionResult result;
      switch (modeId) {
        case 'pdf_to_sheet':
          result = await RealConversionEngine.convertPdfToExcel(selected.realFile);
          break;
        case 'pdf_to_doc':
          result = await RealConversionEngine.convertPdfToWord(selected.realFile);
          break;
        case 'doc_to_pdf':
          result = await RealConversionEngine.convertWordToPdf(selected.realFile);
          break;
        case 'sheet_to_pdf':
          result = await RealConversionEngine.convertExcelToPdf(selected.realFile);
          break;
        case 'sheet_to_csv':
          result = await RealConversionEngine.convertSheetToCsv(selected.realFile);
          break;
        case 'csv_to_sheet':
          result = await RealConversionEngine.convertCsvToSheet(selected.realFile);
          break;
        case 'pdf_to_slide':
          result = await RealConversionEngine.convertPdfToSlides(selected.realFile);
          break;
        case 'slide_to_pdf':
          result = await RealConversionEngine.convertPptxToSlides(selected.realFile);
          break;
        case 'pdf_to_txt':
          result = await RealConversionEngine.convertToPlainText(selected.realFile);
          break;
        case 'img_to_pdf':
          result = await RealConversionEngine.convertImageToPdf(selected.realFile);
          break;
        case 'pdf_compress':
          result = await RealConversionEngine.compressPdf(selected.realFile);
          break;
        default:
          result = await RealConversionEngine.convertWordToPdf(selected.realFile);
          break;
      }

      if (!result.success) {
        throw Exception(result.message);
      }

      // AI Akıllı Analiz ve Zenginleştirme Adımı
      if (_isAiEnhanceEnabled) {
        if (!mounted) return;
        setState(() {
          _conversionProgress = 0.85;
          _conversionStepText = '🤖 Easy AI belgeyi analiz ediyor, özet ve formülleri optimize ediyor...';
        });

        result = await RealConversionEngine.enhanceWithAi(
          result,
          summarize: _aiAutoSummary,
          autoFormulas: _aiAutoFormulas,
          translateToTr: _aiTranslateTr,
        );
      }

      if (result.convertedDocument != null) {
        OfficeStorage().addDocument(result.convertedDocument!);
      }

      if (!mounted) return;
      setState(() {
        _isConverting = false;
        _conversionProgress = 1.0;
        _conversionStepText = _isAiEnhanceEnabled
            ? '✨ AI destekli akıllı dönüştürme tamamlandı!'
            : 'Dönüştürme başarıyla tamamlandı!';
        _resultsByMode[modeId] = result;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: OfficeTheme.sheetColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConverting = false;
        _conversionProgress = 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dönüştürme başarısız oldu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openConvertedFile() {
    final res = _currentResult;
    if (res?.convertedDocument == null) return;
    final doc = res!.convertedDocument!;

    if (doc.type == DocumentType.doc) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => DocsEditorScreen(document: doc)));
    } else if (doc.type == DocumentType.sheet) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SheetsEditorScreen(document: doc)));
    } else if (doc.type == DocumentType.slide) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => SlidesEditorScreen(document: doc)));
    } else {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfViewerScreen(document: doc)));
    }
  }

  Future<void> _shareConvertedFile() async {
    final res = _currentResult;
    final selected = _currentSelectedFile;
    if (res?.outputFilePath != null) {
      final file = File(res!.outputFilePath!);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Easy Office ile dönüştürülmüş belge: ${selected?.fileName ?? "Belge"}',
        );
      }
    } else if (res?.extractedRawText != null) {
      await Share.share(res!.extractedRawText!);
    }
  }

  void _removeSelectedFile() {
    final modeId = _convertModes[_selectedModeIdx]['id'] as String;
    setState(() {
      _filesByMode.remove(modeId);
      _resultsByMode.remove(modeId);
      _conversionProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mode = _convertModes[_selectedModeIdx];
    final modeColor = mode['color'] as Color;
    final selectedFile = _currentSelectedFile;
    final result = _currentResult;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: OfficeTheme.brandGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: OfficeTheme.primaryBrand.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.sync_alt_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              LanguageProvider.tr('nav_converter'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
      ),
      body: GlassBackground(
        isDark: isDark,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mod Seçici Başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dönüştürme Formatı Seçin',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${_selectedModeIdx + 1} / ${_convertModes.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Yatay Kaydırılabilir Cam Format Kartları
              SizedBox(
                height: 98,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _convertModes.length,
                  itemBuilder: (ctx, idx) {
                    final item = _convertModes[idx];
                    final isSelected = _selectedModeIdx == idx;
                    final color = item['color'] as Color;
                    final itemId = item['id'] as String;
                    final hasFile = _filesByMode.containsKey(itemId);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedModeIdx = idx;
                          _conversionProgress = _resultsByMode.containsKey(itemId) ? 1.0 : 0.0;
                        });
                      },
                      child: Container(
                        width: 155,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: isDark ? 0.28 : 0.14)
                              : (isDark
                                  ? const Color(0xFF131D33).withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.8)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : (isDark ? Colors.cyanAccent.withValues(alpha: 0.15) : const Color(0xFFE2E8F0)),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(item['icon'] as IconData, color: color, size: 22),
                                if (hasFile)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: isSelected ? color : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // Aktif Mod Cam Kartı
              GlassCard(
                isDark: isDark,
                radius: 18,
                padding: const EdgeInsets.all(16),
                fillColor: modeColor.withValues(alpha: isDark ? 0.22 : 0.12),
                borderColor: modeColor.withValues(alpha: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            mode['title'] as String,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: modeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'MOTOR HAZIR',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Giriş: ${mode['from']}\nÇıkış: ${mode['to']}',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 🤖 YAPAY ZEKA (EASY AI) AKILLI SEÇENEKLER KARTI
              GlassCard(
                isDark: isDark,
                radius: 18,
                padding: const EdgeInsets.all(16),
                borderColor: _isAiEnhanceEnabled ? OfficeTheme.cyanGlow.withValues(alpha: 0.5) : null,
                fillColor: _isAiEnhanceEnabled
                    ? (isDark ? const Color(0xFF0284C7).withValues(alpha: 0.18) : const Color(0xFF0284C7).withValues(alpha: 0.08))
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [OfficeTheme.aiGradientStart, OfficeTheme.aiGradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: OfficeTheme.aiColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Easy AI Akıllı Dönüştürücü',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                              Text(
                                'Özet çıkarma, formül onarımı ve terminoloji analizi',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _isAiEnhanceEnabled,
                          activeThumbColor: OfficeTheme.cyanGlow,
                          onChanged: (val) => setState(() => _isAiEnhanceEnabled = val),
                        ),
                      ],
                    ),
                    if (_isAiEnhanceEnabled) ...[
                      const Divider(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('📝 Yönetici Özeti Çıkar', style: TextStyle(fontSize: 11)),
                            selected: _aiAutoSummary,
                            selectedColor: OfficeTheme.cyanGlow.withValues(alpha: isDark ? 0.35 : 0.2),
                            onSelected: (val) => setState(() => _aiAutoSummary = val),
                          ),
                          FilterChip(
                            label: const Text('📊 Tablo & Formülleri Onar', style: TextStyle(fontSize: 11)),
                            selected: _aiAutoFormulas,
                            selectedColor: OfficeTheme.sheetColor.withValues(alpha: isDark ? 0.35 : 0.2),
                            onSelected: (val) => setState(() => _aiAutoFormulas = val),
                          ),
                          FilterChip(
                            label: const Text('🌐 Türkçe Uyarlama', style: TextStyle(fontSize: 11)),
                            selected: _aiTranslateTr,
                            selectedColor: OfficeTheme.aiColor.withValues(alpha: isDark ? 0.35 : 0.2),
                            onSelected: (val) => setState(() => _aiTranslateTr = val),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Kaynak Dosya Seçim Kutusu
              GlassCard(
                isDark: isDark,
                radius: 18,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bu Dönüştürme İçin Dosya',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (selectedFile != null)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _removeSelectedFile,
                            child: const Text(
                              'Dosyayı Kaldır',
                              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Dosya Seçim Butonları
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: OfficeTheme.primaryBrand.withValues(alpha: isDark ? 0.3 : 0.12),
                              foregroundColor: isDark ? OfficeTheme.cyanGlow : OfficeTheme.primaryBrand,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _pickFromPhoneStorage,
                            icon: const Icon(Icons.folder_rounded, size: 18),
                            label: const Text(
                              'Telefon Hafızası',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(
                                color: isDark ? Colors.cyanAccent.withValues(alpha: 0.25) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            onPressed: _showInAppDocSelector,
                            icon: const Icon(Icons.history_edu_rounded, size: 18),
                            label: const Text(
                              'Easy Belgeler',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: OfficeTheme.sheetColor.withValues(alpha: isDark ? 0.3 : 0.15),
                            foregroundColor: OfficeTheme.sheetColor,
                          ),
                          onPressed: _pickFromCamera,
                          icon: const Icon(Icons.camera_alt_rounded),
                          tooltip: 'Kamera',
                        ),
                      ],
                    ),

                    // Seçili Dosya Kartı
                    if (selectedFile != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: modeColor.withValues(alpha: isDark ? 0.18 : 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: modeColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: modeColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                selectedFile.isExternal ? Icons.snippet_folder_rounded : Icons.article_rounded,
                                color: modeColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedFile.fileName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${selectedFile.fileSize} • Hazır',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                              onPressed: _removeSelectedFile,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF101B30).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.cyanAccent.withValues(alpha: 0.15) : const Color(0xFFE2E8F0),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 32,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bu mod için henüz bir dosya seçilmedi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Desteklenen: ${(mode['extensions'] as List<String>).join(', ').toUpperCase()}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Dönüştürme İşlemi ve Sonuç
              if (_isConverting) ...[
                GlassCard(
                  isDark: isDark,
                  radius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _conversionStepText,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Text(
                            '%${(_conversionProgress * 100).toInt()}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: modeColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _conversionProgress,
                          minHeight: 8,
                          color: modeColor,
                          backgroundColor: modeColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (result != null && result.success) ...[
                // Ana Sonuç Kartı
                GlassCard(
                  isDark: isDark,
                  radius: 18,
                  padding: const EdgeInsets.all(18),
                  borderColor: OfficeTheme.sheetColor.withValues(alpha: 0.6),
                  fillColor: OfficeTheme.sheetColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: OfficeTheme.sheetColor, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Dönüştürme Başarıyla Tamamlandı!',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: OfficeTheme.sheetColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: OfficeTheme.sheetColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _openConvertedFile,
                              icon: const Icon(Icons.open_in_new_rounded, size: 16),
                              label: const Text('Belgeyi Aç'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              backgroundColor: OfficeTheme.primaryBrand.withValues(alpha: 0.2),
                              foregroundColor: OfficeTheme.cyanGlow,
                            ),
                            onPressed: _shareConvertedFile,
                            icon: const Icon(Icons.share_rounded, size: 18),
                            tooltip: 'Paylaş',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 🤖 EASY AI AKILLI ANALİZ & ÖZET RAPORU KARTI
                if (result.isAiEnhanced) ...[
                  const SizedBox(height: 14),
                  GlassCard(
                    isDark: isDark,
                    radius: 18,
                    padding: const EdgeInsets.all(16),
                    borderColor: OfficeTheme.cyanGlow.withValues(alpha: 0.6),
                    fillColor: isDark ? const Color(0xFF0F1E38).withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.85),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [OfficeTheme.aiGradientStart, OfficeTheme.aiGradientEnd],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Easy AI Analiz & Özet',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                ),
                              ],
                            ),
                            if (result.aiDetectedCategory != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: OfficeTheme.primaryBrand.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: OfficeTheme.cyanGlow.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  result.aiDetectedCategory!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: OfficeTheme.cyanGlow,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (result.aiSummary != null && result.aiSummary!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              result.aiSummary!,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                        if (result.aiKeyInsights != null && result.aiKeyInsights!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ...result.aiKeyInsights!.map((insight) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  insight,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.4,
                                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                  ),
                                ),
                              )),
                        ],
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onPressed: () {
                              final textToCopy = '${result.aiSummary ?? ""}\n\n${result.aiKeyInsights?.join("\n") ?? ""}';
                              Clipboard.setData(ClipboardData(text: textToCopy));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('AI Özeti panoya kopyalandı!')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 14),
                            label: const Text('Özeti Kopyala', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [modeColor, modeColor.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: modeColor.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: selectedFile != null ? _startConversion : null,
                    icon: const Icon(Icons.bolt_rounded, size: 20, color: Colors.white),
                    label: Text(
                      selectedFile != null
                          ? '${mode['shortName']} Dönüştürmeyi Başlat'
                          : 'Önce Dosya Seçin',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
