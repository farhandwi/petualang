import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/buddy_post_model.dart';
import '../../theme/app_theme.dart';
import '../common/app_image.dart';
import '../level_avatar.dart';

class BuddyCard extends StatelessWidget {
  const BuddyCard({super.key, required this.buddy, required this.onTap});

  final BuddyPostModel buddy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mountain image header
            if (buddy.mountainImage != null)
              SizedBox(
                height: 100,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                      url: buddy.mountainImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: colors.primaryOrange.withOpacity(0.2)),
                    ),
                    Container(color: Colors.black.withOpacity(0.3)),
                    Positioned(
                      left: 14,
                      bottom: 12,
                      child: Text(
                        buddy.mountainName ?? 'Lokasi belum ditentukan',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      LevelAvatar(
                        level: buddy.userLevel ?? 1,
                        radius: 18,
                        avatarUrl: buddy.userPicture,
                        name: buddy.userName ?? '?',
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              buddy.userName ?? 'Anonim',
                              style: GoogleFonts.beVietnamPro(
                                color: colors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              dateFmt.format(buddy.targetDate),
                              style: GoogleFonts.beVietnamPro(
                                color: colors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SpotsChip(spotsLeft: buddy.spotsLeft),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    buddy.title,
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotsChip extends StatelessWidget {
  const _SpotsChip({required this.spotsLeft});
  final int spotsLeft;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isFull = spotsLeft <= 0;
    final color = isFull ? colors.textMuted : colors.primaryOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isFull ? 'Penuh' : 'Sisa $spotsLeft',
        style: GoogleFonts.beVietnamPro(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
