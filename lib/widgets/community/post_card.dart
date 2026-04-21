import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_config.dart';
import '../../models/community_post_model.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../level_avatar.dart';
import 'report_bottom_sheet.dart';
import '../video_player_widget.dart';

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
    final isVideo = post.imageUrl != null && 
                    (post.imageUrl!.toLowerCase().endsWith('.mp4') || 
                     post.imageUrl!.toLowerCase().endsWith('.mov'));

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
                LevelAvatar(
                  level: post.authorLevel,
                  radius: 18,
                  avatarUrl: post.authorAvatar,
                  name: post.authorName,
                ),
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
                    child: isVideo
                        ? VideoPlayerWidget(
                            url: AppConfig.resolveImageUrl(post.imageUrl),
                            autoPlay: true, // Instagram-like auto play
                            loop: true,
                          )
                        : Image.network(
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
          // Text-only post background tap area
          else if (post.content.isNotEmpty)
            GestureDetector(
              onDoubleTap: () {
                HapticFeedback.lightImpact();
                if (!widget.post.isLiked) widget.onLike?.call();
                setState(() => _showHeart = true);
                _heartController.forward(from: 0.0);
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) setState(() => _showHeart = false);
                });
              },
              onTap: widget.onTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                color: Colors.transparent,
              ),
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
                  label: post.commentCount > 0 ? '${post.commentCount}' : null,
                  onTap: widget.onTap,
                ),
                const SizedBox(width: 2),
                // Share
                _IGActionButton(
                  icon: Icons.send_outlined,
                  color: colors.textPrimary,
                  label: post.shareCount > 0 ? '${post.shareCount}' : null,
                  onTap: () async {
                    // Update share count to backend optimisticly
                    context.read<CommunityProvider>().sharePost(post.id, post.communityId);
                    // Open native share dialog
                    final shareText = 'Lihat postingan dari ${post.authorName} di komunitas ${post.communityName ?? "Petualang"}!\n${post.content}\n\nAyo gabung ke Petualang sekarang!';
                    await Share.share(shareText);
                  },
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
  final String? label;
  final VoidCallback? onTap;

  const _IGActionButton({required this.icon, required this.color, this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: color),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

