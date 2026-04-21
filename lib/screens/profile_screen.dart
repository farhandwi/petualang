import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import '../models/gamification_models.dart';
import '../widgets/level_avatar.dart';
import 'gamification_detail_screen.dart';
import 'identity_verification_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserGamificationProfile? _gamificationProfile;
  bool _isLoadingGamification = true;
  String? _selectedActivityId;

  @override
  void initState() {
    super.initState();
    _fetchGamificationData();
  }

  Future<void> _fetchGamificationData() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;
    
    setState(() {
      _isLoadingGamification = true;
    });
    
    try {
      final res = await http.get(
        Uri.parse('http://10.0.2.2:8080/api/gamification/me'),
        headers: {'Authorization': 'Bearer ${auth.token}'},
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            _gamificationProfile = UserGamificationProfile.fromJson(data['gamification']);
            _isLoadingGamification = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching gamification: $e');
    }
    
    if (mounted) {
      setState(() {
        _isLoadingGamification = false;
      });
    }
  }

  void _openGamificationDetail(int index) {
    if (_gamificationProfile == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GamificationDetailScreen(
          profile: _gamificationProfile!,
          initialIndex: index,
        ),
      ),
    );
  }

  void _onActivityTapped(String activityId) {
    setState(() {
      if (_selectedActivityId == activityId) {
        _selectedActivityId = null; // Unselect
      } else {
        _selectedActivityId = activityId;
      }
    });
  }

  Color _getLevelBorderColor(int level, BuildContext context) {
    if (level < 3) return Colors.brown.shade400; // Bronze
    if (level < 10) return Colors.grey.shade400; // Silver
    if (level < 21) return Colors.amber; // Gold
    if (level < 40) return Colors.cyanAccent; // Platinum/Diamond
    return Colors.purpleAccent; // Max/Legend
  }

  String _getLevelTitle(int level) {
    if (level < 3) return 'Pemula';
    if (level < 10) return 'Petualang Muda';
    if (level < 21) return 'Penguasa Jalur';
    if (level < 40) return 'Penakluk Semesta';
    return 'Legenda Hidup';
  }

  IconData _getActivityIcon(String assetName) {
    switch (assetName) {
      case 'terrain':
        return Icons.terrain_rounded;
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'holiday_village':
        return Icons.holiday_village_rounded;
      case 'groups':
        return Icons.groups_rounded;
      case 'pedal_bike':
        return Icons.pedal_bike_rounded;
      case 'filter_hdr':
        return Icons.filter_hdr_rounded;
      default:
        return Icons.local_activity_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null || _isLoadingGamification) {
      return const Center(child: CircularProgressIndicator());
    }

    final gamification = _gamificationProfile;
    if (gamification == null) {
      return Center(
        child: Text('Gagal memuat profil gamifikasi', style: TextStyle(color: context.colors.textPrimary)),
      );
    }

    final borderColor = _getLevelBorderColor(gamification.level, context);

    // Apply Filter based on selected activity
    final filteredCommunities = _selectedActivityId == null
        ? gamification.communities
        : gamification.communities.where((c) => c.activityId == _selectedActivityId).toList();
        
    final filteredAchievements = _selectedActivityId == null
        ? gamification.achievements
        : gamification.achievements.where((a) => a.activityId == _selectedActivityId).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 80,
            pinned: true,
            backgroundColor: context.colors.surface,
            elevation: 0,
            title: Text(
              'Profil Petualang',
              style: GoogleFonts.beVietnamPro(
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh Profil',
                onPressed: _fetchGamificationData,
                color: context.colors.primaryOrange,
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
                color: context.colors.textPrimary,
              )
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Header Gamification
                  Row(
                    children: [
                      // Avatar with Global LevelAvatar
                      LevelAvatar(
                        name: user.name,
                        avatarUrl: user.profilePicture,
                        level: gamification.level,
                        radius: 45,
                      ),
                      const SizedBox(width: 20),
                      // User Detail & Level
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: GoogleFonts.beVietnamPro(
                                color: context.colors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: borderColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: borderColor.withOpacity(0.5)),
                              ),
                              child: Text(
                                'Lv ${gamification.level} • ${_getLevelTitle(gamification.level)}',
                                style: GoogleFonts.beVietnamPro(
                                  color: context.colors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // EXP Bar
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (gamification.currentExp / gamification.nextLevelExp).clamp(0.0, 1.0),
                                      backgroundColor: context.colors.textMuted
                                          .withOpacity(0.2),
                                      color: borderColor,
                                      minHeight: 8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${gamification.currentExp} / ${gamification.nextLevelExp} XP',
                                  style: GoogleFonts.beVietnamPro(
                                    color: context.colors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Summary Stats
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: context.colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => _openGamificationDetail(0),
                          child: _buildStatItem(context, '${gamification.totalActivities}', 'Aktifitas'),
                        ),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                        GestureDetector(
                          onTap: () => _openGamificationDetail(1),
                          child: _buildStatItem(context, '${gamification.totalCommunities}', 'Komunitas'),
                        ),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                        GestureDetector(
                          onTap: () => _openGamificationDetail(2),
                          child: _buildStatItem(context, '${gamification.unlockedAchievements}', 'Pencapaian'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Verifikasi Identitas Card ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 28, bottom: 4),
              child: _buildVerificationCard(context, user.verificationStatus),
            ),
          ),

          // Keahlian / Aktifitas Section
          SliverToBoxAdapter(
            child: _buildSectionTitle(context, 'Rekam Jejak Aktifitas'),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: gamification.activities.length,
                itemBuilder: (context, index) {
                  final act = gamification.activities[index];
                  final isSelected = _selectedActivityId == act.id;
                  
                  return GestureDetector(
                    onTap: () => _onActivityTapped(act.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? context.colors.primaryOrange.withOpacity(0.2) : context.colors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? context.colors.primaryOrange : Colors.white.withOpacity(0.05),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: context.colors.primaryOrange.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.colors.primaryOrange.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getActivityIcon(act.iconAsset),
                                color: context.colors.primaryOrange, size: 28),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            act.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.beVietnamPro(
                              color: context.colors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${act.completions} Selesai',
                            style: GoogleFonts.beVietnamPro(
                              color: context.colors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Komunitas Section
          if (filteredCommunities.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _buildSectionTitle(context, 'Bivak Komunitas'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredCommunities.length,
                  itemBuilder: (context, index) {
                    final com = filteredCommunities[index];
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(com.imageUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.4),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              com.name,
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.people_rounded,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '${com.memberCount} Anggota',
                                  style: GoogleFonts.beVietnamPro(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          
          if (filteredCommunities.isEmpty && _selectedActivityId != null)
            SliverToBoxAdapter(
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                 child: Text('Belum ada komunitas untuk aktivitas ini.', style: TextStyle(color: context.colors.textMuted)),
               ),
            ),

          // Pencapaian (Achievements) Section
          SliverToBoxAdapter(
            child: _buildSectionTitle(context, 'Hall of Fame'),
          ),
          
          if (filteredAchievements.isEmpty)
             SliverToBoxAdapter(
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                 child: Text('Tidak ada pencapaian di grup ini.', style: TextStyle(color: context.colors.textMuted)),
               ),
            ),
            
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ach = filteredAchievements[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ach.isUnlocked 
                          ? context.colors.card 
                          : context.colors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ach.isUnlocked
                            ? context.colors.primaryOrange.withOpacity(0.3)
                            : Colors.transparent,
                        width: ach.isUnlocked ? 1.5 : 0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Badge Image
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: ach.isUnlocked
                                    ? Colors.amber
                                    : Colors.grey.withOpacity(0.3),
                                width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: ColorFiltered(
                              colorFilter: ach.isUnlocked
                                  ? const ColorFilter.mode(
                                      Colors.transparent, BlendMode.multiply)
                                  : const ColorFilter.mode(
                                      Colors.grey, BlendMode.saturation),
                              child: Image.network(
                                ach.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.emoji_events, color: Colors.grey.withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Detail
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
                                        color: ach.isUnlocked
                                            ? context.colors.textPrimary
                                            : context.colors.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (ach.isUnlocked)
                                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ach.activityType,
                                style: GoogleFonts.beVietnamPro(
                                  color: context.colors.primaryOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ach.description,
                                style: GoogleFonts.beVietnamPro(
                                  color: context.colors.textMuted,
                                  fontSize: 12,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                childCount: filteredAchievements.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Text(
        title,
        style: GoogleFonts.beVietnamPro(
          color: context.colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildVerificationCard(BuildContext context, String status) {
    final colors = context.colors;
    const Color accent = Color(0xFF00B894);
    const Color accentDark = Color(0xFF00A67E);
    const Color amber = Color(0xFFFFC107);

    // Config per-status — hanya brand colors yang hardcode, sisanya pakai AppColors
    final IconData icon;
    final Color iconBg;
    final Color iconColor;
    final String badgeText;
    final Color badgeBg;
    final Color badgeColor;
    final String title;
    final String subtitle;
    final String btnText;
    final List<Color> btnGradient;
    final Color borderColor;
    final Color? glowColor;

    switch (status) {
      case 'pending':
        icon = Icons.hourglass_top_rounded;
        iconBg = amber.withAlpha(30);
        iconColor = amber;
        badgeText = 'Sedang Diproses';
        badgeBg = amber.withAlpha(30);
        badgeColor = amber;
        title = 'Verifikasi dalam Review';
        subtitle = 'Data Anda sedang diproses tim kami. Biasanya selesai dalam 1×24 jam.';
        btnText = 'Lihat Status';
        btnGradient = [amber, const Color(0xFFFF9800)];
        borderColor = amber.withAlpha(80);
        glowColor = amber;
        break;
      case 'verified':
        icon = Icons.verified_rounded;
        iconBg = accent.withAlpha(30);
        iconColor = accent;
        badgeText = 'Terverifikasi';
        badgeBg = accent.withAlpha(30);
        badgeColor = accent;
        title = 'Identitas Terverifikasi ✓';
        subtitle = 'Identitas Anda telah diverifikasi. Nikmati akses penuh ke semua fitur.';
        btnText = 'Lihat Detail';
        btnGradient = [accent, accentDark];
        borderColor = accent.withAlpha(80);
        glowColor = accent;
        break;
      case 'rejected':
        icon = Icons.cancel_outlined;
        iconBg = colors.error.withAlpha(30);
        iconColor = colors.error;
        badgeText = 'Ditolak';
        badgeBg = colors.error.withAlpha(25);
        badgeColor = colors.error;
        title = 'Verifikasi Ditolak';
        subtitle = 'Verifikasi sebelumnya ditolak. Silakan kirim ulang dengan dokumen yang valid.';
        btnText = 'Coba Lagi';
        btnGradient = [colors.error, colors.error.withAlpha(200)];
        borderColor = colors.error.withAlpha(80);
        glowColor = colors.error;
        break;
      default: // unverified
        icon = Icons.shield_outlined;
        iconBg = colors.input;
        iconColor = colors.textMuted;
        badgeText = 'Belum Diverifikasi';
        badgeBg = colors.input;
        badgeColor = colors.textMuted;
        title = 'Verifikasi Identitas';
        subtitle = 'Lengkapi verifikasi untuk membuka akses penuh ke semua fitur Petualang.';
        btnText = 'Mulai Verifikasi';
        btnGradient = [accent, accentDark];
        borderColor = colors.border;
        glowColor = null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const IdentityVerificationScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: glowColor != null
                ? [
                    BoxShadow(
                      color: glowColor.withAlpha(40),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badgeText,
                            maxLines: 1,
                            style: GoogleFonts.poppins(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: btnGradient),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            btnText,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    ),
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
