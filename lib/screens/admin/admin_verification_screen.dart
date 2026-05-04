import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchVerifications(status: _status);
    });
  }

  Future<void> _refresh() async {
    await context.read<AdminProvider>().fetchVerifications(status: _status);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<AdminProvider>();
    final list = provider.verifications;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Verifikasi Identitas', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'pending', label: Text('Menunggu')),
                ButtonSegment(value: 'verified', label: Text('Disetujui')),
                ButtonSegment(value: 'rejected', label: Text('Ditolak')),
              ],
              selected: {_status},
              onSelectionChanged: (s) {
                setState(() => _status = s.first);
                _refresh();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: provider.loading && list.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : list.isEmpty
                      ? _empty(colors)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _VerificationCard(
                            data: list[i],
                            isPending: _status == 'pending',
                          ),
                        ),
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
        Icon(Icons.verified_user_rounded, size: 64, color: colors.textMuted),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Tidak ada data verifikasi',
            style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isPending;
  const _VerificationCard({required this.data, required this.isPending});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ktpUrl = data['ktp_photo_url'] as String?;
    final selfieUrl = data['selfie_ktp_url'] as String?;

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
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primaryOrange.withValues(alpha: 0.15),
                child: Icon(Icons.person_rounded, color: colors.primaryOrange),
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
              _StatusChip(status: data['verification_status'] ?? 'pending'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'NIK', value: data['nik']?.toString() ?? '-'),
          _InfoRow(label: 'Tempat Lahir', value: data['birth_place'] ?? '-'),
          _InfoRow(label: 'Alamat KTP', value: data['ktp_address'] ?? '-'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ImagePreview(
                  url: ktpUrl,
                  label: 'Foto KTP',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ImagePreview(
                  url: selfieUrl,
                  label: 'Selfie + KTP',
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _action(context, 'reject'),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _action(context, 'approve'),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _action(BuildContext context, String action) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<AdminProvider>().actionVerification(
          data['id'] as int,
          action,
        );
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? (action == 'approve' ? 'Disetujui' : 'Ditolak')
            : 'Gagal memperbarui status'),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'verified':
        color = Colors.green;
        label = 'Terverifikasi';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Ditolak';
        break;
      default:
        color = Colors.orange;
        label = 'Menunggu';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.beVietnamPro(color: colors.textPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String? url;
  final String label;
  const _ImagePreview({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolved = AppConfig.resolveImageUrl(url);

    return GestureDetector(
      onTap: resolved.isEmpty ? null : () => _showFullScreen(context, resolved),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: colors.input,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: resolved.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_rounded, color: colors.textMuted),
                    const SizedBox(height: 4),
                    Text(label, style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 11)),
                  ],
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    resolved,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.broken_image_rounded, color: colors.textMuted),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      color: Colors.black54,
                      child: Text(
                        label,
                        style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showFullScreen(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
