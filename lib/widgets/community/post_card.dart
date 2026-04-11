import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../models/community_post_model.dart';
import '../../theme/app_theme.dart';
import 'like_button.dart';
import 'report_bottom_sheet.dart';

class PostCard extends StatelessWidget {
  final CommunityPostModel post;
  final bool showCommunityName;
  final VoidCallback? onLike;
  final VoidCallback? onTap;
  final int? currentUserId;

  const PostCard({
    super.key,
    required this.post,
    this.showCommunityName = true,
    this.onLike,
    this.onTap,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
              child: Row(
                children: [
                  _Avatar(name: post.authorName, avatarUrl: post.authorAvatar, size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: colors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            if (showCommunityName && post.communityName != null) ...[
                              Text(
                                post.communityName ?? 'Grup',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.primaryOrange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(' · ', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                            ],
                            Text(
                              _formatTime(post.createdAt),
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: colors.textSecondary),
                    onPressed: () => ReportBottomSheet.show(
                      context,
                      targetType: 'post',
                      targetId: post.id,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Text(
                  post.content,
                  style: TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.5),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Image
            if (post.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    AppConfig.resolveImageUrl(post.imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: colors.border,
                      child: Icon(Icons.broken_image_rounded, color: colors.textSecondary),
                    ),
                  ),
                ),
              ),

            // Action bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: Row(
                children: [
                  LikeButton(
                    isLiked: post.isLiked,
                    likeCount: post.likeCount,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 4),
                  _ActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: '${post.commentCount}',
                    onTap: onTap,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('d MMM', 'id_ID').format(dt);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;

  const _Avatar({required this.name, this.avatarUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(AppConfig.resolveImageUrl(avatarUrl)),
      );
    }
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.primaryOrange,
      child: Text(
        initials,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}
