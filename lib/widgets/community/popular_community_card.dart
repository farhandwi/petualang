import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/community_model.dart';
import '../../theme/app_theme.dart';
import '../common/app_image.dart';

/// Card horizontal "Komunitas Populer" — cover kiri + info + tombol gabung.
class PopularCommunityCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  const PopularCommunityCard({
    super.key,
    required this.community,
    this.onTap,
    this.onJoin,
  });

  String _formatCount(int n) {
    if (n >= 1000) {
      final k = (n / 1000).toStringAsFixed(1);
      return '${k.endsWith('.0') ? k.substring(0, k.length - 2) : k}K';
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 84,
                height: 84,
                child: AppImage(
                  url: community.coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: colors.primaryOrange.withOpacity(0.15),
                    child: Icon(Icons.landscape, color: colors.primaryOrange),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          community.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (community.onlineCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${community.category ?? '-'} · ${_formatCount(community.memberCount)} anggota',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          color: Colors.amber.shade700, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        community.rating.toStringAsFixed(1),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· ${community.onlineCount} aktif',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _JoinButton(
              joined: community.isMember,
              onPressed: onJoin,
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final bool joined;
  final VoidCallback? onPressed;
  const _JoinButton({required this.joined, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: joined ? Colors.transparent : colors.primaryOrange.withOpacity(0.08),
            border: Border.all(color: colors.primaryOrange, width: 1.4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            joined ? '✓ Anggota' : '+ Gabung',
            style: GoogleFonts.beVietnamPro(
              color: colors.primaryOrange,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
