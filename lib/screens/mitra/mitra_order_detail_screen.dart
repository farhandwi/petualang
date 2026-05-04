import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/mitra_provider.dart';
import '../../theme/app_theme.dart';

/// Layar detail order untuk mitra: tampil info pelanggan, alat yang disewa,
/// timeline status, plus aksi update status.
class MitraOrderDetailScreen extends StatefulWidget {
  final int orderId;
  const MitraOrderDetailScreen({super.key, required this.orderId});

  @override
  State<MitraOrderDetailScreen> createState() => _MitraOrderDetailScreenState();
}

class _MitraOrderDetailScreenState extends State<MitraOrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final data = await context.read<MitraProvider>().fetchOrderDetail(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = data;
      _loading = false;
    });
  }

  Future<void> _updateStatus(String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<MitraProvider>().updateOrderStatus(widget.orderId, status);
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Status diperbarui' : 'Gagal')));
    if (ok) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final order = _order;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Detail Pesanan', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? Center(
                  child: Text(
                    'Order tidak ditemukan',
                    style: GoogleFonts.beVietnamPro(color: colors.textMuted),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _HeaderCard(order: order),
                      const SizedBox(height: 12),
                      _CustomerCard(order: order),
                      const SizedBox(height: 12),
                      _ItemsCard(order: order),
                      const SizedBox(height: 12),
                      _StatusTimeline(currentStatus: order['status']?.toString() ?? 'pending'),
                      const SizedBox(height: 16),
                      _ActionButtons(
                        currentStatus: order['status']?.toString() ?? 'pending',
                        onUpdate: _updateStatus,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _HeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');
    final start = order['start_date'] != null ? DateTime.tryParse(order['start_date'] as String) : null;
    final end = order['end_date'] != null ? DateTime.tryParse(order['end_date'] as String) : null;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryOrange, colors.primaryOrange.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kode Order',
            style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 12),
          ),
          Text(
            order['rental_code']?.toString() ?? '-',
            style: GoogleFonts.beVietnamPro(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (start != null && end != null)
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${dateFmt.format(start)} – ${dateFmt.format(end)}',
                  style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          if (order['mountain_name'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.terrain_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(
                  order['mountain_name'].toString(),
                  style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.beVietnamPro(color: Colors.white70, fontSize: 12),
              ),
              Text(
                currency.format((order['total_price'] as num?) ?? 0),
                style: GoogleFonts.beVietnamPro(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _CustomerCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.primaryOrange.withValues(alpha: 0.15),
            child: Icon(Icons.person_rounded, color: colors.primaryOrange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pelanggan',
                  style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 11),
                ),
                Text(
                  order['customer_name']?.toString() ?? '-',
                  style: GoogleFonts.beVietnamPro(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((order['customer_phone'] as String?)?.isNotEmpty == true)
                  Text(
                    order['customer_phone'].toString(),
                    style: GoogleFonts.beVietnamPro(color: colors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = (order['items'] as List?) ?? const [];
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alat Disewa (${items.length})',
            style: GoogleFonts.beVietnamPro(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final raw in items) ...[
            _itemRow(context, raw as Map<String, dynamic>, currency),
            if (raw != items.last) Divider(color: colors.border, height: 18),
          ],
          if (items.isEmpty)
            Text(
              'Tidak ada item',
              style: GoogleFonts.beVietnamPro(color: colors.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _itemRow(BuildContext context, Map<String, dynamic> it, NumberFormat currency) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.primaryOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.inventory_2_rounded, color: colors.primaryOrange, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                it['name']?.toString() ?? '-',
                style: GoogleFonts.beVietnamPro(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${it['quantity']} × ${currency.format((it['price_per_day'] as num?) ?? 0)}/hari',
                style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          currency.format((it['subtotal'] as num?) ?? 0),
          style: GoogleFonts.beVietnamPro(
            color: Colors.green,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;
  const _StatusTimeline({required this.currentStatus});

  static const _flow = [
    ('pending', 'Pending', Icons.hourglass_top_rounded),
    ('confirmed', 'Confirmed', Icons.check_circle_rounded),
    ('active', 'Active', Icons.local_shipping_rounded),
    ('completed', 'Completed', Icons.task_alt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentIdx = _flow.indexWhere((f) => f.$1 == currentStatus);
    final isCancelled = currentStatus == 'cancelled' || currentStatus == 'failed';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline Status',
            style: GoogleFonts.beVietnamPro(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (isCancelled)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Order dibatalkan',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < _flow.length; i++) ...[
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: i <= currentIdx
                          ? colors.primaryOrange
                          : colors.border,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _flow[i].$3,
                      size: 16,
                      color: i <= currentIdx ? Colors.white : colors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _flow[i].$2,
                      style: GoogleFonts.beVietnamPro(
                        color: i <= currentIdx ? colors.textPrimary : colors.textMuted,
                        fontWeight: i == currentIdx ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (i == currentIdx)
                    Text(
                      'sekarang',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.primaryOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (i < _flow.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 13, top: 2, bottom: 2),
                  child: Container(
                    width: 2,
                    height: 16,
                    color: i < currentIdx ? colors.primaryOrange : colors.border,
                  ),
                ),
            ],
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onUpdate;
  const _ActionButtons({required this.currentStatus, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'completed' || currentStatus == 'cancelled' || currentStatus == 'failed') {
      return const SizedBox.shrink();
    }

    // Tampilkan aksi sesuai status saat ini.
    final next = switch (currentStatus) {
      'pending' => ('confirmed', 'Konfirmasi Pesanan', Icons.check_circle_rounded, Colors.blue),
      'confirmed' => ('active', 'Tandai Sedang Aktif', Icons.local_shipping_rounded, Colors.orange),
      'active' => ('completed', 'Tandai Selesai', Icons.task_alt_rounded, Colors.green),
      _ => null,
    };

    return Column(
      children: [
        if (next != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onUpdate(next.$1),
              icon: Icon(next.$3),
              label: Text(next.$2),
              style: ElevatedButton.styleFrom(
                backgroundColor: next.$4,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => onUpdate('cancelled'),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Batalkan Pesanan'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
