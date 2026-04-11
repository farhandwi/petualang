import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_theme.dart';

class ReportBottomSheet extends StatefulWidget {
  final String targetType; // 'post' | 'comment' | 'message'
  final int targetId;

  const ReportBottomSheet({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  static Future<void> show(
    BuildContext context, {
    required String targetType,
    required int targetId,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportBottomSheet(targetType: targetType, targetId: targetId),
    );
  }

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  String? _selectedReason;
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Spam atau iklan berulang',
    'Konten tidak pantas / NSFW',
    'Ujaran kebencian atau diskriminasi',
    'Pelecehan atau perundungan',
    'Informasi palsu / hoaks',
    'Lainnya',
  ];

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _isSubmitting = true);

    final provider = context.read<CommunityProvider>();
    final success = await provider.submitReport(
      targetType: widget.targetType,
      targetId: widget.targetId,
      reason: _selectedReason!,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Laporan berhasil dikirim. Terima kasih!'
                : 'Gagal mengirim laporan. Coba lagi.',
          ),
          backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Laporkan Konten',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih alasan laporan Anda',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          ..._reasons.map((reason) => RadioListTile<String>(
                dense: true,
                title: Text(reason, style: TextStyle(fontSize: 14, color: colors.textPrimary)),
                value: reason,
                groupValue: _selectedReason,
                activeColor: colors.primaryOrange,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) => setState(() => _selectedReason = val),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedReason != null && !_isSubmitting ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Kirim Laporan', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
