import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/community/post_card.dart';
import 'community_discover_screen.dart';
import 'community_detail_screen.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Use addPostFrameCallback to avoid "setState() during build" error
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }
  }

  Future<void> _loadData() async {
    final provider = context.read<CommunityProvider>();
    await Future.wait([
      provider.fetchFeed(refresh: true),
      provider.fetchCommunities(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final auth = context.watch<AuthProvider>();
    final community = context.watch<CommunityProvider>();
    final joinedCommunities = community.communities.where((c) => c.isMember).toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: colors.primaryOrange,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Sticky AppBar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: colors.background,
              elevation: 0,
              title: Text(
                'Komunitas',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
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

            // My Groups horizontal
            if (joinedCommunities.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Grup Saya',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: colors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CommunityDiscoverScreen()),
                            ),
                            child: Text('Jelajahi', style: TextStyle(color: colors.primaryOrange, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    // Instagram-style Stories bar
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        scrollDirection: Axis.horizontal,
                        itemCount: joinedCommunities.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 14),
                        itemBuilder: (_, i) {
                          final c = joinedCommunities[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CommunityDetailScreen(community: c)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Story ring
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF05A19), Color(0xFFFF9A5C), Color(0xFFF05A19)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: colors.background,
                                      shape: BoxShape.circle,
                                    ),
                                    child: _GroupAvatar(community: c, size: 56),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: 66,
                                  child: Text(
                                    c.name,
                                    style: TextStyle(fontSize: 11, color: colors.textPrimary, fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

            // Discover banner
            if (joinedCommunities.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _DiscoverBanner(onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CommunityDiscoverScreen()),
                  )),
                ),
              ),

            // Divider (Instagram thick separator between stories & feed)
            SliverToBoxAdapter(
              child: Divider(color: colors.border, thickness: 1, height: 1),
            ),

            // Feed
            if (community.isLoadingFeed && community.globalFeed.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (community.globalFeed.isEmpty)
              SliverFillRemaining(
                child: _EmptyFeed(
                  onDiscover: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CommunityDiscoverScreen()),
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

class _GroupAvatar extends StatelessWidget {
  final dynamic community;
  final double size;
  const _GroupAvatar({required this.community, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colors.primaryOrange.withValues(alpha: 0.8), colors.primaryOrange.withValues(alpha: 0.4)],
        ),
      ),
      child: community.iconImageUrl != null
          ? CircleAvatar(backgroundImage: NetworkImage(community.iconImageUrl!))
          : Center(
              child: Text(
                community.name.isNotEmpty ? community.name[0].toUpperCase() : 'G',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.38),
              ),
            ),
    );
  }
}

class _DiscoverBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _DiscoverBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primaryOrange, colors.primaryOrange.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.explore_rounded, color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Temukan Komunitas!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bergabung dan mulai berbagi petualanganmu',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final VoidCallback onDiscover;
  const _EmptyFeed({required this.onDiscover});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
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
            onPressed: onDiscover,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Jelajahi Komunitas'),
          ),
        ],
      ),
    );
  }
}
