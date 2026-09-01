import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const GlassBackground({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? OfficeTheme.darkBackgroundGlow
            : OfficeTheme.lightBackgroundGlow,
      ),
      child: Stack(
        children: [
          // Üst Sağ Işıltılı Neon Camgöbeği Parıltısı
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF0284C7) : const Color(0xFF38BDF8))
                        .withValues(alpha: isDark ? 0.35 : 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Sol Alt Sıcak Altın / Kehribar Parıltı
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    OfficeTheme.goldPro.withValues(alpha: isDark ? 0.12 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Ana İçerik
          SafeArea(
            child: child,
          ),
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? fillColor;

  const GlassCard({
    super.key,
    required this.child,
    required this.isDark,
    this.radius = 18,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: OfficeTheme.glassBox(
        isDark: isDark,
        radius: radius,
        borderColor: borderColor,
        fillColor: fillColor,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: content,
      ),
    );
  }
}
