import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/explore_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/home/service_cards_grid.dart';
import '../widgets/home/hero_carousel.dart';
import '../widgets/home/upcoming_trip_card.dart';
import '../widgets/home/upcoming_booking_card.dart';
import '../widgets/home/rental_vendor_card.dart';
import '../widgets/home/home_article_card.dart';
import '../widgets/home/section_header.dart';
import 'main_wrapper.dart';
import 'explore/explore_screen.dart';
import 'explore/open_trip_list_screen.dart';
import 'explore/article_list_screen.dart';
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
        context.read<ExploreProvider>().fetchExploreData();
        context.read<BookingProvider>().fetchUpcomingBookings();
      });
    }
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<ExploreProvider>().fetchExploreData(),
      context.read<BookingProvider>().fetchUpcomingBookings(),
    ]);
  }

  void _openSearch() {
    final wrapper = context.findAncestorStateOfType<MainWrapperState>();
    if (wrapper != null) {
      wrapper.switchTab(1);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ExploreScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final exploreProvider = context.watch<ExploreProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final data = exploreProvider.exploreData;
    final isLoading = exploreProvider.isLoading && data == null;
    final upcomingBookings = bookingProvider.upcomingBookings;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: colors.primaryOrange,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Header (greeting + bell) ────────────────
              const SliverToBoxAdapter(child: _HomeGreeting()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Search bar ──────────────────────────────
              SliverToBoxAdapter(child: _SearchBar(onTap: _openSearch)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── 4 Service cards ─────────────────────────
              const SliverToBoxAdapter(child: ServiceCardsGrid()),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),

              // ── Hero carousel (top 3 open trips) ────────
              if (isLoading)
                const SliverToBoxAdapter(child: _HeroSkeleton())
              else if (data != null && data.heroCarousel.isNotEmpty)
                SliverToBoxAdapter(
                  child: HeroCarousel(trips: data.heroCarousel),
                )
              else if (data != null && data.openTrips.isNotEmpty)
                SliverToBoxAdapter(
                  child: HeroCarousel(
                    trips: data.openTrips.take(3).toList(),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 28)),

              // ── Trip Mendatang (CONDITIONAL — hide kalau user belum ada booking) ──
              if (upcomingBookings.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Trip Mendatang',
                    actionText: 'Lihat Semua',
                    onActionTap: () {
                      // Navigate ke "Pesanan" tab di bottom nav
                      final wrapper = context
                          .findAncestorStateOfType<MainWrapperState>();
                      wrapper?.switchTab(3);
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 230,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: upcomingBookings.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) =>
                          UpcomingBookingCard(booking: upcomingBookings[i]),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],

              // ── Open Trip section ───────────────────────
              if (data != null && data.openTrips.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Open Trip',
                    actionText: 'Lihat Semua',
                    onActionTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OpenTripListScreen(),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 270,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.openTrips.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) =>
                          UpcomingTripCard(trip: data.openTrips[i]),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],

              // ── Sewa Alat (top 5 vendors) ───────────────
              if (data != null && data.topVendors.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Sewa Alat',
                    actionText: 'Lihat Semua',
                    onActionTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RentalMainScreen(),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.topVendors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) =>
                          RentalVendorCard(vendor: data.topVendors[i]),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],

              // ── Artikel ─────────────────────────────────
              if (data != null && data.articles.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Artikel & Tips',
                    actionText: 'Lihat Semua',
                    onActionTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ArticleListScreen(),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 260,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.articles.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) =>
                          HomeArticleCard(article: data.articles[i]),
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Greeting header ─────────────────────────────────────────

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = context.watch<AuthProvider>().user;
    final firstName = user?.name.split(' ').first ?? 'Pendaki';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Halo, $firstName!',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('👋', style: TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Mau ke mana hari ini?',
                  style: GoogleFonts.beVietnamPro(
                    color: colors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _NotificationBell(),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.surface,
            border: Border.all(color: colors.border),
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: colors.textPrimary,
            size: 20,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEA4335),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Search bar ──────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: colors.textMuted, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Cari gunung, trip, atau alat...',
                  style: GoogleFonts.beVietnamPro(
                    color: colors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Loading skeleton ────────────────────────────────────────

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
      ),
    );
  }
}
