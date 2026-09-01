import 'package:flutter/material.dart';
import '../core/theme.dart';

class SignaturePadDialog extends StatefulWidget {
  final ValueChanged<List<List<Offset>>> onSaveSignature;

  const SignaturePadDialog({super.key, required this.onSaveSignature});

  @override
  State<SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<SignaturePadDialog> {
  final List<List<Offset>> _lines = [];
  List<Offset> _currentLine = [];

  double _strokeWidth = 2.5;
  Color _strokeColor = const Color(0xFF1E3A8A); // Royal Signature Navy

  final List<Color> _availableColors = [
    const Color(0xFF1E3A8A), // Royal Navy
    const Color(0xFF0F172A), // Black
    const Color(0xFFDC2626), // Crimson Red
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: OfficeTheme.primaryBrand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.draw_rounded, color: OfficeTheme.primaryBrand, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Dijital İmza & Mühür Stüdyosu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Color & Thickness Controls Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Color Selectors
                Row(
                  children: _availableColors.map((col) {
                    final isSelected = _strokeColor == col;
                    return GestureDetector(
                      onTap: () => setState(() => _strokeColor = col),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.amber : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Stroke Width Selectors
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 1.5, label: Text('İnce')),
                    ButtonSegment(value: 2.5, label: Text('Orta')),
                    ButtonSegment(value: 4.0, label: Text('Kalın')),
                  ],
                  selected: {_strokeWidth},
                  onSelectionChanged: (val) => setState(() => _strokeWidth = val.first),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Signature Drawing Canvas (Paper Texture)
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // Baseline Guideline
                    Positioned(
                      bottom: 45,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 1,
                        color: const Color(0xFF94A3B8).withValues(alpha: 0.4),
                      ),
                    ),
                    const Positioned(
                      bottom: 25,
                      right: 25,
                      child: Text(
                        '✕ Burayı İmzalayın',
                        style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Gesture Listener for drawing
                    GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _currentLine = [details.localPosition];
                          _lines.add(_currentLine);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _currentLine.add(details.localPosition);
                        });
                      },
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          lines: _lines,
                          strokeColor: _strokeColor,
                          strokeWidth: _strokeWidth,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _lines.clear()),
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.red),
                  label: const Text('Temizle', style: TextStyle(color: Colors.red)),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: OfficeTheme.primaryBrand,
                      ),
                      onPressed: _lines.isEmpty
                          ? null
                          : () {
                              widget.onSaveSignature(_lines);
                              Navigator.of(context).pop();
                            },
                      icon: const Icon(Icons.verified_rounded, size: 16),
                      label: const Text('Mühürle & Ekle'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> lines;
  final Color strokeColor;
  final double strokeWidth;

  _SignaturePainter({
    required this.lines,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    for (final line in lines) {
      if (line.isEmpty) continue;
      final path = Path();
      path.moveTo(line[0].dx, line[0].dy);
      for (int i = 1; i < line.length; i++) {
        path.lineTo(line[i].dx, line[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
