import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  String _role = 'all';
  String _q = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers(role: _role, q: _q);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<AdminProvider>().fetchUsers(role: _role, q: _q);
  }

  Future<void> _showActions(Map<String, dynamic> user) async {
    final colors = context.colors;
    final isActive = user['is_active'] as bool? ?? true;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isActive ? Icons.block_rounded : Icons.check_circle_rounded),
              title: Text(isActive ? 'Nonaktifkan akun' : 'Aktifkan akun'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                final ok = await context.read<AdminProvider>().updateUser(
                      user['id'] as int,
                      isActive: !isActive,
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Diperbarui' : 'Gagal')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.upgrade_rounded),
              title: const Text('Promote ke Mitra'),
              enabled: user['role'] != 'mitra',
              onTap: () async {
                Navigator.pop(sheetCtx);
                final ok = await context.read<AdminProvider>().updateUser(
                      user['id'] as int,
                      role: 'mitra',
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Role diubah ke mitra' : 'Gagal')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('Demote ke User'),
              enabled: user['role'] != 'user',
              onTap: () async {
                Navigator.pop(sheetCtx);
                final ok = await context.read<AdminProvider>().updateUser(
                      user['id'] as int,
                      role: 'user',
                    );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Role diubah ke user' : 'Gagal')),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<AdminProvider>();
    final users = provider.users;
    final dashboard = provider.dashboard;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Manajemen Pengguna', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stats summary header (dari dashboard payload yang sudah di-cache).
          if (dashboard != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _UserStatsHeader(data: (dashboard['users'] as Map?) ?? const {}),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau email...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (v) {
                    setState(() => _q = v.trim());
                    _refresh();
                  },
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Semua')),
                    ButtonSegment(value: 'user', label: Text('User')),
                    ButtonSegment(value: 'mitra', label: Text('Mitra')),
                    ButtonSegment(value: 'admin', label: Text('Admin')),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) {
                    setState(() => _role = s.first);
                    _refresh();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: provider.loading && users.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                'Tidak ada pengguna',
                                style: GoogleFonts.beVietnamPro(color: colors.textMuted),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final u = users[i];
                            return _UserTile(
                              data: u,
                              onTap: () => _showActions(u),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header strip 4-kolom dengan ringkasan: total / aktif / mitra / nonaktif.
class _UserStatsHeader extends StatelessWidget {
  final Map data;
  const _UserStatsHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = data['total'] ?? 0;
    final inactive = data['inactive'] ?? 0;
    final mitra = data['mitra_count'] ?? 0;
    final active = (total is int && inactive is int) ? (total - inactive) : 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _statCol(context, label: 'Total', value: '$total', color: Colors.blue)),
          _divider(colors),
          Expanded(child: _statCol(context, label: 'Aktif', value: '$active', color: Colors.green)),
          _divider(colors),
          Expanded(child: _statCol(context, label: 'Mitra', value: '$mitra', color: Colors.purple)),
          _divider(colors),
          Expanded(child: _statCol(context, label: 'Nonaktif', value: '$inactive', color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _divider(AppColors colors) =>
      Container(width: 1, height: 32, color: colors.border);

  Widget _statCol(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _UserTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isActive = data['is_active'] as bool? ?? true;
    final role = data['role']?.toString() ?? 'user';

    Color roleColor;
    switch (role) {
      case 'admin':
        roleColor = Colors.red;
        break;
      case 'mitra':
        roleColor = Colors.purple;
        break;
      default:
        roleColor = Colors.blue;
    }

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Icon(Icons.person_rounded, color: roleColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? '-',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      data['email'] ?? '-',
                      style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: GoogleFonts.beVietnamPro(
                        color: roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                    size: 14,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
