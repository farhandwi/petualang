import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/explore_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/explore_model.dart';
import '../../models/mountain_model.dart';
import 'open_trip_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().fetchExploreData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.colors.primaryOrange,
          onRefresh: () => provider.fetchExploreData(),
          child: CustomScrollView(
            slivers: [
              // HEADER & SEARCH
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jelajah\nPetualangan',
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isDark 
                            ? Border.all(color: Colors.white.withOpacity(0.1))
                            : Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: context.colors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.beVietnamPro(
                                  color: context.colors.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Cari gunung, trip, tips...',
                                  hintStyle: GoogleFonts.beVietnamPro(
                                    color: context.colors.textSecondary,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(label: 'Semua', isSelected: true, context: context),
                            _FilterChip(label: 'Gunung', context: context),
                            _FilterChip(label: 'Event Trip', context: context),
                            _FilterChip(label: 'Tips & Berita', context: context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (provider.isLoading && provider.exploreData == null)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryOrange),
                  ),
                )
              else if (provider.error != null && provider.exploreData == null)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      provider.error!,
                      style: GoogleFonts.beVietnamPro(color: context.colors.error),
                    ),
                  ),
                )
              else if (provider.exploreData != null) ...[
                  
                // POPULAR MOUNTAINS CAROUSEL
                if (provider.exploreData!.popularMountains.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Destinasi Populer',
                            style: GoogleFonts.beVietnamPro(
                              color: context.colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Lihat Semua',
                            style: GoogleFonts.beVietnamPro(
                              color: context.colors.primaryOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 240,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.exploreData!.popularMountains.length,
                        itemBuilder: (context, index) {
                          return _MountainHeroCard(
                            mountain: provider.exploreData!.popularMountains[index],
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // OPEN TRIPS HORIZONTAL LIST
                if (provider.exploreData!.openTrips.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Event & Open Trip',
                            style: GoogleFonts.beVietnamPro(
                              color: context.colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 180,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.exploreData!.openTrips.length,
                        itemBuilder: (context, index) {
                          return _OpenTripCard(
                            trip: provider.exploreData!.openTrips[index],
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // ARTICLES MASONRY/GRID
                if (provider.exploreData!.articles.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Text(
                        'Edukasi & Tips Petualang',
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _ArticleCard(
                          article: provider.exploreData!.articles[index],
                        ),
                        childCount: provider.exploreData!.articles.length,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final BuildContext context;

  const _FilterChip({
    required this.label,
    this.isSelected = false,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isSelected 
        ? context.colors.primaryOrange 
        : (isDark ? const Color(0xFF2C2C2E) : Colors.white);
    
    final textColor = isSelected 
        ? Colors.white 
        : context.colors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: !isSelected 
            ? Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200)
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          color: textColor,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

class _OpenTripCard extends StatelessWidget {
  final OpenTripModel trip;

  const _OpenTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OpenTripDetailScreen(trip: trip),
          ),
        );
      },
      child: Container(
        width: 320,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark 
            ? Border.all(color: Colors.white.withOpacity(0.05))
            : Border.all(color: Colors.grey.shade100),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: trip.imageUrl != null
                ? Image.asset(trip.imageUrl!, width: 110, height: 180, fit: BoxFit.cover)
                : Container(
                    width: 110,
                    color: context.colors.primaryOrange.withOpacity(0.1),
                    child: Icon(Icons.event_note, color: context.colors.primaryOrange),
                  ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    trip.title,
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 14, color: context.colors.primaryOrange),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('dd').format(trip.startDate)} - ${DateFormat('dd MMM').format(trip.endDate)}',
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.group_rounded, size: 14, color: context.colors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.currentParticipants}/${trip.maxParticipants} Kuota',
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(trip.price),
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.primaryOrange,
                      fontSize: 14,
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
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final ArticleModel article;

  const _ArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      color: context.colors.primaryOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      article.title,
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
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
                      color: context.colors.textSecondary,
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
