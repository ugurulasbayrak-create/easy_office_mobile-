import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/localization.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../widgets/glass_background.dart';
import 'docs_editor_screen.dart';

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
          'Merhaba! Ben Easy AI Asistanınız. 🤖✨\n\nWord belgelerinizi yazabilir, Excel için gelişmiş formüller üretebilir, sunum slaytları tasarlayabilir veya sözleşmelerinizi analiz edebilirim. Size nasıl yardımcı olabilirim?',
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

    // AI Response generation logic
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      String aiResponse = '';
      final lower = query.toLowerCase();

      if (lower.contains('sözleşme') || lower.contains('nda') || lower.contains('contract')) {
        aiResponse =
            '📋 **Hazırlanan Gizlilik & Hizmet Sözleşmesi:**\n\n'
            '**Madde 1 (Taraflar):** Easy Office ve Müşteri arasında akdedilmiştir.\n'
            '**Madde 2 (Gizlilik):** Paylaşılan tüm ofis verileri ve finansal analizler kesinlikle 3. şahıslara aktarılamaz.\n'
            '**Madde 3 (Süre):** İşbu sözleşme imza tarihinden itibaren 2 (iki) yıl süreyle geçerlidir.\n\n'
            'Bu taslağı tek dokunuşla yeni bir **Easy Docs** belgesine aktarabilirsiniz!';
      } else if (lower.contains('excel') || lower.contains('formül') || lower.contains('sum') || lower.contains('kâr')) {
        aiResponse =
            '📊 **Excel Gelişmiş Formül Önerisi:**\n\n'
            '• **Kâr Hesaplama:** `=B2-C2`\n'
            '• **Toplam Ciro:** `=SUM(B2:B10)`\n'
            '• **Ortalama Sipariş Tutarı:** `=AVERAGE(B2:B10)`\n'
            '• **Büyüme Oranı:** `=(B2-B1)/B1`\n\n'
            'Bu formülleri doğrudan **Easy Sheets** tablonuza yapıştırabilirsiniz.';
      } else if (lower.contains('sunum') || lower.contains('pitch') || lower.contains('slayt')) {
        aiResponse =
            '📽️ **Girişim Yatırımcı Sunumu Taslağı (3 Slayt):**\n\n'
            '1. **Slayt 1 (Vizyon):** Yeni Nesil Mobil Ofis Teknolojileri.\n'
            '2. **Slayt 2 (Pazar Büyüklüğü):** 48 Milyar Dolarlık mobil üretkenlik pazarı.\n'
            '3. **Slayt 3 (Çözüm):** Hepsi bir arada ofis araçları ve dahili OCR motoru.';
      } else {
        aiResponse =
            '✨ **Easy AI Analiz ve Çıktı:**\n\n'
            'Talebinizi işledim: "$query".\n'
            'Easy Office AI motoru içeriği profesyonel iş standartlarına uygun olarak biçimlendirdi. Belgenize eklemek veya dışa aktarmak için aşağıdaki butonları kullanabilirsiniz.';
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
      title: 'Easy AI Taslak Belge.docx',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                  _buildPromptChip('📊 Excel Kâr Formülü Üret', isDark),
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
                        radius: 16,
                        padding: const EdgeInsets.all(12),
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
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                      padding: const EdgeInsets.all(14),
                      decoration: isUser
                          ? BoxDecoration(
                              gradient: OfficeTheme.brandGradient,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                                bottomRight: Radius.circular(4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            )
                          : OfficeTheme.glassBox(
                              isDark: isDark,
                              radius: 18,
                              borderColor: OfficeTheme.cyanGlow.withValues(alpha: isDark ? 0.25 : 0.15),
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
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
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
                                const SizedBox(width: 4),
                                FilledButton.tonalIcon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: OfficeTheme.primaryBrand.withValues(alpha: isDark ? 0.3 : 0.15),
                                    foregroundColor: isDark ? OfficeTheme.cyanGlow : OfficeTheme.primaryBrand,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _createDocFromAi(text),
                                  icon: const Icon(Icons.description_outlined, size: 14),
                                  label: const Text('Belgeye Dönüştür', style: TextStyle(fontSize: 11)),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              child: GlassCard(
                isDark: isDark,
                radius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        radius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        onTap: () => _sendMessage(text),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

