import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/explore_model.dart';
import '../../theme/app_theme.dart';
import '../../screens/explore/article_detail_screen.dart';
import '../common/app_image.dart';

class HomeArticleCard extends StatelessWidget {
  const HomeArticleCard({super.key, required this.article});

  final ArticleModel article;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 240,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: AppImage(
                  url: article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(colors),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.primaryOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        article.category.toUpperCase(),
                        style: GoogleFonts.beVietnamPro(
                          color: colors.primaryOrange,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title,
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            color: colors.textMuted, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${article.viewCount}',
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.favorite_outline_rounded,
                            color: colors.textMuted, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${article.likesCount}',
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(AppColors colors) => Container(
        color: colors.primaryOrange.withOpacity(0.12),
        alignment: Alignment.center,
        child: Icon(
          Icons.article_rounded,
          color: colors.primaryOrange,
          size: 32,
        ),
      );
}
