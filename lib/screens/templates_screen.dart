import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../widgets/glass_background.dart';
import 'docs_editor_screen.dart';
import 'sheets_editor_screen.dart';
import 'slides_editor_screen.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  int _selectedCategoryIdx = 0;

  final List<String> _categories = [
    'Tümü',
    'İş & Sözleşme',
    'Finans & Bütçe',
    'Sunum & Pitch',
    'CV & Kariyer',
  ];

  final List<Map<String, dynamic>> _templates = [
    {
      'title': 'Standart Gizlilik Sözleşmesi (NDA)',
      'type': DocumentType.doc,
      'category': 'İş & Sözleşme',
      'icon': Icons.gavel_rounded,
      'color': OfficeTheme.docColor,
      'desc': 'Şirketler ve freelancerlar arası çift taraflı gizlilik anlaşması.',
      'content':
          '# GİZLİLİK VE VERİ KORUMA SÖZLEŞMESİ\n\n**1. TARAFLAR:** İşbu sözleşme [Şirket Adı] ile [Müşteri Adı] arasında imzalanmıştır.\n**2. GİZLİ BİLGİ:** Ticari sırlar, kaynak kodlar ve müşteri listeleri gizli kabul edilir.\n**3. SÜRE:** 3 yıl geçerlidir.',
    },
    {
      'title': 'Aylık Gelir - Gider & Bütçe Tablosu',
      'type': DocumentType.sheet,
      'category': 'Finans & Bütçe',
      'icon': Icons.account_balance_wallet_rounded,
      'color': OfficeTheme.sheetColor,
      'desc': 'Otomatik toplam ve net kâr formüllü kişisel ve kurumsal bütçe.',
      'content': <String, String>{
        'A1': 'Kategori', 'B1': 'Bütçe (₺)', 'C1': 'Harcanan (₺)', 'D1': 'Kalan (₺)',
        'A2': 'Ofis Kirası', 'B2': '12000', 'C2': '12000', 'D2': '=B2-C2',
        'A3': 'Personel Maaşları', 'B3': '45000', 'C3': '43000', 'D3': '=B3-C3',
        'A4': 'Pazarlama & Reklam', 'B4': '15000', 'C4': '11500', 'D4': '=B4-C4',
        'A5': 'Genel Toplam', 'B5': '=SUM(B2:B4)', 'C6': '=SUM(C2:C4)', 'D5': '=SUM(D2:D4)',
      },
    },
    {
      'title': 'Yatırımcı Pitch Deck Sunumu',
      'type': DocumentType.slide,
      'category': 'Sunum & Pitch',
      'icon': Icons.insights_rounded,
      'color': OfficeTheme.slideColor,
      'desc': 'Girişimciler için tohum yatırım sunum şablonu.',
      'content': [
        SlideModel(
          title: 'STARTUP PITCH DECK',
          subtitle: 'Tohum Yatırım Turu Sunumu',
          body: 'Kurucular ve Şirket Vizyonu 2026',
          themeName: 'Emerald Luxury',
        ),
        SlideModel(
          title: 'Pazar Problemi',
          subtitle: 'Geleneksel Ofis Araçları Yetersiz',
          body: '• Mobil hız ve pratiklik eksikliği\n• PDF dönüştürme maliyetleri',
          themeName: 'Modern Dark',
        ),
      ],
    },
    {
      'title': 'Modern Profesyonel Özgeçmiş (CV)',
      'type': DocumentType.doc,
      'category': 'CV & Kariyer',
      'icon': Icons.badge_rounded,
      'color': OfficeTheme.docColor,
      'desc': 'İş başvuruları için ATS uyumlu modern CV taslağı.',
      'content':
          '# AD SOYAD\n**Kıdemli Yazılım Mühendisi & Proje Yöneticisi**\n\n• **E-posta:** email@example.com | **Telefon:** +90 555 123 4567\n\n## DENEYİM\n**Kıdemli Geliştirici - Tech Corp (2022 - Günümüz)**\n- Flutter ve bulut tabanlı mobil uygulamalar geliştirildi.\n\n## EĞİTİM\n**Bilgisayar Mühendisliği Lisans** - 2020',
    },
    {
      'title': 'Proje Zaman Çizelgesi & Gantt',
      'type': DocumentType.sheet,
      'category': 'İş & Sözleşme',
      'icon': Icons.calendar_month_rounded,
      'color': OfficeTheme.sheetColor,
      'desc': 'Sprint planlama ve görev tamamlama takip tablosu.',
      'content': <String, String>{
        'A1': 'Görev Adı', 'B1': 'Sorumlu', 'C1': 'Başlangıç', 'D1': 'Durum',
        'A2': 'UI/UX Tasarım', 'B2': 'Ayşe', 'C2': 'Hafta 1', 'D2': 'Tamamlandı',
        'A3': 'Mobil Kodlama', 'B3': 'Mehmet', 'C3': 'Hafta 2', 'D3': 'Devam Ediyor',
      },
    },
  ];

  void _useTemplate(Map<String, dynamic> tpl) {
    final title = '${tpl['title']}.${tpl['type'] == DocumentType.doc ? 'docx' : tpl['type'] == DocumentType.sheet ? 'xlsx' : 'pptx'}';
    final doc = OfficeDocument(
      id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      type: tpl['type'] as DocumentType,
      lastModified: DateTime.now(),
      previewContent: tpl['desc'] as String,
      data: tpl['content'],
      tag: tpl['category'] as String,
    );

    OfficeStorage().addDocument(doc);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _selectedCategoryIdx == 0
        ? _templates
        : _templates
            .where((t) => t['category'] == _categories[_selectedCategoryIdx])
            .toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: OfficeTheme.goldGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Şablon Galerisi (Pro)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      ),
      body: GlassBackground(
        isDark: isDark,
        child: Column(
          children: [
            // Kategori filtre hapları
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: List.generate(_categories.length, (idx) {
                  final isSelected = _selectedCategoryIdx == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GlassCard(
                      isDark: isDark,
                      radius: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      fillColor: isSelected
                          ? (isDark ? const Color(0xFF0284C7).withValues(alpha: 0.35) : const Color(0xFF0284C7).withValues(alpha: 0.15))
                          : null,
                      borderColor: isSelected ? OfficeTheme.cyanGlow.withValues(alpha: 0.6) : null,
                      onTap: () => setState(() => _selectedCategoryIdx = idx),
                      child: Text(
                        _categories[idx],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF0284C7))
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Şablon Kartları Izgarası
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, idx) {
                  final item = filtered[idx];
                  final color = item['color'] as Color;

                  return GlassCard(
                    isDark: isDark,
                    radius: 18,
                    padding: const EdgeInsets.all(14),
                    borderColor: color.withValues(alpha: isDark ? 0.35 : 0.25),
                    onTap: () => _useTemplate(item),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: isDark ? 0.35 : 0.2),
                                color.withValues(alpha: isDark ? 0.15 : 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withValues(alpha: 0.3)),
                          ),
                          child: Icon(item['icon'] as IconData, color: color, size: 24),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            item['desc'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['category'] as String,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
                            ),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: color),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

