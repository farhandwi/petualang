import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/community_post_model.dart';
import '../../theme/app_theme.dart';
import '../common/app_image.dart';
import '../level_avatar.dart';

/// Tile post di tab Diskusi.
class CommunityPostCard extends StatelessWidget {
  final CommunityPostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + time + pin
          Row(
            children: [
              LevelAvatar(
                level: post.authorLevel,
                radius: 18,
                avatarUrl: post.authorAvatar,
                name: post.authorName,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      _timeAgo(post.createdAt),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (post.isPinned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.push_pin_rounded,
                          size: 12, color: colors.primaryOrange),
                      const SizedBox(width: 3),
                      Text(
                        'PIN',
                        style: GoogleFonts.beVietnamPro(
                          color: colors.primaryOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.content,
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              height: 1.4,
              color: colors.textPrimary,
            ),
          ),
          if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppImage(
                url: post.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: colors.background,
                  child: Icon(Icons.broken_image_rounded, color: colors.textMuted),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: colors.border, height: 1),
          const SizedBox(height: 6),
          Row(
            children: [
              _PostAction(
                icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: post.isLiked ? Colors.red.shade400 : colors.textSecondary,
                label: '${post.likeCount}',
                onTap: onLike,
              ),
              const SizedBox(width: 16),
              _PostAction(
                icon: Icons.chat_bubble_outline_rounded,
                color: colors.textSecondary,
                label: '${post.commentCount}',
                onTap: onComment,
              ),
              const Spacer(),
              _PostAction(
                icon: Icons.share_outlined,
                color: colors.textSecondary,
                label: 'Bagikan',
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _PostAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
