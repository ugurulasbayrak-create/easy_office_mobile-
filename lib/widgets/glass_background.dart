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
            top: -80,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
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

          // Sol Orta Mor / Nebula Parıltısı
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35,
            left: -100,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isDark ? const Color(0xFF7C3AED) : const Color(0xFFC084FC))
                        .withValues(alpha: isDark ? 0.18 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Sol Alt Sıcak Altın / Kehribar Parıltı
          Positioned(
            bottom: 60,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    OfficeTheme.goldPro.withValues(alpha: isDark ? 0.14 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Ana İçerik
          SafeArea(
            bottom: false,
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
  final bool glow;

  const GlassCard({
    super.key,
    required this.child,
    required this.isDark,
    this.radius = 20,
    this.padding,
    this.margin,
    this.onTap,
    this.borderColor,
    this.fillColor,
    this.glow = false,
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
        glow: glow,
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          splashColor: (borderColor ?? OfficeTheme.primaryBrand).withValues(alpha: 0.15),
          highlightColor: (borderColor ?? OfficeTheme.primaryBrand).withValues(alpha: 0.08),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: content,
        ),
      ),
    );
  }
}
