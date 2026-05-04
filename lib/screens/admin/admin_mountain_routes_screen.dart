import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';

class AdminMountainRoutesScreen extends StatefulWidget {
  final int mountainId;
  final String mountainName;
  const AdminMountainRoutesScreen({
    super.key,
    required this.mountainId,
    required this.mountainName,
  });

  @override
  State<AdminMountainRoutesScreen> createState() => _AdminMountainRoutesScreenState();
}

class _AdminMountainRoutesScreenState extends State<AdminMountainRoutesScreen> {
  List<Map<String, dynamic>> _routes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final routes = await context.read<AdminProvider>().fetchMountainRoutes(widget.mountainId);
    if (!mounted) return;
    setState(() {
      _routes = routes;
      _loading = false;
    });
  }

  Future<void> _addRoute() async {
    final name = TextEditingController();
    final desc = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Jalur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nama jalur'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: desc,
              decoration: const InputDecoration(labelText: 'Deskripsi (opsional)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );

    if (ok != true || name.text.trim().isEmpty) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final success = await context.read<AdminProvider>().createMountainRoute(
          widget.mountainId,
          {'name': name.text.trim(), 'description': desc.text.trim()},
        );
    messenger.showSnackBar(SnackBar(content: Text(success ? 'Jalur ditambah' : 'Gagal')));
    if (success) _refresh();
  }

  Future<void> _delete(int routeId, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Jalur?'),
        content: Text('Hapus jalur "$name"?'),
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
    final success = await context.read<AdminProvider>().deleteMountainRoute(widget.mountainId, routeId);
    messenger.showSnackBar(SnackBar(content: Text(success ? 'Jalur dihapus' : 'Gagal')));
    if (success) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          'Jalur ${widget.mountainName}',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRoute,
        backgroundColor: colors.primaryOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada jalur.',
                    style: GoogleFonts.beVietnamPro(color: colors.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _routes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = _routes[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.alt_route_rounded, color: colors.primaryOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['name']?.toString() ?? '-',
                                  style: GoogleFonts.beVietnamPro(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if ((r['description'] as String?)?.isNotEmpty == true)
                                  Text(
                                    r['description']!.toString(),
                                    style: GoogleFonts.beVietnamPro(
                                      color: colors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _delete(r['id'] as int, r['name'] as String),
                            icon: const Icon(Icons.delete_rounded, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
