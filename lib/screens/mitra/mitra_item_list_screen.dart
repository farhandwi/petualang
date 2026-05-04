import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/mitra_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adaptive_image.dart';
import 'mitra_item_form_screen.dart';

class MitraItemListScreen extends StatefulWidget {
  const MitraItemListScreen({super.key});

  @override
  State<MitraItemListScreen> createState() => _MitraItemListScreenState();
}

class _MitraItemListScreenState extends State<MitraItemListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _category = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MitraProvider>().fetchItems();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Apply search query + category filter di sisi client.
  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> items) {
    Iterable<Map<String, dynamic>> filtered = items;
    if (_category != 'Semua') {
      filtered = filtered.where(
        (it) => (it['category']?.toString().toLowerCase() ?? '') ==
            _category.toLowerCase(),
      );
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered.where((it) {
        final name = it['name']?.toString().toLowerCase() ?? '';
        final brand = it['brand']?.toString().toLowerCase() ?? '';
        return name.contains(q) || brand.contains(q);
      });
    }
    return filtered.toList();
  }

  /// Set semua kategori unik dari items + 'Semua' di awal.
  List<String> _categories(List<Map<String, dynamic>> items) {
    final set = <String>{};
    for (final it in items) {
      final c = it['category']?.toString();
      if (c != null && c.isNotEmpty) set.add(c);
    }
    return ['Semua', ...set.toList()..sort()];
  }

  Future<void> _confirmDelete(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Alat?'),
        content: Text('Hapus "$name" dari toko?'),
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
    final success = await context.read<MitraProvider>().deleteItem(id);
    messenger.showSnackBar(
      SnackBar(content: Text(success ? 'Alat dihapus' : 'Gagal')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<MitraProvider>();
    final items = provider.items;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Alat Saya', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MitraItemFormScreen()),
          );
          if (mounted) context.read<MitraProvider>().fetchItems();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
        backgroundColor: colors.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Cari alat atau merek...',
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
          // Category chips
          if (items.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final cat in _categories(items))
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: _category == cat,
                        onSelected: (_) => setState(() => _category = cat),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchItems(),
              child: provider.loading && items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Icon(Icons.inventory_2_rounded, size: 64, color: colors.textMuted),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Belum ada alat. Tambahkan alat sewa pertama Anda.',
                                style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
                              ),
                            ),
                          ],
                        )
                      : Builder(builder: (_) {
                          final filtered = _filter(items);
                          if (filtered.isEmpty) {
                            return ListView(
                              children: [
                                const SizedBox(height: 80),
                                Icon(Icons.search_off_rounded, size: 56, color: colors.textMuted),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    'Tidak ada alat yang cocok',
                                    style: GoogleFonts.beVietnamPro(color: colors.textMuted),
                                  ),
                                ),
                              ],
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final it = filtered[i];
                              return _ItemCard(
                                data: it,
                                currency: currency,
                                onEdit: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MitraItemFormScreen(initial: it),
                                    ),
                                  );
                                  if (mounted) context.read<MitraProvider>().fetchItems();
                                },
                                onDelete: () => _confirmDelete(it['id'] as int, it['name'] as String),
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
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.data,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final imgUrl = data['image_url'] as String?;
    final price = (data['price_per_day'] as num?)?.toDouble() ?? 0;
    final available = (data['available_stock'] as int?) ?? 0;
    final stock = (data['stock'] as int?) ?? 0;
    // Threshold low stock: <= 3 unit dianggap perlu perhatian. 0 = habis.
    final isOut = available == 0;
    final isLow = available > 0 && available <= 3;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOut
              ? Colors.red.withValues(alpha: 0.4)
              : isLow
                  ? Colors.orange.withValues(alpha: 0.4)
                  : colors.border,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
              child: AdaptiveImage(
                url: imgUrl,
                fit: BoxFit.cover,
                fallbackBuilder: (_) => _ph(colors),
              ),
            ),
          ),
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isOut)
                      _StockBadge(label: 'HABIS', color: Colors.red)
                    else if (isLow)
                      _StockBadge(label: 'STOK MENIPIS', color: Colors.orange),
                  ],
                ),
                Text(
                  '${data['category']} • ${data['brand']}',
                  style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${currency.format(price)}/hari',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stok: $available/$stock',
                      style: GoogleFonts.beVietnamPro(
                        color: isOut
                            ? Colors.red
                            : isLow
                                ? Colors.orange
                                : colors.textSecondary,
                        fontSize: 11,
                        fontWeight: (isOut || isLow) ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 18)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _ph(AppColors colors) => Container(
        color: colors.input,
        child: Icon(Icons.image_rounded, color: colors.textMuted),
      );
}

/// Badge kecil untuk indikator stok (HABIS / STOK MENIPIS).
class _StockBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StockBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
