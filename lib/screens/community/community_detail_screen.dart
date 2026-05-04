import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/community_event_model.dart';
import '../../models/community_model.dart';
import '../../models/community_rule_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_post_provider.dart';
import '../../providers/community_provider.dart';
import '../../services/dm_api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/permission_helper.dart';
import '../../widgets/common/app_image.dart';
import '../../widgets/community/community_post_card.dart';
import '../../widgets/level_avatar.dart';
import 'edit_community_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final CommunityModel community;
  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (_initialized) return;
    _initialized = true;
    final id = widget.community.id;
    final p = context.read<CommunityProvider>();
    final posts = context.read<CommunityPostProvider>();
    await Future.wait([
      p.fetchCommunityDetail(id),
      p.fetchMembers(id),
      p.fetchEvents(id),
      p.fetchPhotos(id),
      p.fetchRules(id),
      p.fetchMyRating(id),
      posts.loadPosts(id, refresh: true),
    ]);
  }

  Future<void> _toggleJoin(CommunityModel c) async {
    final provider = context.read<CommunityProvider>();
    if (c.isMember) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Keluar Komunitas'),
          content: Text('Yakin ingin keluar dari ${c.name}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (ok == true) await provider.leaveCommunity(c.id);
    } else {
      await provider.joinCommunity(c.id);
    }
  }

  Future<void> _showRatingDialog(CommunityModel c) async {
    if (!c.isMember) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bergabung dulu untuk memberi rating'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final provider = context.read<CommunityProvider>();
    int stars = provider.myRatingStars ?? 5;
    final ok = await showDialog<int>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Beri Rating'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return IconButton(
                onPressed: () => setS(() => stars = i + 1),
                icon: Icon(
                  i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber.shade700,
                  size: 32,
                ),
              );
            }),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, stars),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (ok != null) {
      await provider.submitRating(c.id, ok);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<CommunityProvider>();
    final c = provider.selectedCommunity ?? widget.community;
    final currentUserId = context.watch<AuthProvider>().user?.id;
    final canManage =
        c.isOwnedBy(currentUserId) || c.myRole == 'admin' || c.myRole == 'moderator';

    return Scaffold(
      backgroundColor: colors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: colors.background,
            leading: _CircleIconButton(
              icon: Icons.arrow_back_ios_rounded,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              if (canManage)
                _CircleIconButton(
                  icon: Icons.settings_rounded,
                  onTap: () => _openManageSheet(c),
                ),
              if (canManage) const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.share_rounded,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tautan komunitas disalin')),
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    url: c.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: colors.primaryOrange.withOpacity(0.5),
                    ),
                  ),
                  Container(color: Colors.black26),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _CommunityHeader(
              community: c,
              onJoinToggle: () => _toggleJoin(c),
              onRate: () => _showRatingDialog(c),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBar(
              TabBar(
                controller: _tab,
                isScrollable: false,
                labelColor: colors.primaryOrange,
                unselectedLabelColor: colors.textSecondary,
                indicatorColor: colors.primaryOrange,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w800, fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.beVietnamPro(
                  fontWeight: FontWeight.w700, fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Diskusi'),
                  Tab(text: 'Kegiatan'),
                  Tab(text: 'Foto'),
                  Tab(text: 'Anggota'),
                  Tab(text: 'Aturan'),
                ],
              ),
              colors.background,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: [
            _DiskusiTab(community: c),
            _KegiatanTab(events: provider.selectedEvents),
            _FotoTab(photos: provider.selectedPhotos),
            _AnggotaTab(members: provider.selectedMembers),
            _AturanTab(
              rules: provider.selectedRules,
              canEdit: c.myRole == 'admin' || c.myRole == 'moderator',
              onEdit: () => _editRules(provider, c.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openManageSheet(CommunityModel c) async {
    final colors = context.colors;
    final provider = context.read<CommunityProvider>();
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Kelola Komunitas',
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            Text(
              c.name,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _ManageOption(
              icon: Icons.gavel_rounded,
              iconColor: colors.primaryOrange,
              title: 'Edit Aturan',
              subtitle: 'Atur peraturan komunitas',
              onTap: () {
                Navigator.pop(sheetCtx);
                _editRules(provider, c.id);
              },
            ),
            _ManageOption(
              icon: Icons.people_alt_rounded,
              iconColor: Colors.blue.shade600,
              title: 'Kelola Anggota',
              subtitle: 'Lihat dan atur anggota komunitas',
              onTap: () {
                Navigator.pop(sheetCtx);
                _tab.animateTo(3);
              },
            ),
            _ManageOption(
              icon: Icons.event_rounded,
              iconColor: Colors.purple.shade600,
              title: 'Tambah Kegiatan',
              subtitle: 'Buat acara/event komunitas',
              onTap: () {
                Navigator.pop(sheetCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur tambah kegiatan segera hadir')),
                );
              },
            ),
            _ManageOption(
              icon: Icons.edit_rounded,
              iconColor: Colors.teal.shade600,
              title: 'Edit Informasi',
              subtitle: 'Ubah nama, deskripsi, kategori, poster',
              onTap: () async {
                Navigator.pop(sheetCtx);
                await Navigator.push<CommunityModel?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditCommunityScreen(community: c),
                  ),
                );
                if (mounted) {
                  await provider.fetchCommunityDetail(c.id);
                }
              },
            ),
            if (c.isOwnedBy(context.read<AuthProvider>().user?.id))
              _ManageOption(
                icon: Icons.delete_outline_rounded,
                iconColor: Colors.red.shade600,
                title: 'Hapus Komunitas',
                subtitle: 'Tindakan ini tidak bisa dibatalkan',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur hapus komunitas segera hadir')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editRules(CommunityProvider provider, int communityId) async {
    final controllers = provider.selectedRules.isEmpty
        ? [TextEditingController()]
        : provider.selectedRules
            .map((r) => TextEditingController(text: r.text))
            .toList();
    final result = await showDialog<List<String>?>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Edit Aturan'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...List.generate(controllers.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: TextField(
                      controller: controllers[i],
                      decoration: InputDecoration(
                        labelText: 'Aturan ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Aturan'),
                  onPressed: () => setS(() => controllers.add(TextEditingController())),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx,
                  controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList()),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      await provider.saveRules(communityId, result);
    }
  }
}

// ─── Header (info card + stats + active members) ─────────────

class _CommunityHeader extends StatelessWidget {
  final CommunityModel community;
  final VoidCallback onJoinToggle;
  final VoidCallback onRate;

  const _CommunityHeader({
    required this.community,
    required this.onJoinToggle,
    required this.onRate,
  });

  String _formatCount(int n) {
    if (n >= 1000) {
      final k = (n / 1000).toStringAsFixed(1);
      return '${k.endsWith('.0') ? k.substring(0, k.length - 2) : k}K';
    }
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<CommunityProvider>();
    final activeMembers = provider.selectedMembers
        .where((m) => m['is_online'] == true)
        .toList();

    return Container(
      color: colors.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E4C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: AppImage(
                  url: community.iconImageUrl ?? community.coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.landscape_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      '${community.category ?? '-'} · ${community.location ?? 'Indonesia'}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: community.isMember ? Colors.transparent : colors.primaryOrange,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: colors.primaryOrange, width: 1.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: InkWell(
                  onTap: onJoinToggle,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          community.isMember ? Icons.check_rounded : Icons.add_rounded,
                          size: 18,
                          color: community.isMember ? colors.primaryOrange : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          community.isMember ? 'Anggota' : 'Gabung',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: community.isMember ? colors.primaryOrange : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (community.description != null && community.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              community.description!,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                height: 1.5,
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _StatCell(
                  value: _formatCount(community.memberCount),
                  label: 'Member',
                ),
                _StatCell(
                  value: '${community.onlineCount}',
                  label: 'Online',
                ),
                _StatCell(
                  value: community.rating.toStringAsFixed(1),
                  label: 'Rating',
                  onTap: onRate,
                ),
                _StatCell(
                  value: '${community.eventCount}',
                  label: 'Acara',
                ),
              ],
            ),
          ),
          if (activeMembers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  height: 28,
                  width: (activeMembers.length.clamp(0, 3) * 18 + 14).toDouble(),
                  child: Stack(
                    children: List.generate(
                      activeMembers.length.clamp(0, 3),
                      (i) => Positioned(
                        left: i * 18.0,
                        child: LevelAvatar(
                          radius: 14,
                          name: (activeMembers[i]['name'] ?? '?') as String,
                          avatarUrl: activeMembers[i]['profile_picture'] as String?,
                          level: activeMembers[i]['level'] as int? ?? 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${activeMembers.length} anggota aktif sekarang',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;
  const _StatCell({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = Column(
      children: [
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.primaryOrange,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 11,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
    return Expanded(
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black38,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

class _ManageOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManageOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── Tab: Diskusi (post feed) ────────────────────────────────

class _DiskusiTab extends StatefulWidget {
  final CommunityModel community;
  const _DiskusiTab({required this.community});

  @override
  State<_DiskusiTab> createState() => _DiskusiTabState();
}

class _DiskusiTabState extends State<_DiskusiTab> {
  Future<void> _openComposer() async {
    if (!widget.community.isMember) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bergabung dulu untuk membuat post'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostComposerSheet(communityId: widget.community.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final postProvider = context.watch<CommunityPostProvider>();
    final id = widget.community.id;
    final posts = postProvider.postsFor(id);
    final loading = postProvider.isLoading(id);

    return RefreshIndicator(
      color: colors.primaryOrange,
      onRefresh: () => postProvider.loadPosts(id, refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Composer
          GestureDetector(
            onTap: _openComposer,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: colors.primaryOrange.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.primaryOrange.withOpacity(0.4),
                  width: 1.4,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: colors.primaryOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tulis sesuatu di komunitas...',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.primaryOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (loading && posts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (posts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Belum ada post. Jadilah yang pertama!',
                  style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
                ),
              ),
            )
          else
            ...posts.expand((p) => [
                  CommunityPostCard(
                    post: p,
                    onLike: () => postProvider.toggleLike(id, p.id),
                    onComment: () {},
                    onShare: () {},
                  ),
                  const SizedBox(height: 12),
                ]),
        ],
      ),
    );
  }
}

class _PostComposerSheet extends StatefulWidget {
  final int communityId;
  const _PostComposerSheet({required this.communityId});

  @override
  State<_PostComposerSheet> createState() => _PostComposerSheetState();
}

class _PostComposerSheetState extends State<_PostComposerSheet> {
  final _ctrl = TextEditingController();
  File? _image;
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final granted = await PermissionHelper.checkPhotosPermission(context);
    if (!granted) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty && _image == null) return;
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthProvider>();
      final token = auth.token;
      if (token == null) return;
      String? imageUrl;
      if (_image != null) {
        imageUrl = await DmApiService().uploadImage(_image!, token);
      }
      final ok = await context.read<CommunityPostProvider>().createPost(
            communityId: widget.communityId,
            content: _ctrl.text.trim().isEmpty ? '(gambar)' : _ctrl.text.trim(),
            imageUrl: imageUrl,
          );
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat post')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tulis post baru',
              style: GoogleFonts.beVietnamPro(
                fontSize: 16, fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Bagikan info, pertanyaan, atau cerita...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_image != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 160, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(Icons.image_rounded, color: colors.primaryOrange),
                ),
                const Spacer(),
                Material(
                  color: _busy ? colors.primaryOrange.withOpacity(0.5) : colors.primaryOrange,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _busy ? null : _submit,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: _busy
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Posting',
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
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

// ─── Tab: Kegiatan ───────────────────────────────────────────

class _KegiatanTab extends StatelessWidget {
  final List<CommunityEventModel> events;
  const _KegiatanTab({required this.events});

  String _monthShort(int m) {
    const list = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    if (m < 1 || m > 12) return '';
    return list[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Belum ada kegiatan terjadwal.',
            style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final e = events[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: colors.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      e.eventDate?.day.toString().padLeft(2, '0') ?? '--',
                      style: GoogleFonts.beVietnamPro(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: colors.primaryOrange,
                      ),
                    ),
                    Text(
                      _monthShort(e.eventDate?.month ?? 0),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (e.location != null)
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 12, color: colors.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              e.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (e.maxParticipants != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${e.currentParticipants}/${e.maxParticipants} peserta',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                        ),
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
}

// ─── Tab: Foto ───────────────────────────────────────────────

class _FotoTab extends StatelessWidget {
  final List<Map<String, dynamic>> photos;
  const _FotoTab({required this.photos});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Belum ada foto dibagikan.',
            style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, i) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AppImage(
            url: photos[i]['image_url'] as String?,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: colors.background,
              child: Icon(Icons.broken_image_rounded, color: colors.textMuted),
            ),
          ),
        );
      },
    );
  }
}

// ─── Tab: Anggota ────────────────────────────────────────────

class _AnggotaTab extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  const _AnggotaTab({required this.members});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: members.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (_, i) {
        final m = members[i];
        final isOnline = m['is_online'] == true;
        final role = (m['role'] as String?) ?? 'member';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Stack(
            children: [
              LevelAvatar(
                radius: 22,
                name: (m['name'] ?? '?') as String,
                avatarUrl: m['profile_picture'] as String?,
                level: m['level'] as int? ?? 1,
              ),
              if (isOnline)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.background, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            (m['name'] ?? '') as String,
            style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            isOnline ? 'Online sekarang' : 'Anggota',
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: isOnline ? Colors.green.shade700 : colors.textSecondary,
            ),
          ),
          trailing: role == 'admin' || role == 'moderator'
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    role == 'admin' ? 'Admin' : 'Moderator',
                    style: GoogleFonts.beVietnamPro(
                      color: colors.primaryOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

// ─── Tab: Aturan ─────────────────────────────────────────────

class _AturanTab extends StatelessWidget {
  final List<CommunityRuleModel> rules;
  final bool canEdit;
  final VoidCallback onEdit;

  const _AturanTab({
    required this.rules,
    required this.canEdit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canEdit)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: const Text('Edit Aturan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ),
        if (rules.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Belum ada aturan ditetapkan.',
                style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
              ),
            ),
          )
        else
          ...rules.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: colors.primaryOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${r.ordinal}',
                        style: GoogleFonts.beVietnamPro(
                          color: colors.primaryOrange,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.text,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          height: 1.4,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }
}

// ─── Sticky tab bar delegate ─────────────────────────────────

class _StickyTabBar extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color background;
  _StickyTabBar(this.tabBar, this.background);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: background, child: tabBar);
  }

  @override
  bool shouldRebuild(_StickyTabBar oldDelegate) =>
      oldDelegate.tabBar != tabBar || oldDelegate.background != background;
}
