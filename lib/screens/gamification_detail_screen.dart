import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/gamification_models.dart';
import '../theme/app_theme.dart';
import '../widgets/level_avatar.dart';

class GamificationDetailScreen extends StatefulWidget {
  final UserGamificationProfile profile;
  final int initialIndex;

  const GamificationDetailScreen({
    super.key,
    required this.profile,
    this.initialIndex = 0,
  });

  @override
  State<GamificationDetailScreen> createState() => _GamificationDetailScreenState();
}

class _GamificationDetailScreenState extends State<GamificationDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.card,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        title: Text(
          'Detail Profil',
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.colors.primaryOrange,
          labelColor: context.colors.primaryOrange,
          unselectedLabelColor: context.colors.textSecondary,
          labelStyle: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Aktifitas'),
            Tab(text: 'Komunitas'),
            Tab(text: 'Pencapaian'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivitiesTab(),
          _buildCommunitiesTab(),
          _buildAchievementsTab(),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab() {
    final activities = widget.profile.activities;
    if (activities.isEmpty) {
      return Center(
        child: Text(
          'Belum ada rekam jejak aktifitas.',
          style: TextStyle(color: context.colors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final act = activities[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.colors.primaryOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIconForActivity(act.title),
                  color: context.colors.primaryOrange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      act.title,
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      act.description,
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.colors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.primaryOrange.withOpacity(0.5)),
                ),
                child: Text(
                  '${act.completions}x',
                  style: GoogleFonts.beVietnamPro(
                    color: context.colors.primaryOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunitiesTab() {
    final communities = widget.profile.communities;
    if (communities.isEmpty) {
      return Center(
        child: Text(
          'Belum bergabung dengan komunitas manapun.',
          style: TextStyle(color: context.colors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: communities.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comm = communities[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  comm.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.groups, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comm.name,
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.people_alt_rounded, size: 14, color: context.colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${comm.memberCount} Anggota',
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsTab() {
    final achievements = widget.profile.achievements;
    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'Belum ada pencapaian.',
          style: TextStyle(color: context.colors.textMuted),
        ),
      );
    }

    // Group achievements by tier
    final Map<int, List<Achievement>> groupedAchievements = {4: [], 3: [], 2: [], 1: []};
    for (var ach in achievements) {
      int achLevel = int.tryParse(ach.id.replaceAll(RegExp(r'\D'), '')) ?? (ach.title.length % 4 + 1);
      int tier = (achLevel > 4) ? 4 : (achLevel < 1 ? 1 : achLevel);
      groupedAchievements[tier]!.add(ach);
    }

    final tierTitles = {
      4: '💎 Diamond Tier',
      3: '🥇 Gold Tier',
      2: '🥈 Silver Tier',
      1: '🥉 Bronze Tier',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (int tier = 4; tier >= 1; tier--)
          if (groupedAchievements[tier]!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
              child: Text(
                tierTitles[tier]!,
                style: GoogleFonts.beVietnamPro(
                  color: context.colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ...groupedAchievements[tier]!.map((ach) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAchievementItem(ach, tier),
                )),
            const SizedBox(height: 16),
          ],
      ],
    );
  }

  Widget _buildAchievementItem(Achievement ach, int tier) {
    Color tierColor;
    IconData tierIcon;
    if (tier == 4) { tierColor = const Color(0xFF00E5FF); tierIcon = Icons.diamond_rounded; }
    else if (tier == 3) { tierColor = const Color(0xFFFFD700); tierIcon = Icons.workspace_premium_rounded; }
    else if (tier == 2) { tierColor = const Color(0xFFC0C0C0); tierIcon = Icons.military_tech_rounded; }
    else { tierColor = const Color(0xFFCD7F32); tierIcon = Icons.star_rounded; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ach.isUnlocked ? tierColor.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
        boxShadow: (ach.isUnlocked && tier >= 3) ? [
          BoxShadow(
            color: tierColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ach.isUnlocked ? LinearGradient(
                colors: [tierColor.withOpacity(0.8), tierColor.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              color: ach.isUnlocked ? null : Colors.grey.shade800,
              border: Border.all(color: ach.isUnlocked ? tierColor : Colors.transparent, width: 2),
            ),
            child: Icon(
              tierIcon,
              color: ach.isUnlocked ? Colors.white : Colors.grey.shade600,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ach.title,
                        style: GoogleFonts.beVietnamPro(
                          color: ach.isUnlocked ? context.colors.textPrimary : context.colors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (ach.isUnlocked)
                      const Icon(Icons.check_circle, color: Colors.green, size: 16)
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ach.description,
                  style: GoogleFonts.beVietnamPro(
                    color: context.colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForActivity(String title) {
    if (title.toLowerCase().contains('pendaki')) return Icons.terrain;
    if (title.toLowerCase().contains('lari')) return Icons.directions_run;
    if (title.toLowerCase().contains('kemah') || title.toLowerCase().contains('bivak')) return Icons.holiday_village;
    if (title.toLowerCase().contains('sepeda')) return Icons.directions_bike;
    return Icons.explore;
  }
}
