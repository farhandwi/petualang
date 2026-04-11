import 'package:flutter/material.dart';
import '../../models/community_model.dart';
import '../../theme/app_theme.dart';

class CommunityCard extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;

  const CommunityCard({
    super.key,
    required this.community,
    this.onTap,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: community.coverImageUrl != null
                    ? Image.network(community.coverImageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _DefaultCover(category: community.category))
                    : _DefaultCover(category: community.category),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_rounded, size: 13, color: colors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${_formatCount(community.memberCount)} anggota',
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: community.isMember ? null : onJoin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: community.isMember ? Colors.transparent : colors.primaryOrange,
                        border: Border.all(
                          color: community.isMember ? colors.border : colors.primaryOrange,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        community.isMember ? 'Bergabung ✓' : 'Gabung',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: community.isMember ? colors.textSecondary : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}rb';
    return '$count';
  }
}

class _DefaultCover extends StatelessWidget {
  final String? category;
  const _DefaultCover({this.category});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final icon = _iconForCategory(category);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryOrange.withOpacity(0.8), colors.primaryOrange.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(icon, size: 36, color: Colors.white.withOpacity(0.8))),
    );
  }

  IconData _iconForCategory(String? cat) {
    switch (cat) {
      case 'Pendakian': return Icons.terrain_rounded;
      case 'Camping': return Icons.cabin_rounded;
      case 'Fotografi': return Icons.camera_alt_rounded;
      default: return Icons.people_rounded;
    }
  }
}
