import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/community_model.dart';
import '../../theme/app_theme.dart';
import '../common/app_image.dart';

/// Card horizontal "Komunitaku" — cover + nama + role badge.
class MyCommunityCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback? onTap;
  final bool isOwner;

  const MyCommunityCard({
    super.key,
    required this.community,
    this.onTap,
    this.isOwner = false,
  });

  Color _badgeBg(AppColors colors, String role) {
    if (isOwner) return colors.primaryOrange;
    switch (role) {
      case 'admin':
        return colors.primaryOrange.withOpacity(0.15);
      case 'moderator':
        return Colors.orange.withOpacity(0.18);
      default:
        return Colors.blue.withOpacity(0.15);
    }
  }

  Color _badgeFg(AppColors colors, String role) {
    if (isOwner) return Colors.white;
    switch (role) {
      case 'admin':
        return colors.primaryOrange;
      case 'moderator':
        return Colors.orange.shade800;
      default:
        return Colors.blue.shade700;
    }
  }

  String _badgeLabel(String role) {
    if (isOwner) return 'Pemilik';
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'moderator':
        return 'Moderator';
      default:
        return 'Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final role = community.myRole ?? 'member';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: AppImage(
                  url: community.coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: colors.primaryOrange.withOpacity(0.15),
                    child: Icon(Icons.landscape, color: colors.primaryOrange),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      community.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _badgeBg(colors, role),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _badgeLabel(role),
                        style: GoogleFonts.beVietnamPro(
                          color: _badgeFg(colors, role),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
