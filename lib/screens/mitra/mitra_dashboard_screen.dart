import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mitra_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class MitraDashboardScreen extends StatefulWidget {
  const MitraDashboardScreen({super.key});

  @override
  State<MitraDashboardScreen> createState() => _MitraDashboardScreenState();
}

class _MitraDashboardScreenState extends State<MitraDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mitra = context.read<MitraProvider>();
      mitra.fetchStats();
      mitra.refreshPendingOrderCount();
    });
  }

  Future<void> _refreshAll() async {
    final mitra = context.read<MitraProvider>();
    await Future.wait([
      mitra.fetchStats(),
      mitra.refreshPendingOrderCount(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<MitraProvider>();
    final user = context.watch<AuthProvider>().user;
    final stats = provider.stats;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Dashboard Mitra', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: provider.loading && stats == null
            ? const Center(child: CircularProgressIndicator())
            : stats == null
                ? _empty(colors)
                : ListView(
                    padding: context.pagePadding,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primaryOrange,
                              colors.primaryOrange.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${user?.name ?? 'Mitra'}!',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.beVietnamPro(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status toko: ${(stats['is_open'] as bool? ?? false) ? '🟢 Buka' : '🔴 Tutup'}',
                                    style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                            ),
                          ],
                        ),
                      ),
                      if (provider.pendingOrderCount > 0) ...[
                        const SizedBox(height: 12),
                        _PendingAlert(count: provider.pendingOrderCount),
                      ],
                      const SizedBox(height: 16),
                      ResponsiveGrid(
                        mobileColumns: 2,
                        tabletColumns: 4,
                        desktopColumns: 4,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatCard(
                            icon: Icons.shopping_bag_rounded,
                            color: Colors.deepPurple,
                            title: 'Order Bulan Ini',
                            value: '${(stats['orders'] as Map?)?['this_month'] ?? 0}',
                            subtitle: 'Total: ${(stats['orders'] as Map?)?['total'] ?? 0}',
                          ),
                          _StatCard(
                            icon: Icons.payments_rounded,
                            color: Colors.green,
                            title: 'Omzet Bulan Ini',
                            value: currency.format(((stats['revenue'] as Map?)?['this_month'] ?? 0)),
                            subtitle: 'Total: ${currency.format(((stats['revenue'] as Map?)?['total'] ?? 0))}',
                          ),
                          _StatCard(
                            icon: Icons.inventory_2_rounded,
                            color: Colors.blue,
                            title: 'Total Alat',
                            value: '${stats['total_items'] ?? 0}',
                            subtitle: 'Terdaftar di toko',
                          ),
                          _StatCard(
                            icon: Icons.star_rounded,
                            color: Colors.amber,
                            title: 'Rating Toko',
                            value: '${stats['rating'] ?? 0}',
                            subtitle: '${stats['review_count'] ?? 0} ulasan',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Alat Paling Laris',
                        style: GoogleFonts.beVietnamPro(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._buildTopItems(stats, colors, currency),
                    ],
                  ),
      ),
    );
  }

  List<Widget> _buildTopItems(
    Map<String, dynamic> stats,
    AppColors colors,
    NumberFormat currency,
  ) {
    final items = (stats['top_items'] as List?) ?? [];
    if (items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Belum ada penjualan.',
            style: GoogleFonts.beVietnamPro(color: colors.textMuted),
          ),
        ),
      ];
    }
    return items.map<Widget>((it) {
      final m = it as Map<String, dynamic>;
      final imgUrl = AppConfig.resolveImageUrl(m['image_url'] as String?);
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: imgUrl.isNotEmpty
                    ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph(colors))
                    : _ph(colors),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['name']?.toString() ?? '-',
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${m['total_qty'] ?? 0} unit terjual',
                    style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              currency.format(m['revenue'] ?? 0),
              style: GoogleFonts.beVietnamPro(
                color: Colors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _ph(AppColors colors) => Container(
        color: colors.input,
        child: Icon(Icons.image_rounded, color: colors.textMuted),
      );

  Widget _empty(AppColors colors) {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.storefront_rounded, size: 64, color: colors.textMuted),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Tidak dapat memuat data toko',
            style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

/// Alert banner kuning yang muncul saat ada order pending — mengarahkan
/// mitra ke tab Pesanan untuk memproses.
class _PendingAlert extends StatelessWidget {
  final int count;
  const _PendingAlert({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count pesanan menunggu konfirmasi',
                  style: GoogleFonts.beVietnamPro(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Buka tab Pesanan untuk memprosesnya.',
                  style: GoogleFonts.beVietnamPro(
                    color: colors.textSecondary,
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
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String subtitle;
  const _StatCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.beVietnamPro(color: colors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
