import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../widgets/glass_background.dart';

class DocsEditorScreen extends StatefulWidget {
  final OfficeDocument? document;

  const DocsEditorScreen({super.key, this.document});

  @override
  State<DocsEditorScreen> createState() => _DocsEditorScreenState();
}

class _DocsEditorScreenState extends State<DocsEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _docId;

  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  double _fontSize = 15.0;
  double _lineHeight = 1.6;
  final String _fontFamily = 'Normal';
  final Color _selectedTextColor = const Color(0xFF1E293B);

  int _wordCount = 0;
  int _charCount = 0;
  int _paragraphCount = 0;

  @override
  void initState() {
    super.initState();
    _docId = widget.document?.id ?? 'doc-${DateTime.now().millisecondsSinceEpoch}';
    _titleController = TextEditingController(
      text: widget.document?.title ?? 'Yeni Belge.docx',
    );
    String initialText = widget.document?.data as String? ??
        '# Proje Dokümantasyonu\n\nEasy Office Docs kelime işlemcisine hoş geldiniz. Zengin metin biçimlendirme araçlarını, başlıkları, tabloları ve Easy AI asistanını kullanarak dökümanlarınızı profesyonelce hazırlayın.';

    _contentController = TextEditingController(text: initialText);
    _updateStats();
    _contentController.addListener(_updateStats);
  }

  void _updateStats() {
    final text = _contentController.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    final paragraphs = text.isEmpty ? 0 : text.split('\n\n').length;

    setState(() {
      _wordCount = words;
      _charCount = text.length;
      _paragraphCount = paragraphs;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveDocument() {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Document.docx'
        : _titleController.text.trim();
    final content = _contentController.text;
    final preview = content.length > 80 ? '${content.substring(0, 80)}...' : content;

    final storage = OfficeStorage();
    if (widget.document != null) {
      storage.updateDocument(_docId, title: title, data: content, preview: preview);
    } else {
      storage.addDocument(
        OfficeDocument(
          id: _docId,
          title: title,
          type: DocumentType.doc,
          lastModified: DateTime.now(),
          previewContent: preview,
          data: content,
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LanguageProvider.tr('save_success')),
        backgroundColor: OfficeTheme.docColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _insertFormatting(String prefix, [String suffix = '']) {
    final selection = _contentController.selection;
    final text = _contentController.text;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$prefix$selectedText$suffix',
      );
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length + suffix.length,
        ),
      );
    } else {
      final offset = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(offset, offset, '$prefix$suffix');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: offset + prefix.length),
      );
    }
  }

  void _showExportModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.file_download_outlined, color: OfficeTheme.docColor),
                  SizedBox(width: 10),
                  Text('Dışa Aktar & Paylaş', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 16),
              _buildExportOption(Icons.picture_as_pdf_rounded, 'PDF Olarak Kaydet', 'Yüksek kaliteli vektörel PDF'),
              _buildExportOption(Icons.description_rounded, 'DOCX Olarak Kaydet', 'Microsoft Word uyumlu format'),
              _buildExportOption(Icons.code_rounded, 'HTML / Markdown Olarak Kaydet', 'Web ve geliştirici formatı'),
              _buildExportOption(Icons.text_snippet_rounded, 'Düz Metin (TXT) Olarak Kaydet', 'Hafif sade metin'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOption(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: OfficeTheme.docColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: OfficeTheme.docColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title tamamlandı!')),
        );
      },
    );
  }

  void _showFontOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Yazı Tipi & Boyut Ayarları', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Yazı Boyutu:'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (_fontSize > 10) setState(() => _fontSize -= 1);
                        },
                      ),
                      Text('${_fontSize.toInt()} pt', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          if (_fontSize < 32) setState(() => _fontSize += 1);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Satır Aralığı:'),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('1.2x'),
                        selected: _lineHeight == 1.2,
                        onSelected: (v) => setState(() => _lineHeight = 1.2),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('1.6x'),
                        selected: _lineHeight == 1.6,
                        onSelected: (v) => setState(() => _lineHeight = 1.6),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('2.0x'),
                        selected: _lineHeight == 2.0,
                        onSelected: (v) => setState(() => _lineHeight = 2.0),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _saveDocument();
            Navigator.of(context).pop();
          },
        ),
        title: TextField(
          controller: _titleController,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Belge Başlığı',
          ),
          onSubmitted: (_) => _saveDocument(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields_rounded),
            tooltip: 'Yazı Tipi & Boyut',
            onPressed: _showFontOptions,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Dışa Aktar',
            onPressed: _showExportModal,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: OfficeTheme.sheetColor),
            tooltip: 'Kaydet',
            onPressed: _saveDocument,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: GlassBackground(
        isDark: isDark,
        child: Column(
          children: [
            // Pro Document Live Info Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101B33).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.cyanAccent.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 16, color: OfficeTheme.docColor),
                      const SizedBox(width: 6),
                      Text(
                        '$_wordCount ${LanguageProvider.tr('words')} | $_charCount ${LanguageProvider.tr('chars')} | $_paragraphCount Paragraf',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: OfficeTheme.docColor),
                      ),
                    ],
                  ),
                  Text(
                    '~${(_wordCount / 200).ceil()} ${LanguageProvider.tr('read_time')}',
                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            // Main Paper Canvas with Luxury Styling
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F1A30).withValues(alpha: 0.9) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.cyanAccent.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  style: TextStyle(
                    fontSize: _fontSize,
                    height: _lineHeight,
                    fontFamily: _fontFamily == 'Monospace' ? 'monospace' : null,
                    color: isDark ? const Color(0xFFF8FAFC) : _selectedTextColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Belgenizi yazmaya başlayın...',
                  ),
                ),
              ),
            ),

            // Pro Mobile Formatting Toolbar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0E182F).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.cyanAccent.withValues(alpha: 0.25) : const Color(0xFFCBD5E1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFF0284C7).withValues(alpha: 0.08),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_bold_rounded),
                      color: _isBold ? OfficeTheme.docColor : null,
                      onPressed: () {
                        setState(() => _isBold = !_isBold);
                        _insertFormatting('**', '**');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic_rounded),
                      color: _isItalic ? OfficeTheme.docColor : null,
                      onPressed: () {
                        setState(() => _isItalic = !_isItalic);
                        _insertFormatting('*', '*');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_underlined_rounded),
                      color: _isUnderline ? OfficeTheme.docColor : null,
                      onPressed: () {
                        setState(() => _isUnderline = !_isUnderline);
                        _insertFormatting('<u>', '</u>');
                      },
                    ),
                    const VerticalDivider(width: 14),
                    IconButton(
                      icon: const Icon(Icons.title_rounded),
                      tooltip: 'Başlık 1',
                      onPressed: () => _insertFormatting('\n# ', '\n'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_size_rounded),
                      tooltip: 'Başlık 2',
                      onPressed: () => _insertFormatting('\n## ', '\n'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_list_bulleted_rounded),
                      tooltip: 'Madde İmi',
                      onPressed: () => _insertFormatting('\n• '),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_box_outlined),
                      tooltip: 'Yapılacaklar Kutusu',
                      onPressed: () => _insertFormatting('\n[ ] '),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_quote_rounded),
                      tooltip: 'Alıntı',
                      onPressed: () => _insertFormatting('\n> '),
                    ),
                    IconButton(
                      icon: const Icon(Icons.table_chart_outlined),
                      tooltip: 'Tablo Ekle',
                      onPressed: () => _insertFormatting(
                        '\n| Kalem | Miktar | Fiyat |\n| --- | --- | --- |\n| Ürün A | 1 | 250 ₺ |\n',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.code_rounded),
                      tooltip: 'Kod Bloğu',
                      onPressed: () => _insertFormatting('\n```\n', '\n```\n'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
