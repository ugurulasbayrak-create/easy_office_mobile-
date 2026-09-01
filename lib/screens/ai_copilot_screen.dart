import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../widgets/glass_background.dart';
import 'docs_editor_screen.dart';
import 'sheets_editor_screen.dart';
import 'slides_editor_screen.dart';

class AiCopilotScreen extends StatefulWidget {
  const AiCopilotScreen({super.key});

  @override
  State<AiCopilotScreen> createState() => _AiCopilotScreenState();
}

class _AiCopilotScreenState extends State<AiCopilotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text':
          'Merhaba! Ben Easy AI Asistanınız. 🤖✨\n\nWord sözleşmelerinizi hazırlayabilir, Excel için gelişmiş formüllü tablolar kurabilir, sunum slaytları tasarlayabilir veya dokümanlarınızı özetleyebilirim. Size nasıl yardımcı olabilirim?',
    },
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': query.trim()});
      _isTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    // AI Yanıt Üretme Motoru
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;

      String aiResponse = '';
      final lower = query.toLowerCase();

      if (lower.contains('sözleşme') || lower.contains('nda') || lower.contains('contract') || lower.contains('protokol')) {
        aiResponse =
            '📋 **Hazırlanan Gizlilik & Hizmet Sözleşmesi (Draft):**\n\n'
            '**MADDE 1 - TARAFLAR:**\nİşbu sözleşme Easy Office (Hizmet Sağlayıcı) ile Kullanıcı (Müşteri) arasında akdedilmiştir.\n\n'
            '**MADDE 2 - GİZLİLİK VE VERİ GÜVENLİĞİ:**\nPaylaşılan tüm ticari sırlar, finansal dökümler ve ofis verileri 3. şahıslara aktarılamaz ve yerel cihazda şifrelenir.\n\n'
            '**MADDE 3 - SÜRE VE FESİH:**\nSözleşme imza tarihinden itibaren 2 yıl geçerlidir.\n\n'
            '👉 *Aşağıdaki butonla bu taslağı anında düzenlenebilir Word belgesine aktarabilirsiniz.*';
      } else if (lower.contains('excel') || lower.contains('formül') || lower.contains('sum') || lower.contains('kâr') || lower.contains('tablo') || lower.contains('bütçe')) {
        aiResponse =
            '📊 **Excel Hesap Tablosu & Formül Paketi:**\n\n'
            '• **Satış Kârı:** `=B2-C2` *(Gelir - Gider)*\n'
            '• **Genel Ciro Toplamı:** `=SUM(B2:B10)`\n'
            '• **KDV Hesaplama (%20):** `=B2*0.20`\n'
            '• **Net Bakiye:** `=SUM(D2:D10)-SUM(E2:E10)`\n'
            '• **Ortalama Değer:** `=AVERAGE(B2:B10)`\n\n'
            '👉 *Aşağıdaki butonla formüllü boş bir Excel tablosu oluşturabilirsiniz.*';
      } else if (lower.contains('sunum') || lower.contains('pitch') || lower.contains('slayt') || lower.contains('proje')) {
        aiResponse =
            '📽️ **Girişim ve Yatırımcı Sunumu Taslağı (3 Slayt):**\n\n'
            '1. **Slayt 1 (Vizyon):** Yeni Nesil Yapay Zeka Destekli Mobil Ofis Ekosistemi\n'
            '2. **Slayt 2 (Pazar & Fırsat):** 48 Milyar Dolarlık küresel mobil üretkenlik pazarı\n'
            '3. **Slayt 3 (Teknoloji & Çözüm):** Hepsi bir arada Word/Excel/PPT/PDF ve dahili OCR motoru\n\n'
            '👉 *Aşağıdaki butonla bu sunumu doğrudan slayt stüdyosuna aktarabilirsiniz.*';
      } else {
        aiResponse =
            '✨ **Easy AI Akıllı Yanıtı:**\n\n'
            'Talebiniz incelendi: "$query".\n'
            'Easy Office AI motoru içeriği profesyonel iş standartlarına ve kurumsal formata uygun şekilde yapılandırdı. Belgenize eklemek veya dışa aktarmak için aşağıdaki aksiyonları kullanabilirsiniz.';
      }

      setState(() {
        _isTyping = false;
        _messages.add({'role': 'assistant', 'text': aiResponse});
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _createDocFromAi(String content) {
    final doc = OfficeDocument(
      id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
      title: 'AI Üretilen Belge.docx',
      type: DocumentType.doc,
      lastModified: DateTime.now(),
      previewContent: content.length > 80 ? '${content.substring(0, 80)}...' : content,
      data: content,
    );
    OfficeStorage().addDocument(doc);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DocsEditorScreen(document: doc)),
    );
  }

  void _createSheetFromAi(String content) {
    final doc = OfficeDocument(
      id: 'sheet-${DateTime.now().millisecondsSinceEpoch}',
      title: 'AI Üretilen Tablo.xlsx',
      type: DocumentType.sheet,
      lastModified: DateTime.now(),
      previewContent: 'AI tarafından oluşturulan formüllü hesap tablosu',
      data: <String, String>{
        'A1': 'Kalem Açıklaması', 'B1': 'Miktar', 'C1': 'Birim Fiyat', 'D1': 'Toplam Tutar',
        'A2': 'Satış Geliri', 'B2': '10', 'C2': '250', 'D2': '=B2*C2',
        'A3': 'Hizmet Bedeli', 'B3': '1', 'C3': '1500', 'D3': '=B3*C3',
        'A4': 'GENEL TOPLAM', 'D4': '=SUM(D2:D3)',
      },
    );
    OfficeStorage().addDocument(doc);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SheetsEditorScreen(document: doc)),
    );
  }

  void _createSlideFromAi(String content) {
    final doc = OfficeDocument(
      id: 'slide-${DateTime.now().millisecondsSinceEpoch}',
      title: 'AI Üretilen Sunum.pptx',
      type: DocumentType.slide,
      lastModified: DateTime.now(),
      previewContent: 'AI tarafından oluşturulan sunum slaytları',
      data: [
        SlideModel(
          title: 'Yeni Nesil Proje Vizyonu',
          subtitle: 'Easy AI Tarafından Hazırlandı',
          body: '• Pazar analizi ve büyüme hedefleri\n• Yapay zeka destekli ofis araçları\n• Yüksek verimlilik ve hız',
          themeName: 'Modern Dark',
        ),
      ],
    );
    OfficeStorage().addDocument(doc);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SlidesEditorScreen(document: doc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
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
                    color: OfficeTheme.aiColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              LanguageProvider.tr('nav_ai'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
      ),
      body: GlassBackground(
        isDark: isDark,
        child: Column(
          children: [
            // Hızlı Öneri İpuçları
            Container(
              height: 48,
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildPromptChip('📝 Gizlilik Sözleşmesi Yaz', isDark),
                  _buildPromptChip('📊 Excel Kâr & Bütçe Formülü', isDark),
                  _buildPromptChip('📽️ 3 Slaytlık Pitch Deck', isDark),
                  _buildPromptChip('🌐 Profesyonel İngilizce Çevir', isDark),
                ],
              ),
            ),

            // Mesajlar Listesi
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (ctx, idx) {
                  if (idx == _messages.length && _isTyping) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: GlassCard(
                        isDark: isDark,
                        radius: 18,
                        padding: const EdgeInsets.all(14),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: OfficeTheme.cyanGlow),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Easy AI yanıt hazırlıyor...',
                              style: TextStyle(fontSize: 12, color: OfficeTheme.cyanGlow, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final msg = _messages[idx];
                  final isUser = msg['role'] == 'user';
                  final text = msg['text'] ?? '';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
                      padding: const EdgeInsets.all(16),
                      decoration: isUser
                          ? BoxDecoration(
                              gradient: OfficeTheme.brandGradient,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            )
                          : OfficeTheme.glassBox(
                              isDark: isDark,
                              radius: 20,
                              borderColor: OfficeTheme.cyanGlow.withValues(alpha: isDark ? 0.30 : 0.18),
                              fillColor: isDark ? const Color(0xFF0D1B36).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.92),
                            ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: isUser
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                            ),
                          ),
                          if (!isUser && idx > 0) ...[
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: OfficeTheme.docColor.withValues(alpha: isDark ? 0.3 : 0.12),
                                    foregroundColor: isDark ? Colors.cyanAccent : OfficeTheme.docColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _createDocFromAi(text),
                                  icon: const Icon(Icons.description_rounded, size: 14),
                                  label: const Text('Word Yap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: OfficeTheme.sheetColor.withValues(alpha: isDark ? 0.3 : 0.12),
                                    foregroundColor: isDark ? Colors.greenAccent : OfficeTheme.sheetColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _createSheetFromAi(text),
                                  icon: const Icon(Icons.table_view_rounded, size: 14),
                                  label: const Text('Excel Yap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: OfficeTheme.slideColor.withValues(alpha: isDark ? 0.3 : 0.12),
                                    foregroundColor: isDark ? Colors.orangeAccent : OfficeTheme.slideColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _createSlideFromAi(text),
                                  icon: const Icon(Icons.slideshow_rounded, size: 14),
                                  label: const Text('Sunum Yap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 16),
                                  tooltip: 'Kopyala',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: text));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Metin panoya kopyalandı!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Giriş Alanı
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              child: GlassCard(
                isDark: isDark,
                radius: 26,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                borderColor: OfficeTheme.cyanGlow.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Easy AI\'ya bir soru sorun veya belge isteyin...',
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        ),
                        onSubmitted: (val) => _sendMessage(val),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: OfficeTheme.brandGradient,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        onPressed: () => _sendMessage(_inputController.text),
                      ),
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

  Widget _buildPromptChip(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GlassCard(
        isDark: isDark,
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: () => _sendMessage(text),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}
