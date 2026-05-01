import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/explore_provider.dart';
import '../../providers/events_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/explore/explore_mountain_card.dart';
import '../../widgets/explore/explore_trip_card.dart';
import '../../widgets/explore/explore_event_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ExploreProvider>().fetchExploreData();
        context.read<EventsProvider>().fetchEvents();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<ExploreProvider>().fetchExploreData(),
      context.read<EventsProvider>().fetchEvents(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Jelajah',
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const Spacer(),
                  _IconButton(
                    icon: Icons.map_outlined,
                    onTap: () => _showSoon(context, 'Peta destinasi'),
                  ),
                  const SizedBox(width: 8),
                  _IconButton(
                    icon: Icons.tune_rounded,
                    onTap: () => _showSoon(context, 'Filter'),
                  ),
                ],
              ),
            ),

            // ── Search ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
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
                    Icon(Icons.search_rounded,
                        color: colors.textMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cari destinasi, trip, event…',
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

            // ── TabBar ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: colors.primaryOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Gunung'),
                    Tab(text: 'Trip'),
                    Tab(text: 'Event'),
                  ],
                ),
              ),
            ),

            // ── Tab content ──────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _MountainsTab(onRefresh: _onRefresh),
                  _TripsTab(onRefresh: _onRefresh),
                  _EventsTab(onRefresh: _onRefresh),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature segera hadir')),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: colors.textPrimary, size: 18),
      ),
    );
  }
}

// ─── Tabs ─────────────────────────────────────────────────────

class _MountainsTab extends StatelessWidget {
  const _MountainsTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<ExploreProvider>();
    final data = provider.exploreData;

    if (provider.isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final mountains = data?.popularMountains ?? const [];
    if (mountains.isEmpty) {
      return _Empty(
        icon: Icons.landscape_outlined,
        message: 'Belum ada destinasi gunung.',
      );
    }

    return RefreshIndicator(
      color: colors.primaryOrange,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: mountains.length,
        itemBuilder: (_, i) =>
            ExploreMountainCard(mountain: mountains[i]),
      ),
    );
  }
}

class _TripsTab extends StatelessWidget {
  const _TripsTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<ExploreProvider>();
    final data = provider.exploreData;

    if (provider.isLoading && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final trips = data?.openTrips ?? const [];
    if (trips.isEmpty) {
      return _Empty(
        icon: Icons.map_outlined,
        message: 'Belum ada open trip.',
      );
    }

    return RefreshIndicator(
      color: colors.primaryOrange,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: trips.length,
        itemBuilder: (_, i) => ExploreTripCard(trip: trips[i]),
      ),
    );
  }
}

class _EventsTab extends StatelessWidget {
  const _EventsTab({required this.onRefresh});
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<EventsProvider>();

    if (provider.isLoading && provider.events.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.events.isEmpty) {
      return _Empty(
        icon: Icons.event_outlined,
        message: 'Belum ada event mendatang.',
      );
    }

    return RefreshIndicator(
      color: colors.primaryOrange,
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: provider.events.length,
        itemBuilder: (_, i) =>
            ExploreEventCard(event: provider.events[i]),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.textMuted, size: 56),
            const SizedBox(height: 12),
            Text(
              message,
              style: GoogleFonts.beVietnamPro(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
