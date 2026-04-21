import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/community/post_card.dart';
import '../community/community_discover_screen.dart';
import '../community/create_post_screen.dart';
import '../community/post_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<CommunityProvider>();
        provider.fetchFeed(refresh: true);
        provider.fetchCommunities();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final auth = context.watch<AuthProvider>();
    final community = context.watch<CommunityProvider>();
    final joinedCommunities = community.communities.where((c) => c.isMember).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Jelajah Petualangan',
          style: GoogleFonts.beVietnamPro(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: colors.textPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunityDiscoverScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colors.primaryOrange,
        onRefresh: () => community.fetchFeed(refresh: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (community.isLoadingFeed && community.globalFeed.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
              )
            else if (community.globalFeed.isEmpty)
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 72, color: colors.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        'Feed kosong',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bergabung ke komunitas untuk melihat postingan dari sesama petualang',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CommunityDiscoverScreen()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Jelajahi Komunitas'),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    if (i == community.globalFeed.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: TextButton(
                            onPressed: () => community.fetchFeed(),
                            child: Text('Muat lebih banyak',
                                style: TextStyle(color: colors.primaryOrange)),
                          ),
                        ),
                      );
                    }
                    final post = community.globalFeed[i];
                    return PostCard(
                      post: post,
                      currentUserId: auth.user?.id,
                      onLike: () => community.toggleLike(post.id, post.communityId),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) =>
                            PostDetailScreen(postId: post.id, communityId: post.communityId)),
                      ),
                    );
                  },
                  childCount: community.globalFeed.length + 1,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (joinedCommunities.isEmpty) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityDiscoverScreen()));
          } else {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => CreatePostScreen(communityId: joinedCommunities.first.id),
              ),
            );
            
            if (result == true && mounted) {
              context.read<CommunityProvider>().fetchFeed(refresh: true);
            }
          }
        },
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Buat Post'),
        backgroundColor: colors.primaryOrange,
        foregroundColor: Colors.white,
      ),
    );
  }
}
