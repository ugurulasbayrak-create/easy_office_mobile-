import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../widgets/document_card.dart';
import '../widgets/glass_background.dart';
import 'docs_editor_screen.dart';
import 'file_converter_screen.dart';
import 'ocr_scanner_screen.dart';
import 'pdf_viewer_screen.dart';
import 'sheets_editor_screen.dart';
import 'slides_editor_screen.dart';
import 'templates_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilterIdx = 0; // 0: All, 1: DOC, 2: XLS, 3: PPT, 4: PDF, 5: Favorites

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _createNewDoc(BuildContext context) {
    final newDoc = OfficeDocument(
      id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Yeni Belge.docx',
      type: DocumentType.doc,
      lastModified: DateTime.now(),
      previewContent: 'Mobil üzerinde oluşturulmuş boş Word belgesi',
      data: '# Yeni Belge\n\nİçeriğinizi buraya yazmaya başlayın...',
    );
    OfficeStorage().addDocument(newDoc);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocsEditorScreen(document: newDoc)),
    );
  }

  void _createNewSheet(BuildContext context) {
    final newDoc = OfficeDocument(
      id: 'sheet-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Yeni Hesap Tablosu.xlsx',
      type: DocumentType.sheet,
      lastModified: DateTime.now(),
      previewContent: 'Formül ve grafik destekli boş Excel tablosu',
      data: <String, String>{
        'A1': 'Kalem', 'B1': 'Adet', 'C1': 'Fiyat (₺)', 'D1': 'Toplam (₺)',
        'A2': 'Ürün A', 'B2': '10', 'C2': '150', 'D2': '=B2*C2',
      },
    );
    OfficeStorage().addDocument(newDoc);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SheetsEditorScreen(document: newDoc)),
    );
  }

  void _createNewSlide(BuildContext context) {
    final newDoc = OfficeDocument(
      id: 'slide-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Yeni Sunum.pptx',
      type: DocumentType.slide,
      lastModified: DateTime.now(),
      previewContent: 'Slayt 1: Sunum Başlığı',
      data: [
        SlideModel(
          title: 'Sunum Başlığı',
          subtitle: 'Alt başlığı buraya ekleyin',
          body: '• Önemli madde 1\n• Önemli madde 2',
        ),
      ],
    );
    OfficeStorage().addDocument(newDoc);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SlidesEditorScreen(document: newDoc)),
    );
  }

  void _showLanguageDialog() {
    final langProvider = LanguageProvider();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: widget.isDark ? const Color(0xFF111D35) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: widget.isDark ? Colors.cyanAccent.withValues(alpha: 0.25) : const Color(0xFF0284C7).withValues(alpha: 0.2),
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.language_rounded, color: OfficeTheme.primaryBrand),
              const SizedBox(width: 8),
              Text(LanguageProvider.tr('language_select'), style: const TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLangTile(ctx, langProvider, AppLanguage.turkish, '🇹🇷 Türkçe'),
              _buildLangTile(ctx, langProvider, AppLanguage.english, '🇬🇧 English'),
              _buildLangTile(ctx, langProvider, AppLanguage.german, '🇩🇪 Deutsch'),
              _buildLangTile(ctx, langProvider, AppLanguage.spanish, '🇪🇸 Español'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangTile(
    BuildContext ctx,
    LanguageProvider provider,
    AppLanguage lang,
    String label,
  ) {
    final isSelected = provider.currentLanguage == lang;
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: OfficeTheme.primaryBrand) : null,
      onTap: () {
        provider.setLanguage(lang);
        Navigator.of(ctx).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = OfficeStorage();

    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        var docs = storage.documents;

        if (_selectedFilterIdx == 1) {
          docs = docs.where((d) => d.type == DocumentType.doc).toList();
        } else if (_selectedFilterIdx == 2) {
          docs = docs.where((d) => d.type == DocumentType.sheet).toList();
        } else if (_selectedFilterIdx == 3) {
          docs = docs.where((d) => d.type == DocumentType.slide).toList();
        } else if (_selectedFilterIdx == 4) {
          docs = docs.where((d) => d.type == DocumentType.pdf).toList();
        } else if (_selectedFilterIdx == 5) {
          docs = docs.where((d) => d.isFavorite).toList();
        }

        if (_searchQuery.isNotEmpty) {
          docs = docs
              .where((d) =>
                  d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  d.previewContent.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Row(
              children: [
                // 3D Cam Uygulama İkonu Rozeti
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icons/app_icon.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) {
                        return Container(
                          decoration: const BoxDecoration(
                            gradient: OfficeTheme.brandGradient,
                          ),
                          child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 20),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                  ).createShader(bounds),
                  child: Text(
                    LanguageProvider.tr('app_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      fontSize: 19,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: OfficeTheme.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: OfficeTheme.goldPro.withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.language_rounded),
                onPressed: _showLanguageDialog,
                tooltip: LanguageProvider.tr('language_select'),
              ),
              IconButton(
                icon: Icon(widget.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                onPressed: widget.onToggleTheme,
                tooltip: LanguageProvider.tr('theme_toggle'),
              ),
              IconButton(
                icon: const Icon(Icons.dashboard_customize_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TemplatesScreen()),
                  );
                },
                tooltip: LanguageProvider.tr('nav_templates'),
              ),
            ],
          ),
          body: GlassBackground(
            isDark: widget.isDark,
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(height: 10),
                ),

                // Güvenli Çevrimdışı Cam Kart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: GlassCard(
                      isDark: widget.isDark,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      radius: 14,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shield_rounded, color: OfficeTheme.cyanGlow, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Şifreli & Yerel Güvenlik',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tüm belgeleriniz cihazınızda güvenle saklanır.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: OfficeTheme.brandGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Cam Efektli Arama Çubuğu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: GlassCard(
                      isDark: widget.isDark,
                      radius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: TextStyle(
                          color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: LanguageProvider.tr('search_hint'),
                          hintStyle: TextStyle(
                            color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 22, color: OfficeTheme.cyanGlow),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        ),
                      ),
                    ),
                  ),
                ),

                // Hızlı Başlatma Cam Butonları
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildQuickActionBtn(
                          label: LanguageProvider.tr('quick_doc'),
                          color: OfficeTheme.docColor,
                          icon: Icons.description_rounded,
                          onTap: () => _createNewDoc(context),
                        ),
                        _buildQuickActionBtn(
                          label: LanguageProvider.tr('quick_sheet'),
                          color: OfficeTheme.sheetColor,
                          icon: Icons.table_chart_rounded,
                          onTap: () => _createNewSheet(context),
                        ),
                        _buildQuickActionBtn(
                          label: LanguageProvider.tr('quick_slide'),
                          color: OfficeTheme.slideColor,
                          icon: Icons.slideshow_rounded,
                          onTap: () => _createNewSlide(context),
                        ),
                        _buildQuickActionBtn(
                          label: LanguageProvider.tr('quick_scan'),
                          color: OfficeTheme.pdfColor,
                          icon: Icons.document_scanner_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OcrScannerScreen()),
                            );
                          },
                        ),
                        _buildQuickActionBtn(
                          label: LanguageProvider.tr('quick_convert'),
                          color: OfficeTheme.aiColor,
                          icon: Icons.auto_awesome_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FileConverterScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Filtre Sekmeleri
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        _buildFilterPill(0, LanguageProvider.tr('filter_all'), Icons.folder_special_rounded),
                        _buildFilterPill(1, 'Word', Icons.article_rounded),
                        _buildFilterPill(2, 'Excel', Icons.grid_on_rounded),
                        _buildFilterPill(3, 'Slide', Icons.co_present_rounded),
                        _buildFilterPill(4, 'PDF', Icons.picture_as_pdf_rounded),
                        _buildFilterPill(5, 'Favoriler', Icons.star_rounded),
                      ],
                    ),
                  ),
                ),

                // Belge Kartları Listesi
                if (docs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 54,
                            color: widget.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            LanguageProvider.tr('no_files'),
                            style: TextStyle(
                              color: widget.isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final doc = docs[i];
                        return DocumentCard(
                          document: doc,
                          onTap: () {
                            if (doc.type == DocumentType.doc) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => DocsEditorScreen(document: doc)),
                              );
                            } else if (doc.type == DocumentType.sheet) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => SheetsEditorScreen(document: doc)),
                              );
                            } else if (doc.type == DocumentType.slide) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => SlidesEditorScreen(document: doc)),
                              );
                            } else if (doc.type == DocumentType.pdf) {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PdfViewerScreen(document: doc)),
                              );
                            }
                          },
                          onDelete: () => storage.deleteDocument(doc.id),
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 70),
                ),
              ],
            ),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: OfficeTheme.brandGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              onPressed: () => _createNewDoc(context),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Yeni Belge',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterPill(int idx, String label, IconData icon) {
    final isSelected = _selectedFilterIdx == idx;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GlassCard(
        isDark: widget.isDark,
        radius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        fillColor: isSelected
            ? (widget.isDark ? const Color(0xFF0284C7).withValues(alpha: 0.35) : const Color(0xFF0284C7).withValues(alpha: 0.15))
            : null,
        borderColor: isSelected
            ? OfficeTheme.cyanGlow.withValues(alpha: 0.6)
            : null,
        onTap: () => setState(() => _selectedFilterIdx = idx),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? OfficeTheme.cyanGlow
                  : (widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected
                    ? (widget.isDark ? Colors.white : const Color(0xFF0284C7))
                    : (widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.9),
                  color.withValues(alpha: 0.65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: widget.isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

