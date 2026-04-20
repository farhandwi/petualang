import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/community_post_model.dart';
import '../../models/community_comment_model.dart';
import '../../widgets/community/report_bottom_sheet.dart';
import '../../widgets/level_avatar.dart';
import 'package:share_plus/share_plus.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final int communityId;

  const PostDetailScreen({super.key, required this.postId, required this.communityId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen>
    with SingleTickerProviderStateMixin {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final FocusNode _focusNode = FocusNode();
  File? _imageFile;
  int? _replyToId;
  String? _replyToName;
  bool _isSubmitting = false;

  // Double-tap heart
  bool _showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.4), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _heartController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _heartController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _removeImage() => setState(() => _imageFile = null);

  void _setReply(int id, String name) {
    setState(() {
      _replyToId = id;
      _replyToName = name;
      _commentController.text = '@$name ';
    });
    _focusNode.requestFocus();
  }

  void _clearReply() {
    setState(() {
      _replyToId = null;
      _replyToName = null;
      _commentController.clear();
    });
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<CommunityProvider>();
    await provider.createComment(
      postId: widget.postId,
      content: _commentController.text.trim(),
      parentId: _replyToId,
      imageFile: _imageFile,
    );

    if (mounted) {
      _commentController.clear();
      setState(() {
        _isSubmitting = false;
        _replyToId = null;
        _replyToName = null;
        _imageFile = null;
      });
    }
  }

  void _doubleTapLike(CommunityProvider provider, CommunityPostModel post) async {
    HapticFeedback.lightImpact();
    if (!post.isLiked) {
      provider.toggleLike(post.id, widget.communityId);
    }
    setState(() => _showHeart = true);
    _heartController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _showHeart = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<CommunityProvider>();
    final post = [...provider.globalFeed, ...(provider.postsByGroup[widget.communityId] ?? [])]
        .where((p) => p.id == widget.postId)
        .firstOrNull;
    final comments = provider.commentsByPost[widget.postId] ?? [];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Postingan',
          style: GoogleFonts.beVietnamPro(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                // ── Post Content ──
                if (post != null) ...[
                  // Header: Avatar + Name + More button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    child: Row(
                      children: [
                        _IGAvatar(name: post.authorName, url: post.authorAvatar, size: 36, level: post.authorLevel),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.authorName,
                                style: GoogleFonts.beVietnamPro(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (post.communityName != null)
                                Text(
                                  post.communityName!,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 11.5,
                                    color: colors.primaryOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.more_horiz, color: colors.textSecondary, size: 22),
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

                  // Full-width image with double-tap like
                  if (post.imageUrl != null)
                    GestureDetector(
                      onDoubleTap: () => _doubleTapLike(provider, post),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              AppConfig.resolveImageUrl(post.imageUrl),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (ctx, child, prog) {
                                if (prog == null) return child;
                                return Container(
                                  color: colors.surface,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: colors.primaryOrange,
                                      value: prog.expectedTotalBytes != null
                                          ? prog.cumulativeBytesLoaded / prog.expectedTotalBytes!
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
                          if (_showHeart)
                            ScaleTransition(
                              scale: _heartScale,
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 90,
                                shadows: [Shadow(color: Colors.black26, blurRadius: 12)],
                              ),
                            ),
                        ],
                      ),
                    ),

                  // Action bar (Instagram style)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 12, 0),
                    child: Row(
                      children: [
                        _IGActionBtn(
                          icon: post.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: post.isLiked ? const Color(0xFFED4956) : colors.textPrimary,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            provider.toggleLike(post.id, widget.communityId);
                          },
                        ),
                        _IGActionBtn(
                          icon: Icons.mode_comment_outlined,
                          color: colors.textPrimary,
                          label: post.commentCount > 0 ? '${post.commentCount}' : null,
                          onTap: () => _focusNode.requestFocus(),
                        ),
                        _IGActionBtn(
                          icon: Icons.send_outlined,
                          color: colors.textPrimary,
                          label: post.shareCount > 0 ? '${post.shareCount}' : null,
                          onTap: () async {
                            provider.sharePost(post.id, widget.communityId);
                            final shareText = 'Lihat postingan dari ${post.authorName} di komunitas ${post.communityName ?? "Petualang"}!\n${post.content}\n\nAyo gabung ke Petualang sekarang!';
                            await Share.share(shareText);
                          },
                        ),
                        const Spacer(),
                        _IGActionBtn(
                          icon: Icons.bookmark_border_rounded,
                          color: colors.textPrimary,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  // Like count
                  if (post.likeCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 0),
                      child: Text(
                        '${post.likeCount} suka',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),

                  // Caption (name bold + content)
                  if (post.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${post.authorName} ',
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: colors.textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: post.content,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                color: colors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Timestamp
                  if (post.createdAt != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                      child: Text(
                        _formatDate(post.createdAt!),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: colors.textMuted,
                        ),
                      ),
                    ),

                  Divider(color: colors.border, height: 1, thickness: 0.5),

                  // "Komentar" header
                  if (comments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                      child: Text(
                        'Komentar',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                ],

                // ── Comments list (Instagram-style flat) ──
                ...comments.map((c) => _IGCommentTile(
                      comment: c,
                      onReply: () => _setReply(c.id, c.authorName),
                    )),

                if (comments.isEmpty && post != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Jadilah yang pertama berkomentar',
                        style: GoogleFonts.beVietnamPro(
                          color: colors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── Reply Indicator ──
          if (_replyToName != null)
            Container(
              color: colors.primaryOrange.withValues(alpha: 0.08),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Membalas @$_replyToName',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: colors.primaryOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearReply,
                    child: Icon(Icons.close_rounded, size: 16, color: colors.primaryOrange),
                  ),
                ],
              ),
            ),

          // ── Comment Input Bar (Instagram style) ──
          Container(
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(top: BorderSide(color: colors.border, width: 0.5)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview
                  if (_imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 44),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _imageFile!,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -10,
                            right: -10,
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(3),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Current user avatar
                      _IGAvatar(
                        name: context.read<AuthProvider>().user?.name ?? 'U',
                        url: context.read<AuthProvider>().user?.profilePicture,
                        size: 32,
                        level: context.read<AuthProvider>().user?.level ?? 1,
                      ),
                      const SizedBox(width: 10),

                      // Input field
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.border),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  focusNode: _focusNode,
                                  maxLines: 5,
                                  minLines: 1,
                                  style: GoogleFonts.beVietnamPro(
                                    color: colors.textPrimary,
                                    fontSize: 13.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: _replyToName != null
                                        ? 'Balas @$_replyToName...'
                                        : 'Tambahkan komentar...',
                                    hintStyle: GoogleFonts.beVietnamPro(
                                      color: colors.textMuted,
                                      fontSize: 13.5,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  textCapitalization: TextCapitalization.sentences,
                                ),
                              ),
                              // Image picker
                              GestureDetector(
                                onTap: _pickImage,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6, bottom: 2),
                                  child: Icon(
                                    Icons.photo_outlined,
                                    color: colors.textMuted,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Send button
                      GestureDetector(
                        onTap: _isSubmitting ? null : _submitComment,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.primaryOrange,
                                  ),
                                )
                              : Text(
                                  'Kirim',
                                  style: GoogleFonts.beVietnamPro(
                                    color: colors.primaryOrange,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('d MMMM yyyy', 'id_ID').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────────
// Instagram-style Comment Tile
// ─────────────────────────────────────────────────────────────────
class _IGCommentTile extends StatelessWidget {
  final CommunityCommentModel comment;
  final VoidCallback onReply;

  const _IGCommentTile({required this.comment, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IGAvatar(name: comment.authorName, url: comment.authorAvatar, size: 32, level: comment.authorLevel),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + content on same line (Instagram style)
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${comment.authorName} ',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: colors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: comment.content,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: colors.textPrimary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Comment image
                    if (comment.imageUrl != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          AppConfig.resolveImageUrl(comment.imageUrl),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ],

                    // Timestamp + actions row
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            _timeAgo(comment.createdAt),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: colors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: onReply,
                            child: Text(
                              'Balas',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => ReportBottomSheet.show(
                              context,
                              targetType: 'comment',
                              targetId: comment.id,
                            ),
                            child: Text(
                              'Laporkan',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Heart icon on right (Instagram)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.favorite_border_rounded, size: 14, color: colors.textMuted),
              ),
            ],
          ),

          // Replies (threaded, indented)
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 10),
              child: Column(
                children: comment.replies.map((reply) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IGAvatar(name: reply.authorName, url: reply.authorAvatar, size: 26, level: reply.authorLevel),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${reply.authorName} ',
                                    style: GoogleFonts.beVietnamPro(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: reply.content,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12.5,
                                      color: context.colors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                _timeAgo(reply.createdAt),
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 11,
                                  color: context.colors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Icon(Icons.favorite_border_rounded,
                            size: 12, color: context.colors.textMuted),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),

          const SizedBox(height: 4),
          Divider(color: colors.border, height: 1, thickness: 0.3),
        ],
      ),
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}j';
    if (diff.inDays < 7) return '${diff.inDays}h';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}mgg';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}bln';
    return '${(diff.inDays / 365).floor()}thn';
  }
}

// ─────────────────────────────────────────────────────────────────
// IG Action Button
// ─────────────────────────────────────────────────────────────────
class _IGActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback? onTap;

  const _IGActionBtn({required this.icon, required this.color, this.label, this.onTap});

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

// ─────────────────────────────────────────────────────────────────
// Instagram-style Avatar
// ─────────────────────────────────────────────────────────────────
class _IGAvatar extends StatelessWidget {
  final String name;
  final String? url;
  final double size;
  final int level;

  const _IGAvatar({required this.name, this.url, required this.size, this.level = 1});

  @override
  Widget build(BuildContext context) {
    return LevelAvatar(
      level: level,
      radius: size / 2,
      avatarUrl: url,
      name: name,
    );
  }
}
