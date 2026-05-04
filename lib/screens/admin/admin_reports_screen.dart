import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchReports(status: _status);
    });
  }

  Future<void> _action(int reportId, String action) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<AdminProvider>().actionReport(reportId, action);
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Diproses' : 'Gagal')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<AdminProvider>();
    final reports = provider.reports;
    final dateFmt = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Moderasi Laporan', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pending', label: Text('Pending')),
                ButtonSegment(value: 'resolved', label: Text('Resolved')),
                ButtonSegment(value: 'dismissed', label: Text('Dismissed')),
              ],
              selected: {_status},
              onSelectionChanged: (s) {
                setState(() => _status = s.first);
                provider.fetchReports(status: _status);
              },
            ),
          ),
          Expanded(
            child: provider.loading && reports.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : reports.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada laporan',
                          style: GoogleFonts.beVietnamPro(color: colors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final r = reports[i];
                          final created = (r['created_at'] as String?) != null
                              ? DateTime.tryParse(r['created_at'] as String)
                              : null;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.flag_rounded, color: Colors.red, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        r['reason']?.toString() ?? '-',
                                        style: GoogleFonts.beVietnamPro(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (created != null)
                                      Text(
                                        dateFmt.format(created),
                                        style: GoogleFonts.beVietnamPro(
                                          color: colors.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Pelapor: ${r['reporter_name'] ?? '-'}',
                                  style: GoogleFonts.beVietnamPro(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                if ((r['post_content'] as String?)?.isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colors.input,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r['post_content']!.toString(),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.beVietnamPro(
                                        color: colors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                if (_status == 'pending') ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _action(r['id'] as int, 'dismiss'),
                                          child: const Text('Tolak'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _action(r['id'] as int, 'takedown'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('Hapus Konten'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
