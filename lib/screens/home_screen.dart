import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../widgets/document_card.dart';
import '../widgets/glass_background.dart';
import '../widgets/office_3d_icon.dart';
import 'docs_editor_screen.dart';
import 'ocr_scanner_screen.dart';
import 'pdf_viewer_screen.dart';
import 'sheets_editor_screen.dart';
import 'slides_editor_screen.dart';
import 'templates_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;
  final void Function(int tabIndex)? onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
    this.onNavigateToTab,
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
      previewContent: 'Formül ve tablo destekli boş Excel sayfası',
      data: <String, String>{
        'A1': 'Kalem', 'B1': 'Adet', 'C1': 'Birim Fiyat (₺)', 'D1': 'Toplam (₺)',
        'A2': 'Yazılım Lisansı', 'B2': '5', 'C2': '1250', 'D2': '=B2*C2',
        'A3': 'Bulut Sunucu', 'B3': '1', 'C3': '4500', 'D3': '=B3*C3',
        'A4': 'GENEL TOPLAM', 'D4': '=SUM(D2:D3)',
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
          title: 'Easy Office Sunumu',
          subtitle: 'Girişim & Proje Planı',
          body: '• Modern yapay zeka entegrasyonu\n• Mobil ofis paketi verimliliği\n• Gerçek zamanlı dışa aktarma',
          themeName: 'Modern Dark',
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
          backgroundColor: widget.isDark ? const Color(0xFF101C38) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: widget.isDark ? Colors.cyanAccent.withValues(alpha: 0.3) : const Color(0xFF0284C7).withValues(alpha: 0.2),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: OfficeTheme.primaryBrand.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.language_rounded, color: OfficeTheme.primaryBrand, size: 20),
              ),
              const SizedBox(width: 10),
              Text(LanguageProvider.tr('language_select'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? OfficeTheme.primaryBrand.withValues(alpha: 0.12) : null,
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: OfficeTheme.primaryBrand) : null,
      onTap: () {
        provider.setLanguage(lang);
        Navigator.of(ctx).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final storage = OfficeStorage();

    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        var docs = storage.documents;

        final docCount = docs.where((d) => d.type == DocumentType.doc).length;
        final sheetCount = docs.where((d) => d.type == DocumentType.sheet).length;
        final slideCount = docs.where((d) => d.type == DocumentType.slide).length;
        final pdfCount = docs.where((d) => d.type == DocumentType.pdf).length;
        final favCount = docs.where((d) => d.isFavorite).length;

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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: OfficeTheme.brandGradient,
                    boxShadow: [
                      BoxShadow(
                        color: OfficeTheme.primaryBrand.withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icons/app_icon.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) {
                        return Container(
                          decoration: const BoxDecoration(gradient: OfficeTheme.brandGradient),
                          child: const Icon(Icons.workspaces_filled, color: Colors.white, size: 22),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageProvider.tr('app_title'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'PRO SUITE • V2.0',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: isDark ? OfficeTheme.goldPro : const Color(0xFF0F172A),
                ),
                tooltip: 'Tema Değiştir',
                onPressed: widget.onToggleTheme,
              ),
              IconButton(
                icon: const Icon(Icons.language_rounded, color: OfficeTheme.primaryBrand),
                tooltip: 'Dil Seç',
                onPressed: _showLanguageDialog,
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: GlassBackground(
            isDark: isDark,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🔍 Modern Cam Arama Çubuğu
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF101B33).withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.cyanAccent.withValues(alpha: 0.2) : const Color(0xFFCBD5E1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFF0284C7).withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            decoration: InputDecoration(
                              hintText: 'Belge, tablo, sunum veya anahtar kelime ara...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: OfficeTheme.primaryBrand),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // 🤖 EASY AI COPILOT HERO BANNER
                        GlassCard(
                          isDark: isDark,
                          radius: 22,
                          padding: const EdgeInsets.all(18),
                          borderColor: OfficeTheme.cyanGlow.withValues(alpha: 0.5),
                          fillColor: isDark
                              ? const Color(0xFF0D1C38).withValues(alpha: 0.82)
                              : const Color(0xFFE0F2FE).withValues(alpha: 0.85),
                          glow: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Office3DIcon(
                                        type: Office3DType.ai,
                                        size: 42,
                                        borderRadius: 12,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Easy AI Copilot',
                                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                          ),
                                          Text(
                                            'Akıllı Ofis & Belge Asistanı',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: OfficeTheme.primaryBrand.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: OfficeTheme.cyanGlow.withValues(alpha: 0.4)),
                                    ),
                                    child: const Text(
                                      'YAPAY ZEKA',
                                      style: TextStyle(color: OfficeTheme.cyanGlow, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Sözleşme taslakları hazırlayın, fatura tablolarını analiz edin veya saniyeler içinde sunum oluşturun.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ActionChip(
                                    avatar: const Icon(Icons.edit_note_rounded, size: 16, color: OfficeTheme.cyanGlow),
                                    label: const Text('Sözleşme Yaz', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    backgroundColor: isDark ? const Color(0xFF102344) : Colors.white,
                                    onPressed: () => widget.onNavigateToTab?.call(3),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.table_chart_rounded, size: 16, color: OfficeTheme.sheetColor),
                                    label: const Text('Bütçe Tablosu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    backgroundColor: isDark ? const Color(0xFF102344) : Colors.white,
                                    onPressed: () => widget.onNavigateToTab?.call(3),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.sync_alt_rounded, size: 16, color: OfficeTheme.goldPro),
                                    label: const Text('AI Dönüştürücü', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    backgroundColor: isDark ? const Color(0xFF102344) : Colors.white,
                                    onPressed: () => widget.onNavigateToTab?.call(1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // 📱 OFİS STÜDYOLARI (3D İKONLU WORD, EXCEL, PPT, PDF, SCANNER)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ofis Stüdyoları',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TemplatesScreen()));
                              },
                              icon: const Icon(Icons.dashboard_customize_rounded, size: 14),
                              label: const Text('Şablonlar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Grid: Word, Excel, Slide, PDF, OCR (3D Cam İkonlu)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.25,
                          children: [
                            _buildStudioCard(
                              isDark: isDark,
                              title: 'Word Belgesi',
                              subtitle: '$docCount Belge Kayıtlı',
                              iconType: Office3DType.doc,
                              color: OfficeTheme.docColor,
                              onTap: () => _createNewDoc(context),
                              actionLabel: 'Yeni Belge +',
                            ),
                            _buildStudioCard(
                              isDark: isDark,
                              title: 'Excel Tablosu',
                              subtitle: '$sheetCount Tablo Kayıtlı',
                              iconType: Office3DType.sheet,
                              color: OfficeTheme.sheetColor,
                              onTap: () => _createNewSheet(context),
                              actionLabel: 'Yeni Tablo +',
                            ),
                            _buildStudioCard(
                              isDark: isDark,
                              title: 'PowerPoint Sunum',
                              subtitle: '$slideCount Sunum Kayıtlı',
                              iconType: Office3DType.slide,
                              color: OfficeTheme.slideColor,
                              onTap: () => _createNewSlide(context),
                              actionLabel: 'Yeni Sunum +',
                            ),
                            _buildStudioCard(
                              isDark: isDark,
                              title: 'PDF Araçları',
                              subtitle: '$pdfCount PDF Kayıtlı',
                              iconType: Office3DType.pdf,
                              color: OfficeTheme.pdfColor,
                              onTap: () => widget.onNavigateToTab?.call(2),
                              actionLabel: 'Araçları Aç ➔',
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Hızlı OCR Tarayıcı Cam Butonu (3D İkonlu)
                        GlassCard(
                          isDark: isDark,
                          radius: 18,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          borderColor: OfficeTheme.cyanGlow.withValues(alpha: 0.35),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const OcrScannerScreen()),
                            );
                          },
                          child: Row(
                            children: [
                              const Office3DIcon(
                                type: Office3DType.ocr,
                                size: 44,
                                borderRadius: 12,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Kamera ile Belge / Fatura Tara (OCR)',
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                                    Text(
                                      'Fiziksel kağıtları düzenlenebilir metin veya PDF yapın',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: OfficeTheme.primaryBrand),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 📂 SON BELGELER VE KATEGORİ SEKMELERİ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Son Çalışmalarım',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${docs.length} Belge',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Filtre Çipleri
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(0, 'Tümü (${storage.documents.length})', isDark),
                              const SizedBox(width: 8),
                              _buildFilterChip(1, '📄 Belgeler ($docCount)', isDark),
                              const SizedBox(width: 8),
                              _buildFilterChip(2, '📊 Tablolar ($sheetCount)', isDark),
                              const SizedBox(width: 8),
                              _buildFilterChip(3, '📽️ Sunumlar ($slideCount)', isDark),
                              const SizedBox(width: 8),
                              _buildFilterChip(4, '📕 PDF ($pdfCount)', isDark),
                              const SizedBox(width: 8),
                              _buildFilterChip(5, '⭐ Favoriler ($favCount)', isDark),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Belge Listesi
                if (docs.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open_rounded,
                            size: 48,
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Bu filtrede henüz belge bulunmuyor',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Yukarıdaki stüdyolardan yeni bir belge oluşturabilir veya dönüştürücüyü kullanabilirsiniz.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = docs[index];
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
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PdfViewerScreen(document: doc)),
                              );
                            }
                          },
                          onDelete: () {
                            storage.deleteDocument(doc.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${doc.title} silindi')),
                            );
                          },
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),

                // Alt Boşluk (Floating Nav Dock için)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(int idx, String label, bool isDark) {
    final isSelected = _selectedFilterIdx == idx;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIdx = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? OfficeTheme.primaryBrand.withValues(alpha: isDark ? 0.35 : 0.18)
              : (isDark ? const Color(0xFF101B33).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? OfficeTheme.primaryBrand
                : (isDark ? Colors.cyanAccent.withValues(alpha: 0.15) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: OfficeTheme.primaryBrand.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            color: isSelected ? (isDark ? OfficeTheme.cyanGlow : OfficeTheme.primaryBrand) : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildStudioCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required Office3DType iconType,
    required Color color,
    required VoidCallback onTap,
    required String actionLabel,
  }) {
    return GlassCard(
      isDark: isDark,
      radius: 20,
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: isDark ? 0.35 : 0.22),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Office3DIcon(
                type: iconType,
                size: 38,
                borderRadius: 11,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
