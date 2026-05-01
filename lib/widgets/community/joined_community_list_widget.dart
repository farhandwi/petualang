import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/community_model.dart';
import '../../screens/community/community_detail_screen.dart';
import '../../screens/community/community_discover_screen.dart';

class JoinedCommunityListWidget extends StatelessWidget {
  final List<CommunityModel> joinedCommunities;

  const JoinedCommunityListWidget({super.key, required this.joinedCommunities});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (joinedCommunities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.groups_rounded, size: 60, color: colors.textMuted),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Komunitas',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda belum bergabung dengan grup manapun. Temukan teman baru sekarang!',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CommunityDiscoverScreen()),
                ),
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Jelajahi Komunitas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: joinedCommunities.length + 1,
      itemBuilder: (context, index) {
        if (index == joinedCommunities.length) {
          // The last button "Jelajahi Komunitas Lainnya"
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommunityDiscoverScreen()),
              ),
              icon: Icon(Icons.search_rounded, color: colors.primaryOrange),
              label: Text(
                'Jelajahi Komunitas Lainnya',
                style: TextStyle(color: colors.primaryOrange, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.primaryOrange),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        }

        final community = joinedCommunities[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primaryOrange.withOpacity(0.1),
            ),
            child: community.iconImageUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(community.iconImageUrl!),
                  )
                : Center(
                    child: Text(
                      community.name[0].toUpperCase(),
                      style: TextStyle(
                        color: colors.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
          ),
          title: Text(
            community.name,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${community.memberCount} Anggota',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CommunityDetailScreen(community: community)),
            );
          },
        );
      },
    );
  }
}
