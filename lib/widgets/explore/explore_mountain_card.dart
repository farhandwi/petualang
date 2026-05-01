import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/mountain_model.dart';
import '../../theme/app_theme.dart';
import '../../screens/booking/mountain_detail_screen.dart';
import '../common/app_image.dart';

/// Card destinasi gunung untuk Jelajah — sesuai mockup:
/// big image + difficulty badge + rating + name + location + elevation + price + CTA
class ExploreMountainCard extends StatelessWidget {
  const ExploreMountainCard({super.key, required this.mountain});

  final MountainModel mountain;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final priceFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image with overlays ────────────────────────
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  url: mountain.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: colors.primaryOrange.withOpacity(0.12),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.landscape_rounded,
                      color: colors.primaryOrange,
                      size: 48,
                    ),
                  ),
                ),
                // Difficulty badge top-left
                Positioned(
                  top: 12,
                  left: 12,
                  child: _DifficultyBadge(difficulty: mountain.difficulty),
                ),
                // Rating top-right
                if (mountain.rating > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFBBC05),
                            size: 14,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            mountain.rating.toStringAsFixed(1),
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Info section ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        mountain.name,
                        style: GoogleFonts.beVietnamPro(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Mulai dari',
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          priceFmt.format(mountain.price),
                          style: GoogleFonts.beVietnamPro(
                            color: colors.primaryOrange,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: colors.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        mountain.location,
                        style: GoogleFonts.beVietnamPro(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.terrain_rounded,
                      color: colors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${mountain.elevation} m',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MountainDetailScreen(mountain: mountain),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Lihat Detail',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});
  final String difficulty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        difficulty,
        style: GoogleFonts.beVietnamPro(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
