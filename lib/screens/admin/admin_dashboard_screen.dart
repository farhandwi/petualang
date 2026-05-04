import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'admin_reports_screen.dart';
import 'admin_verification_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<AdminProvider>();
    final user = context.watch<AuthProvider>().user;
    final data = provider.dashboard;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchDashboard(),
        child: provider.loading && data == null
            ? const Center(child: CircularProgressIndicator())
            : data == null
                ? _emptyState(colors)
                : ListView(
                    padding: context.pagePadding,
                    children: [
                      _GreetingCard(name: user?.name ?? 'Admin', data: data),
                      const SizedBox(height: 16),
                      Text(
                        'Ringkasan Aplikasi',
                        style: GoogleFonts.beVietnamPro(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StatGrid(data: data, currency: currency),
                      const SizedBox(height: 20),
                      Text(
                        'Aksi Cepat',
                        style: GoogleFonts.beVietnamPro(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _QuickAction(
                        icon: Icons.verified_user_rounded,
                        iconColor: Colors.orange,
                        label: 'Verifikasi Identitas',
                        subtitle: '${(data['users'] as Map?)?['pending_verifications'] ?? 0} pengguna menunggu',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminVerificationScreen()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _QuickAction(
                        icon: Icons.flag_rounded,
                        iconColor: Colors.red,
                        label: 'Moderasi Laporan',
                        subtitle: '${data['pending_reports'] ?? 0} laporan menunggu',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminReportsScreen()),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _emptyState(AppColors colors) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Icon(Icons.dashboard_rounded, size: 64, color: colors.textMuted),
        const SizedBox(height: 12),
        Text(
          'Tidak dapat memuat statistik',
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat currency;
  const _StatGrid({required this.data, required this.currency});

  @override
  Widget build(BuildContext context) {
    final users = (data['users'] as Map?) ?? {};
    final tickets = (data['tickets'] as Map?) ?? {};
    final rentals = (data['rentals'] as Map?) ?? {};

    return ResponsiveGrid(
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 4,
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatCard(
          icon: Icons.people_rounded,
          color: Colors.blue,
          title: 'Total Pengguna',
          value: '${users['total'] ?? 0}',
          subtitle: '${users['mitra_count'] ?? 0} mitra • ${users['admin_count'] ?? 0} admin',
        ),
        _StatCard(
          icon: Icons.verified_user_rounded,
          color: Colors.orange,
          title: 'Verifikasi Pending',
          value: '${users['pending_verifications'] ?? 0}',
          subtitle: '${users['verified'] ?? 0} sudah terverifikasi',
        ),
        _StatCard(
          icon: Icons.terrain_rounded,
          color: Colors.teal,
          title: 'Total Gunung',
          value: '${data['mountains'] ?? 0}',
          subtitle: 'Tujuan pendakian',
        ),
        _StatCard(
          icon: Icons.confirmation_number_rounded,
          color: Colors.indigo,
          title: 'Tiket Bulan Ini',
          value: '${tickets['this_month'] ?? 0}',
          subtitle: 'Total: ${tickets['total'] ?? 0}',
        ),
        _StatCard(
          icon: Icons.shopping_bag_rounded,
          color: Colors.deepPurple,
          title: 'Sewa Bulan Ini',
          value: '${rentals['this_month'] ?? 0}',
          subtitle: 'Total: ${rentals['total'] ?? 0}',
        ),
        _StatCard(
          icon: Icons.payments_rounded,
          color: Colors.green,
          title: 'Pendapatan Total',
          value: currency.format(((tickets['revenue'] ?? 0) as num) + ((rentals['revenue'] ?? 0) as num)),
          subtitle: 'Tiket + Sewa',
        ),
      ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.beVietnamPro(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = iconColor ?? colors.primaryOrange;
    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner sambutan gradient yang menampilkan nama admin + ringkasan singkat.
class _GreetingCard extends StatelessWidget {
  final String name;
  final Map<String, dynamic> data;
  const _GreetingCard({required this.name, required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pending = (data['users'] as Map?)?['pending_verifications'] ?? 0;
    final reports = data['pending_reports'] ?? 0;
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat pagi'
        : hour < 15
            ? 'Selamat siang'
            : hour < 19
                ? 'Selamat sore'
                : 'Selamat malam';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryOrange, colors.primaryOrange.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pending > 0 || reports > 0
                      ? 'Ada $pending verifikasi & $reports laporan menunggu tindakan.'
                      : 'Tidak ada pekerjaan yang menunggu — kerja bagus!',
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}
