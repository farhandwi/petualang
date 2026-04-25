import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../config/app_config.dart';
import '../../models/explore_model.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late int likesCount;
  late int shareCount;
  late int commentsCount;
  bool isLiked = false;
  List<dynamic> comments = [];
  bool isLoadingComments = true;
  final TextEditingController _commentController = TextEditingController();
  void Function(void Function())? _setStateSheet;

  @override
  void initState() {
    super.initState();
    likesCount = widget.article.likesCount;
    shareCount = widget.article.shareCount;
    commentsCount = widget.article.commentsCount;
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final response = await http.get(Uri.parse(
          '${AppConfig.baseUrlApi}/articles/${widget.article.id}/comments'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == 'success') {
          setState(() {
            comments = body['data'];
            commentsCount = comments.length;
            isLoadingComments = false;
          });
          _setStateSheet?.call(() {});
          return;
        }
      }
      setState(() => isLoadingComments = false);
      _setStateSheet?.call(() {});
    } catch (e) {
      print('Error fetching comments: $e');
      setState(() => isLoadingComments = false);
      _setStateSheet?.call(() {});
    }
  }

  Future<void> _toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likesCount++;
      } else {
        likesCount--;
      }
    });

    if (isLiked) {
      try {
        await http.post(Uri.parse(
            '${AppConfig.baseUrlApi}/articles/${widget.article.id}/like'));
      } catch (e) {
        print('Like failed: $e');
      }
    }
  }

  Future<void> _shareArticle() async {
    // In a real app, use share_plus plugin. For now, increment count
    setState(() {
      shareCount++;
    });
    try {
      await http.post(Uri.parse(
          '${AppConfig.baseUrlApi}/articles/${widget.article.id}/share'));
    } catch (e) {
      print('Share failed: $e');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tautan artikel disalin dan dibagikan!')),
    );
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Silakan login terlebih dahulu untuk berkomentar.')),
      );
      return;
    }

    _commentController.clear();
    FocusScope.of(context).unfocus();

    try {
      final response = await http.post(
        Uri.parse(
            '${AppConfig.baseUrlApi}/articles/${widget.article.id}/comments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'content': text}),
      );

      if (response.statusCode == 200) {
        _fetchComments(); // Reload comments
      }
    } catch (e) {
      print('Post comment failed: $e');
    }
  }

  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            _setStateSheet = setStateSheet;
            final colors = context.colors;
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    'Komentar ($commentsCount)',
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: isLoadingComments
                        ? Center(
                            child: CircularProgressIndicator(
                                color: colors.primaryOrange))
                        : comments.isEmpty
                            ? Center(
                                child: Text(
                                  'Belum ada komentar.',
                                  style: GoogleFonts.beVietnamPro(
                                      color: colors.textSecondary),
                                ),
                              )
                            : ListView.builder(
                                itemCount: comments.length,
                                itemBuilder: (context, index) {
                                  final comment = comments[index];
                                  final user = comment['user'];
                                  final date =
                                      DateTime.parse(comment['created_at']);
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: user['avatar'] != null
                                          ? NetworkImage(
                                              AppConfig.resolveImageUrl(
                                                  user['avatar']))
                                          : null,
                                      child: user['avatar'] == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    title: Text(
                                      user['name'] ?? 'User',
                                      style: GoogleFonts.beVietnamPro(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          comment['content'],
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 13,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('dd MMM yyyy, HH:mm')
                                              .format(date),
                                          style: GoogleFonts.beVietnamPro(
                                            fontSize: 10,
                                            color: colors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                  // Input Comment
                  Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                      top: 12,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      color: colors.card,
                      border: Border(top: BorderSide(color: colors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Tulis komentar...',
                              hintStyle: GoogleFonts.beVietnamPro(
                                  color: colors.textMuted),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: colors.background,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            style: GoogleFonts.beVietnamPro(
                                color: colors.textPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.send_rounded,
                              color: colors.primaryOrange),
                          onPressed: () {
                            _postComment();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _setStateSheet = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: colors.card,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.article.imageUrl != null
                  ? Image.asset(
                      widget
                          .article.imageUrl!, // Adjust if network image is used
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) =>
                          Container(color: colors.card),
                    )
                  : Container(color: colors.border),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.article.category,
                          style: GoogleFonts.beVietnamPro(
                            color: colors.primaryOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.remove_red_eye_rounded,
                              size: 14, color: colors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.article.viewCount}',
                            style: GoogleFonts.beVietnamPro(
                                color: colors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.article.title,
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colors.border,
                        child: Icon(Icons.person,
                            size: 16, color: colors.textMuted),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.article.author ?? 'Admin Petualang',
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy')
                                .format(widget.article.createdAt),
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.article.content,
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textPrimary,
                      fontSize: 16,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InteractionButton(
                icon: isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isLiked ? Colors.red : colors.textSecondary,
                count: likesCount,
                label: 'Suka',
                onTap: _toggleLike,
              ),
              _InteractionButton(
                icon: Icons.chat_bubble_outline_rounded,
                color: colors.textSecondary,
                count: commentsCount,
                label: 'Komentar',
                onTap: _showCommentsSheet,
              ),
              _InteractionButton(
                icon: Icons.share_rounded,
                color: colors.textSecondary,
                count: shareCount,
                label: 'Bagikan',
                onTap: _shareArticle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              count > 0 ? '$count' : label,
              style: GoogleFonts.beVietnamPro(
                color: color,
                fontSize: 12,
                fontWeight: count > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
