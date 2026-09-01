import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import 'glass_background.dart';
import 'office_3d_icon.dart';

class DocumentCard extends StatelessWidget {
  final OfficeDocument document;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dk önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    } else {
      return '${dt.day}.${dt.month}.${dt.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassCard(
      isDark: isDark,
      radius: 18,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      borderColor: document.brandColor.withValues(alpha: isDark ? 0.35 : 0.22),
      fillColor: isDark
          ? const Color(0xFF101B33).withValues(alpha: 0.75)
          : Colors.white.withValues(alpha: 0.88),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3D Parlak İkon Rozeti
          Office3DIcon.fromDocType(
            document.type,
            size: 48,
            withGlow: true,
          ),
          const SizedBox(width: 14),

          // Başlık ve Önizleme
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: document.brandColor.withValues(alpha: isDark ? 0.25 : 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: document.brandColor.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        document.typeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: document.brandColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  document.previewContent,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(document.lastModified),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${document.fileSizeKb} KB',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        OfficeStorage().toggleFavorite(document.id);
                      },
                      child: Icon(
                        document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 20,
                        color: document.isFavorite ? OfficeTheme.goldPro : (isDark ? Colors.white30 : Colors.black26),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Seçenekler Menüsü
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? Colors.cyanAccent.withValues(alpha: 0.25) : const Color(0xFFE2E8F0),
              ),
            ),
            color: isDark ? const Color(0xFF0F1A30) : Colors.white,
            onSelected: (val) {
              if (val == 'delete') {
                onDelete();
              } else if (val == 'favorite') {
                OfficeStorage().toggleFavorite(document.id);
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'favorite',
                child: Row(
                  children: [
                    Icon(
                      document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 18,
                      color: OfficeTheme.goldPro,
                    ),
                    const SizedBox(width: 10),
                    Text(document.isFavorite ? 'Yıldızı Kaldır' : 'Favorilere Ekle'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text('Belgeyi Sil', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
