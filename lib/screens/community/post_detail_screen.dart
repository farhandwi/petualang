import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/community_comment_model.dart';
import '../../widgets/community/like_button.dart';
import '../../widgets/community/report_bottom_sheet.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final int communityId;

  const PostDetailScreen({super.key, required this.postId, required this.communityId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _imageFile;
  int? _replyToId;
  String? _replyToName;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _removeImage() {
    setState(() => _imageFile = null);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<CommunityProvider>();
    final auth = context.watch<AuthProvider>();
    final post = [...provider.globalFeed, ...(provider.postsByGroup[widget.communityId] ?? [])]
        .where((p) => p.id == widget.postId)
        .firstOrNull;
    final comments = provider.commentsByPost[widget.postId] ?? [];

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Postingan', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // Post content
                if (post != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author row
                        Row(
                          children: [
                            _Avatar(name: post.authorName, url: post.authorAvatar, size: 44),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.authorName, style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary)),
                                if (post.communityName != null)
                                  Text(post.communityName!, style: TextStyle(fontSize: 12, color: colors.primaryOrange)),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(Icons.more_horiz, color: colors.textSecondary),
                              onPressed: () => ReportBottomSheet.show(context, targetType: 'post', targetId: post.id),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(post.content, style: TextStyle(fontSize: 15, color: colors.textPrimary, height: 1.6)),
                        if (post.imageUrl != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              AppConfig.resolveImageUrl(post.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Like bar
                        Row(
                          children: [
                            LikeButton(
                              isLiked: post.isLiked,
                              likeCount: post.likeCount,
                              onTap: () => provider.toggleLike(post.id, widget.communityId),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.mode_comment_outlined, size: 18, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Text('${post.commentCount}', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(color: colors.border, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text('Komentar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: colors.textPrimary)),
                  ),
                ],

                // Comments
                ...comments.map((c) => _CommentTile(
                      comment: c,
                      onReply: () => setState(() {
                        _replyToId = c.id;
                        _replyToName = c.authorName;
                        FocusScope.of(context).requestFocus(FocusNode());
                        _commentController.text = '@${c.authorName} ';
                      }),
                    )),

                if (comments.isEmpty && post != null)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('Belum ada komentar. Jadilah yang pertama!',
                          style: TextStyle(color: colors.textSecondary)),
                    ),
                  ),
              ],
            ),
          ),

          // Reply indicator
          if (_replyToName != null)
            Container(
              color: colors.primaryOrange.withOpacity(0.08),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Membalas @$_replyToName',
                      style: TextStyle(fontSize: 12, color: colors.primaryOrange),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() { _replyToId = null; _replyToName = null; _commentController.clear(); }),
                    child: Icon(Icons.close, size: 16, color: colors.primaryOrange),
                  ),
                ],
              ),
            ),

          // Comment input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            decoration: BoxDecoration(
              color: colors.background,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 44),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_imageFile!, height: 80, width: 80, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                              onPressed: _removeImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      _Avatar(name: auth.user?.name ?? 'U', url: auth.user?.profilePicture, size: 36),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _commentController,
                                  maxLines: 3,
                                  minLines: 1,
                                  decoration: InputDecoration(
                                    hintText: 'Tulis komentar...',
                                    hintStyle: TextStyle(color: colors.textSecondary),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  style: TextStyle(color: colors.textPrimary, fontSize: 14),
                                  textCapitalization: TextCapitalization.sentences,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.image_outlined, color: colors.textSecondary, size: 20),
                                onPressed: _pickImage,
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _isSubmitting ? null : _submitComment,
                        icon: _isSubmitting
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primaryOrange))
                            : Icon(Icons.send_rounded, color: colors.primaryOrange),
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
}

class _CommentTile extends StatelessWidget {
  final CommunityCommentModel comment;
  final VoidCallback onReply;

  const _CommentTile({required this.comment, required this.onReply});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(name: comment.authorName, url: comment.authorAvatar, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(comment.authorName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: colors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(comment.content, style: TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.5)),
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
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: onReply,
                            child: Text('Balas', style: TextStyle(fontSize: 12, color: colors.primaryOrange, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => ReportBottomSheet.show(context, targetType: 'comment', targetId: comment.id),
                            child: Text('Laporkan', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Replies
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Column(
                children: comment.replies.map((reply) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Avatar(name: reply.authorName, url: reply.authorAvatar, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reply.authorName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: colors.textPrimary)),
                              Text(reply.content, style: TextStyle(fontSize: 13, color: colors.textPrimary, height: 1.4)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final String? url;
  final double size;

  const _Avatar({required this.name, this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(AppConfig.resolveImageUrl(url)),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: context.colors.primaryOrange,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.4),
      ),
    );
  }
}
