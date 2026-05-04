import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/community_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import '../../widgets/community/category_chip.dart';
import '../../widgets/community/community_card.dart';
import '../../widgets/community/my_community_card.dart';
import '../../widgets/community/popular_community_card.dart';
import 'community_detail_screen.dart';
import 'create_community_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final p = context.read<CommunityProvider>();
    await Future.wait([
      p.fetchCommunities(),
      p.fetchTrendingCommunities(),
    ]);
  }

  String _formatBigNumber(int n) {
    if (n >= 1000) {
      final s = n.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        buf.write(s[i]);
        final remain = s.length - i - 1;
        if (remain > 0 && remain % 3 == 0) buf.write('.');
      }
      return buf.toString();
    }
    return '$n';
  }

  void _openDetail(CommunityModel c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CommunityDetailScreen(community: c)),
    );
  }

  Future<void> _join(CommunityModel c) async {
    final provider = context.read<CommunityProvider>();
    await provider.joinCommunity(c.id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<CommunityProvider>();
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final ownedComm = provider.ownedCommunitiesFor(currentUserId);
    final myComm = provider.myCommunities
        .where((c) => !c.isOwnedBy(currentUserId))
        .toList();
    final popular = provider.trendingCommunities.isNotEmpty
        ? provider.trendingCommunities
        : provider.communities.take(5).toList();
    final all = provider.filteredAllCommunities;

    final hPad = context.responsive<double>(
        mobile: 16, tablet: 28, desktop: 36);
    final allCols = context.gridColumns(
        mobile: 2, tablet: 3, desktop: 4, large: 5);

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: colors.primaryOrange,
        onRefresh: _refresh,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: Breakpoints.maxContentWidth),
            child: CustomScrollView(
          slivers: [
            // ─── Header gradient ───────────────────────────────
            SliverToBoxAdapter(
              child: _Header(
                totalMembers: provider.totalMembersGlobal,
                formatNumber: _formatBigNumber,
                onCreate: () async {
                  final created = await Navigator.push<CommunityModel?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateCommunityScreen(),
                    ),
                  );
                  if (created != null && mounted) {
                    await _refresh();
                    if (!mounted) return;
                    _openDetail(created);
                  }
                },
                searchController: _searchController,
                onSearch: (q) => provider.setSearch(q),
              ),
            ),

            // ─── Category chips ────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = provider.categories[i];
                    return CategoryChip(
                      label: cat,
                      selected: provider.selectedCategory == cat,
                      onTap: () => provider.setCategory(cat),
                    );
                  },
                ),
              ),
            ),

            // ─── Komunitas Buatan Saya ─────────────────────────
            if (ownedComm.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: _SectionHeader(title: 'Komunitas Buatan Saya'),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 230,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: ownedComm.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => MyCommunityCard(
                      community: ownedComm[i],
                      isOwner: true,
                      onTap: () => _openDetail(ownedComm[i]),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],

            // ─── Komunitaku (selain yang dia buat) ─────────────
            if (myComm.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Komunitas yang Saya Ikuti',
                  trailing: 'Lihat Semua',
                  onTrailing: () {
                    // already showing all below
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 230,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: myComm.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => MyCommunityCard(
                      community: myComm[i],
                      onTap: () => _openDetail(myComm[i]),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ],

            // ─── Komunitas Populer ─────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'Komunitas Populer'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverList.separated(
                itemCount: popular.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final c = popular[i];
                  return PopularCommunityCard(
                    community: c,
                    onTap: () => _openDetail(c),
                    onJoin: () =>
                        c.isMember ? _openDetail(c) : _join(c),
                  );
                },
              ),
            ),

            // ─── Semua Komunitas ───────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Semua Komunitas',
                trailingIcon: Icons.tune_rounded,
              ),
            ),
            if (provider.isLoadingCommunities && all.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (all.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Tidak ada komunitas yang cocok.',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: allCols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final c = all[i];
                      return CommunityCard(
                        community: c,
                        onTap: () => _openDetail(c),
                        onJoin: () =>
                            c.isMember ? _openDetail(c) : _join(c),
                      );
                    },
                    childCount: all.length,
                  ),
                ),
              ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final int totalMembers;
  final String Function(int) formatNumber;
  final VoidCallback onCreate;
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;

  const _Header({
    required this.totalMembers,
    required this.formatNumber,
    required this.onCreate,
    required this.searchController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6B3A1A),
            colors.primaryOrange,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Komunitas',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${formatNumber(totalMembers)} pendaki bergabung',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onCreate,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Buat',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: onSearch,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
              hintText: 'Cari komunitas...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.18),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final IconData? trailingIcon;
  final VoidCallback? onTrailing;

  const _SectionHeader({
    required this.title,
    this.trailing,
    this.trailingIcon,
    this.onTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.beVietnamPro(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
          ),
          if (trailing != null)
            GestureDetector(
              onTap: onTrailing,
              child: Text(
                trailing!,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryOrange,
                ),
              ),
            ),
          if (trailingIcon != null)
            Icon(trailingIcon, color: colors.textSecondary, size: 20),
        ],
      ),
    );
  }
}
