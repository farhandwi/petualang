import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../models/community_post_model.dart';
import '../../theme/app_theme.dart';
import 'like_button.dart';
import 'report_bottom_sheet.dart';

class PostCard extends StatefulWidget {
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
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  bool _showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _doubleTapLike() async {
    HapticFeedback.lightImpact();
    if (!widget.post.isLiked) {
      widget.onLike?.call();
    }
    setState(() => _showHeart = true);
    _heartController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() => _showHeart = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final post = widget.post;

    return Container(
      color: colors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                // Avatar
                _Avatar(name: post.authorName, avatarUrl: post.authorAvatar, size: 36),
                const SizedBox(width: 10),
                // Name + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.authorName,
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (widget.showCommunityName && post.communityName != null) ...[
                            Text('  ·  ',
                                style: GoogleFonts.beVietnamPro(
                                    color: colors.textMuted, fontSize: 12)),
                            Flexible(
                              child: Text(
                                post.communityName!,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 12,
                                  color: colors.primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _formatTime(post.createdAt),
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 11, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                // More button
                IconButton(
                  icon: Icon(Icons.more_horiz, color: colors.textSecondary, size: 20),
                  onPressed: () => ReportBottomSheet.show(
                    context,
                    targetType: 'post',
                    targetId: post.id,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Full-width Image (Instagram style) ──
          if (post.imageUrl != null)
            GestureDetector(
              onDoubleTap: _doubleTapLike,
              onTap: widget.onTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 1 / 1, // Square like Instagram default
                    child: Image.network(
                      AppConfig.resolveImageUrl(post.imageUrl),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (ctx, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colors.surface,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colors.primaryOrange,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          color: colors.border,
                          child: Icon(Icons.broken_image_rounded,
                              color: colors.textMuted, size: 48),
                        ),
                      ),
                    ),
                  ),
                  // Double-tap heart animation
                  if (_showHeart)
                    ScaleTransition(
                      scale: _heartScale,
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 90,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                      ),
                    ),
                ],
              ),
            )
          else
            // Text-only post — tap to open
            if (post.content.isNotEmpty)
              GestureDetector(
                onTap: widget.onTap,
                child: const SizedBox.shrink(),
              ),

          // ── Action Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 2),
            child: Row(
              children: [
                // Like
                _IGActionButton(
                  icon: post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: post.isLiked ? const Color(0xFFED4956) : colors.textPrimary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onLike?.call();
                  },
                ),
                const SizedBox(width: 2),
                // Comment
                _IGActionButton(
                  icon: Icons.mode_comment_outlined,
                  color: colors.textPrimary,
                  onTap: widget.onTap,
                ),
                const SizedBox(width: 2),
                // Share (decorative)
                _IGActionButton(
                  icon: Icons.send_outlined,
                  color: colors.textPrimary,
                  onTap: () {},
                ),
                const Spacer(),
                // Bookmark (decorative)
                _IGActionButton(
                  icon: Icons.bookmark_border_rounded,
                  color: colors.textPrimary,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // ── Like count ──
          if (post.likeCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 2),
              child: Text(
                '${post.likeCount} suka',
                style: GoogleFonts.beVietnamPro(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: colors.textPrimary),
              ),
            ),

          // ── Caption ──
          if (post.content.isNotEmpty)
            GestureDetector(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
                child: RichText(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${post.authorName} ',
                        style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: colors.textPrimary),
                      ),
                      TextSpan(
                        text: post.content,
                        style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: colors.textPrimary,
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Comment count ──
          if (post.commentCount > 0)
            GestureDetector(
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
                child: Text(
                  'Lihat ${post.commentCount} komentar',
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 13, color: colors.textMuted),
                ),
              ),
            ),

          // ── Bottom spacing / divider ──
          Divider(color: colors.border, height: 1, thickness: 1),
        ],
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

// ─────────────────────────────────────────────
// Instagram-style action icon button
// ─────────────────────────────────────────────
class _IGActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _IGActionButton({required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 26, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Avatar widget
// ─────────────────────────────────────────────
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colors.primaryOrange,
            colors.primaryOrange.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.beVietnamPro(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.4),
        ),
      ),
    );
  }
}
