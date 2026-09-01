import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/theme.dart';

enum Office3DType {
  doc,
  sheet,
  slide,
  pdf,
  ai,
  ocr,
  converter,
  signature,
  template,
  custom,
}

class Office3DIcon extends StatelessWidget {
  final Office3DType type;
  final IconData? icon;
  final double size;
  final Color? baseColor;
  final List<Color>? gradientColors;
  final bool withGlow;
  final double borderRadius;

  const Office3DIcon({
    super.key,
    required this.type,
    this.icon,
    this.size = 48,
    this.baseColor,
    this.gradientColors,
    this.withGlow = true,
    this.borderRadius = 16,
  });

  factory Office3DIcon.fromDocType(DocumentType docType, {double size = 48, bool withGlow = true}) {
    switch (docType) {
      case DocumentType.doc:
        return Office3DIcon(type: Office3DType.doc, size: size, withGlow: withGlow);
      case DocumentType.sheet:
        return Office3DIcon(type: Office3DType.sheet, size: size, withGlow: withGlow);
      case DocumentType.slide:
        return Office3DIcon(type: Office3DType.slide, size: size, withGlow: withGlow);
      case DocumentType.pdf:
        return Office3DIcon(type: Office3DType.pdf, size: size, withGlow: withGlow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (iconData, colors, glowColor) = _getIconProperties();

    final outerSize = size;
    final innerIconSize = size * 0.52;

    return Container(
      width: outerSize,
      height: outerSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            colors[0],
            colors[1],
            colors.length > 2 ? colors[2] : colors[1],
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          // 3D Taban Gölgesi
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          // Neon 3D Parıltı Aurası
          if (withGlow)
            BoxShadow(
              color: glowColor.withValues(alpha: 0.45),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Stack(
        children: [
          // Üst Cam Işık Yansıması (Glossy Specular Highlight)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: outerSize * 0.45,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius - 1)),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.40),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3D Çift Katmanlı İkon Efekti
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // İkonun Derinlik Gölgesi
                Transform.translate(
                  offset: const Offset(0, 2),
                  child: Icon(
                    iconData,
                    size: innerIconSize,
                    color: Colors.black.withValues(alpha: 0.4),
                  ),
                ),
                // Parlak Ön İkon
                Icon(
                  iconData,
                  size: innerIconSize,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, List<Color>, Color) _getIconProperties() {
    switch (type) {
      case Office3DType.doc:
        return (
          icon ?? Icons.description_rounded,
          [const Color(0xFF3B82F6), const Color(0xFF1D4ED8), const Color(0xFF1E3A8A)],
          const Color(0xFF60A5FA),
        );
      case Office3DType.sheet:
        return (
          icon ?? Icons.table_view_rounded,
          [const Color(0xFF10B981), const Color(0xFF059669), const Color(0xFF064E3B)],
          const Color(0xFF34D399),
        );
      case Office3DType.slide:
        return (
          icon ?? Icons.slideshow_rounded,
          [const Color(0xFFF97316), const Color(0xFFEA580C), const Color(0xFF9A3412)],
          const Color(0xFFFB923C),
        );
      case Office3DType.pdf:
        return (
          icon ?? Icons.picture_as_pdf_rounded,
          [const Color(0xFFEF4444), const Color(0xFFDC2626), const Color(0xFF991B1B)],
          const Color(0xFFF87171),
        );
      case Office3DType.ai:
        return (
          icon ?? Icons.auto_awesome_rounded,
          [const Color(0xFF06B6D4), const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
          const Color(0xFFA78BFA),
        );
      case Office3DType.ocr:
        return (
          icon ?? Icons.document_scanner_rounded,
          [const Color(0xFF0EA5E9), const Color(0xFF0284C7), const Color(0xFF0369A1)],
          const Color(0xFF38BDF8),
        );
      case Office3DType.converter:
        return (
          icon ?? Icons.sync_alt_rounded,
          [const Color(0xFF6366F1), const Color(0xFF4F46E5), const Color(0xFF3730A3)],
          const Color(0xFF818CF8),
        );
      case Office3DType.signature:
        return (
          icon ?? Icons.draw_rounded,
          [const Color(0xFFF59E0B), const Color(0xFFD97706), const Color(0xFFB45309)],
          const Color(0xFFFBBF24),
        );
      case Office3DType.template:
        return (
          icon ?? Icons.dashboard_customize_rounded,
          [const Color(0xFF14B8A6), const Color(0xFF0D9488), const Color(0xFF115E59)],
          const Color(0xFF2DD4BF),
        );
      case Office3DType.custom:
        final c = baseColor ?? OfficeTheme.primaryBrand;
        return (
          icon ?? Icons.star_rounded,
          gradientColors ?? [c, c.withValues(alpha: 0.8)],
          c,
        );
    }
  }
}
