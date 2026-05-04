import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_mountain_form_screen.dart';
import 'admin_mountain_routes_screen.dart';

class AdminMountainListScreen extends StatefulWidget {
  const AdminMountainListScreen({super.key});

  @override
  State<AdminMountainListScreen> createState() => _AdminMountainListScreenState();
}

class _AdminMountainListScreenState extends State<AdminMountainListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchMountains();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((m) {
      final name = m['name']?.toString().toLowerCase() ?? '';
      final loc = m['location']?.toString().toLowerCase() ?? '';
      return name.contains(q) || loc.contains(q);
    }).toList();
  }

  Future<void> _confirmDelete(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Gunung?'),
        content: Text('Anda akan menghapus "$name" beserta semua jalur. Lanjut?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<AdminProvider>().deleteMountain(id);
    messenger.showSnackBar(SnackBar(
      content: Text(success ? 'Gunung dihapus' : 'Gagal menghapus'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<AdminProvider>();
    final list = provider.mountains;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Manajemen Gunung', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminMountainFormScreen()),
          );
          if (mounted) context.read<AdminProvider>().fetchMountains();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: colors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Cari nama gunung atau lokasi...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            ),
          ),
          if (list.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.terrain_rounded, size: 14, color: colors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${_filter(list).length} gunung${_query.isNotEmpty ? ' (dari ${list.length})' : ''}',
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchMountains(),
              child: provider.loading && list.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? _empty(colors)
                      : Builder(builder: (_) {
                          final filtered = _filter(list);
                          if (filtered.isEmpty) {
                            return ListView(
                              children: [
                                const SizedBox(height: 80),
                                Icon(Icons.search_off_rounded, size: 56, color: colors.textMuted),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    'Tidak ada gunung yang cocok',
                                    style: GoogleFonts.beVietnamPro(color: colors.textMuted),
                                  ),
                                ),
                              ],
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final m = filtered[i];
                              return _MountainCard(
                                data: m,
                                currency: currency,
                                onEdit: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminMountainFormScreen(initial: m),
                                    ),
                                  );
                                  if (mounted) context.read<AdminProvider>().fetchMountains();
                                },
                                onRoutes: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminMountainRoutesScreen(
                                      mountainId: m['id'] as int,
                                      mountainName: m['name'] as String,
                                    ),
                                  ),
                                ),
                                onDelete: () => _confirmDelete(m['id'] as int, m['name'] as String),
                              );
                            },
                          );
                        }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(AppColors colors) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.terrain_rounded, size: 64, color: colors.textMuted),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Belum ada gunung. Tambahkan pertama Anda.',
            style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _MountainCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onRoutes;
  final VoidCallback onDelete;

  const _MountainCard({
    required this.data,
    required this.currency,
    required this.onEdit,
    required this.onRoutes,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final price = (data['price'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Thumb(imageUrl: data['image_url'] as String?),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['name'] ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (data['is_featured'] == true)
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 12, color: colors.textMuted),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            '${data['location'] ?? '-'} • ${data['elevation']} mdpl',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip(label: data['difficulty']?.toString() ?? '-', color: Colors.orange),
              _Chip(label: currency.format(price), color: Colors.green),
              _Chip(label: '⭐ ${data['rating'] ?? 0}', color: Colors.blue),
              if (data['use_external_booking'] == true)
                _Chip(label: '🌐 Eksternal', color: Colors.purple),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRoutes,
                  icon: const Icon(Icons.alt_route_rounded, size: 16),
                  label: const Text('Jalur'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thumbnail 48×48 untuk gunung. Fallback ke icon jika URL kosong / asset
/// tidak ditemukan.
class _Thumb extends StatelessWidget {
  final String? imageUrl;
  const _Thumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = imageUrl ?? '';
    final fallback = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.primaryOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.terrain_rounded, color: colors.primaryOrange),
    );

    if (url.isEmpty) return fallback;
    final isAsset = !url.startsWith('http') && url.startsWith('assets/');
    final isHttp = url.startsWith('http');
    if (!isAsset && !isHttp) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 48,
        height: 48,
        child: isAsset
            ? Image.asset(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback)
            : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
