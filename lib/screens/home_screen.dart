import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../models/community_model.dart';
import '../providers/explore_provider.dart';
import '../models/mountain_model.dart';
import '../models/explore_model.dart';
import 'booking/mountain_list_screen.dart';
import 'community/community_detail_screen.dart';
import 'community/community_screen.dart';
import 'main_wrapper.dart';
import 'explore/open_trip_list_screen.dart';
import 'rental/rental_main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CommunityProvider>().fetchTrendingCommunities();
        context.read<ExploreProvider>().fetchExploreData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final firstName = user?.name.split(' ').first ?? 'Pendaki';
    final communityProvider = context.watch<CommunityProvider>();
    final exploreProvider = context.watch<ExploreProvider>();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Bar Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $firstName! 👋',
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Siap untuk\nPuncak?',
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: context.colors.primaryOrange,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primaryOrange.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          firstName[0].toUpperCase(),
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Slogan Subtitle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  'Temukan perlengkapan dan teman mendaki terbaik untuk trip selanjutnya.',
                  style: GoogleFonts.beVietnamPro(
                    color: context.colors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Layanan Utama Section
            _SectionTitle(title: 'Layanan Utama', onActionTap: () {}),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildListDelegate([
                  _ServiceItem(
                    icon: Icons.people_rounded,
                    label: 'Komunitas',
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CommunityScreen()),
                      );
                    },
                  ),
                  _ServiceItem(
                    icon: Icons.map_rounded,
                    label: 'Trip\nTerbuka',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OpenTripListScreen()),
                      );
                    },
                  ),
                  _ServiceItem(
                    icon: Icons.backpack_rounded,
                    label: 'Sewa\nAlat',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RentalMainScreen()),
                      );
                    },
                  ),
                  _ServiceItem(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Pesan\nTiket',
                    color: context.colors.primaryOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MountainListScreen()),
                      );
                    },
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Petualangan Mendatang Section
            _SectionTitle(title: 'Petualangan Mendatang', actionText: 'Lihat Semua', onActionTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OpenTripListScreen()),
              );
            }),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/event_1.png'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          context.colors.background.withOpacity(0.9),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.primaryOrange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'SEGERA',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ekspedisi Puncak Segara Anak',
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people_alt_rounded, color: context.colors.textSecondary, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              '8 orang bergabung',
                              style: GoogleFonts.beVietnamPro(
                                color: context.colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Komunitas Trending Section ────────────────────────
            _SectionTitle(
              title: 'Komunitas Aktif',
              actionText: 'Lihat Semua',
              onActionTap: () {},
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 185,
                child: communityProvider.isLoadingTrending
                    ? _TrendingShimmer()
                    : communityProvider.trendingCommunities.isEmpty
                        ? _TrendingEmpty()
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            itemCount: communityProvider.trendingCommunities.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final community = communityProvider.trendingCommunities[index];
                              return _TrendingCommunityCard(
                                community: community,
                                rank: index + 1,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CommunityDetailScreen(community: community),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Destinasi Populer Section (From Explore Screen)
            if (exploreProvider.isLoading && exploreProvider.exploreData == null)
              const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryOrange),
                ),
              )
            else if (exploreProvider.exploreData != null) ...[
              if (exploreProvider.exploreData!.popularMountains.isNotEmpty) ...[
                _SectionTitle(title: 'Destinasi Populer', actionText: 'Lihat Semua', onActionTap: () {}),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 240,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: exploreProvider.exploreData!.popularMountains.length,
                      itemBuilder: (context, index) {
                        return _MountainHeroCard(
                          mountain: exploreProvider.exploreData!.popularMountains[index],
                        );
                      },
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Edukasi & Tips Petualang Section (From Explore Screen)
              if (exploreProvider.exploreData!.articles.isNotEmpty) ...[
                _SectionTitle(title: 'Edukasi & Tips Petualang', onActionTap: () {}),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _ArticleCard(
                        article: exploreProvider.exploreData!.articles[index],
                      ),
                      childCount: exploreProvider.exploreData!.articles.length,
                    ),
                  ),
                ),
              ],
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback onActionTap;

  const _SectionTitle({
    required this.title,
    this.actionText,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.beVietnamPro(
                color: context.colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (actionText != null)
              GestureDetector(
                onTap: onActionTap,
                child: Text(
                  actionText!,
                  style: GoogleFonts.beVietnamPro(
                    color: context.colors.primaryOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ServiceItem({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trending Community Card ─────────────────────────────
class _TrendingCommunityCard extends StatelessWidget {
  final CommunityModel community;
  final int rank;
  final VoidCallback onTap;

  const _TrendingCommunityCard({
    required this.community,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: community.coverImageUrl != null
                        ? Image.network(
                            AppConfig.resolveImageUrl(community.coverImageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _CoverFallback(name: community.name),
                          )
                        : _CoverFallback(name: community.name),
                  ),
                ),
                // Rank badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? const Color(0xFFFFD700)
                          : rank == 2
                              ? const Color(0xFFC0C0C0)
                              : rank == 3
                                  ? const Color(0xFFCD7F32)
                                  : colors.primaryOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.beVietnamPro(
                        color: rank <= 3 ? Colors.black87 : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_alt_rounded, color: colors.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(community.memberCount),
                        style: GoogleFonts.beVietnamPro(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (community.category != null) ...[ 
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.primaryOrange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              community.category!,
                              style: GoogleFonts.beVietnamPro(
                                color: colors.primaryOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
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
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}rb Anggota';
    }
    return '$count Anggota';
  }
}

class _CoverFallback extends StatelessWidget {
  final String name;
  const _CoverFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryOrange,
            colors.primaryOrange.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'K',
          style: GoogleFonts.beVietnamPro(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer Skeleton saat loading ───────────────────────
class _TrendingShimmer extends StatefulWidget {
  @override
  State<_TrendingShimmer> createState() => _TrendingShimmerState();
}

class _TrendingShimmerState extends State<_TrendingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, __) => Container(
          width: 200,
          decoration: BoxDecoration(
            color: colors.card.withOpacity(_animation.value + 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  color: colors.border.withOpacity(_animation.value + 0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 120, color: colors.border.withOpacity(_animation.value + 0.2), margin: const EdgeInsets.only(bottom: 8)),
                    Container(height: 10, width: 80, color: colors.border.withOpacity(_animation.value + 0.1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ─────────────────────────────────────────
class _TrendingEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 40, color: colors.textMuted),
            const SizedBox(height: 8),
            Text(
              'Belum ada komunitas aktif',
              style: GoogleFonts.beVietnamPro(
                color: colors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MountainHeroCard extends StatelessWidget {
  final MountainModel mountain;

  const _MountainHeroCard({required this.mountain});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: AssetImage(mountain.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
            stops: const [0.4, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Text(
                mountain.difficulty,
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mountain.name,
              style: GoogleFonts.beVietnamPro(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mountain.location,
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${mountain.elevation} mdpl',
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final ArticleModel article;

  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark 
            ? Border.all(color: Colors.white.withOpacity(0.05))
            : Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: article.imageUrl != null 
                  ? DecorationImage(
                      image: AssetImage(article.imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
                color: isDark ? Colors.black12 : Colors.grey.shade100,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.category,
                    style: GoogleFonts.beVietnamPro(
                      color: colors.primaryOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      article.title,
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(article.createdAt),
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textSecondary,
                      fontSize: 10,
                    ),
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
