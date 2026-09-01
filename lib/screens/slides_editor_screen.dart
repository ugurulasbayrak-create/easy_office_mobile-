import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';

class SlidesEditorScreen extends StatefulWidget {
  final OfficeDocument? document;

  const SlidesEditorScreen({super.key, this.document});

  @override
  State<SlidesEditorScreen> createState() => _SlidesEditorScreenState();
}

class _SlidesEditorScreenState extends State<SlidesEditorScreen> {
  late TextEditingController _titleController;
  late String _slideDocId;

  late List<SlideModel> _slides;
  int _activeSlideIdx = 0;

  final Map<String, List<Color>> _themePalettes = {
    'Modern Dark': [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF6366F1)],
    'Emerald Luxury': [const Color(0xFF064E3B), const Color(0xFF047857), const Color(0xFF10B981)],
    'Corporate Navy': [const Color(0xFF1E3A8A), const Color(0xFF1D4ED8), const Color(0xFF38BDF8)],
    'Sunset Warm': [const Color(0xFF7C2D12), const Color(0xFFEA580C), const Color(0xFFFBBF24)],
  };

  @override
  void initState() {
    super.initState();
    _slideDocId = widget.document?.id ?? 'slide-${DateTime.now().millisecondsSinceEpoch}';
    _titleController = TextEditingController(
      text: widget.document?.title ?? 'Girişim Sunumu.pptx',
    );

    if (widget.document?.data is List) {
      _slides = List<SlideModel>.from(widget.document!.data as List);
    } else {
      _slides = [
        SlideModel(
          title: 'EASY OFFICE MOBİL',
          subtitle: 'Yeni Nesil Mobil Ofis & Yapay Zeka Platformu',
          body: 'Belge, Tablo, Sunum ve PDF Araçları Tek Bir Güçlü Uygulamada.',
          themeName: 'Modern Dark',
        ),
        SlideModel(
          title: 'Pazar Fırsatı & Hedef Kitle',
          subtitle: '500M+ Global Mobil Kullanıcı',
          body: '• Ağır masaüstü ofis araçları yerine hızlı mobil alternatif\n• Çevrimdışı yerel depolama ve sıfır veri sızıntısı\n• Dahili yapay zeka asistanı ve kamera OCR',
          themeName: 'Emerald Luxury',
        ),
      ];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _saveSlides() {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Presentation.pptx'
        : _titleController.text.trim();
    final storage = OfficeStorage();

    final preview = 'Slayt Sayısı: ${_slides.length} | Aktif: ${_slides.first.title}';

    if (widget.document != null) {
      storage.updateDocument(_slideDocId, title: title, data: _slides, preview: preview);
    } else {
      storage.addDocument(
        OfficeDocument(
          id: _slideDocId,
          title: title,
          type: DocumentType.slide,
          lastModified: DateTime.now(),
          previewContent: preview,
          data: _slides,
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sunum başarıyla kaydedildi!'),
        backgroundColor: OfficeTheme.slideColor,
      ),
    );
  }

  void _addNewSlide() {
    setState(() {
      _slides.add(
        SlideModel(
          title: 'Yeni Slayt Başlığı',
          subtitle: 'Açıklayıcı alt başlık ekleyin',
          body: '• Önemli analiz maddesi 1\n• Destekleyici veriler ve grafikler',
          themeName: _slides[_activeSlideIdx].themeName,
        ),
      );
      _activeSlideIdx = _slides.length - 1;
    });
  }

  void _startPresenterMode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _FullscreenPresenterScreen(
          slides: _slides,
          palettes: _themePalettes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_activeSlideIdx];
    final currentPalette = _themePalettes[currentSlide.themeName] ?? _themePalettes['Modern Dark']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _saveSlides();
            Navigator.of(context).pop();
          },
        ),
        title: TextField(
          controller: _titleController,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Sunum Başlığı',
          ),
          onSubmitted: (_) => _saveSlides(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_fill_rounded, color: OfficeTheme.slideColor, size: 28),
            tooltip: 'Canlı Sunum Modu',
            onPressed: _startPresenterMode,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline_rounded),
            tooltip: 'Kaydet',
            onPressed: _saveSlides,
          ),
        ],
      ),
      body: Column(
        children: [
          // Theme & Slide Controls Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFFFEDD5),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette_outlined, size: 16, color: OfficeTheme.slideColor),
                    const SizedBox(width: 6),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: currentSlide.themeName,
                        isDense: true,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: OfficeTheme.slideColor),
                        items: _themePalettes.keys.map((themeKey) {
                          return DropdownMenuItem<String>(
                            value: themeKey,
                            child: Text(themeKey),
                          );
                        }).toList(),
                        onChanged: (newTheme) {
                          if (newTheme != null) {
                            setState(() {
                              currentSlide.themeName = newTheme;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                Text(
                  'Slayt ${_activeSlideIdx + 1} / ${_slides.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: OfficeTheme.slideColor),
                ),
              ],
            ),
          ),

          // Main 16:9 Presentation Canvas
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [currentPalette[0], currentPalette[1]],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Box
                      TextFormField(
                        key: ValueKey('title-$_activeSlideIdx'),
                        initialValue: currentSlide.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Slayt Başlığını Yazın',
                          hintStyle: TextStyle(color: Colors.white60),
                          isDense: true,
                        ),
                        onChanged: (val) => currentSlide.title = val,
                      ),
                      const SizedBox(height: 2),

                      // Subtitle Box
                      TextFormField(
                        key: ValueKey('sub-$_activeSlideIdx'),
                        initialValue: currentSlide.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: currentPalette[2],
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Alt Başlık Ekleyin',
                          hintStyle: TextStyle(color: currentPalette[2].withValues(alpha: 0.6)),
                          isDense: true,
                        ),
                        onChanged: (val) => currentSlide.subtitle = val,
                      ),
                      const Divider(height: 16, color: Colors.white24),

                      // Body Text Box
                      Expanded(
                        child: TextFormField(
                          key: ValueKey('body-$_activeSlideIdx'),
                          initialValue: currentSlide.body,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: Colors.white70,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Madde imleri ve içeriği buraya ekleyin...',
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                          onChanged: (val) => currentSlide.body = val,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Slide Deck Thumbnails Strip (WPS Style)
          Container(
            height: 105,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _slides.length + 1,
              itemBuilder: (ctx, idx) {
                if (idx == _slides.length) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(backgroundColor: OfficeTheme.slideLight),
                        onPressed: _addNewSlide,
                        icon: const Icon(Icons.add_rounded, color: OfficeTheme.slideColor),
                        label: const Text('Slayt Ekle', style: TextStyle(color: OfficeTheme.slideColor)),
                      ),
                    ),
                  );
                }

                final isSelected = _activeSlideIdx == idx;
                final slide = _slides[idx];
                final p = _themePalettes[slide.themeName] ?? _themePalettes['Modern Dark']!;

                return GestureDetector(
                  onTap: () => setState(() => _activeSlideIdx = idx),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [p[0], p[1]],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.amber : Colors.transparent,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${idx + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          slide.title.isEmpty ? 'Başlıksız' : slide.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenPresenterScreen extends StatefulWidget {
  final List<SlideModel> slides;
  final Map<String, List<Color>> palettes;

  const _FullscreenPresenterScreen({required this.slides, required this.palettes});

  @override
  State<_FullscreenPresenterScreen> createState() => _FullscreenPresenterScreenState();
}

class _FullscreenPresenterScreenState extends State<_FullscreenPresenterScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  bool _laserPointerEnabled = false;
  Offset _laserPos = const Offset(150, 150);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: widget.slides.length,
            itemBuilder: (ctx, idx) {
              final slide = widget.slides[idx];
              final p = widget.palettes[slide.themeName] ?? widget.palettes['Modern Dark']!;

              return Center(
                child: GestureDetector(
                  onPanUpdate: _laserPointerEnabled
                      ? (d) => setState(() => _laserPos = d.localPosition)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [p[0], p[1]]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.white.withValues(alpha: 0.15), blurRadius: 40),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slide.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slide.subtitle,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: p[2],
                          ),
                        ),
                        const Divider(height: 32, color: Colors.white24),
                        Text(
                          slide.body,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.8,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Laser Pointer Dot
          if (_laserPointerEnabled)
            Positioned(
              left: _laserPos.dx - 10,
              top: _laserPos.dy - 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.red, blurRadius: 16, spreadRadius: 4),
                  ],
                ),
              ),
            ),

          // Top Controls Bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _laserPointerEnabled ? Icons.lens_rounded : Icons.lens_outlined,
                          color: _laserPointerEnabled ? Colors.redAccent : Colors.white,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _laserPointerEnabled = !_laserPointerEnabled),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentPage + 1} / ${widget.slides.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
