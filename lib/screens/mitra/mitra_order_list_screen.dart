import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/mitra_provider.dart';
import '../../theme/app_theme.dart';
import 'mitra_order_detail_screen.dart';

class MitraOrderListScreen extends StatefulWidget {
  const MitraOrderListScreen({super.key});

  @override
  State<MitraOrderListScreen> createState() => _MitraOrderListScreenState();
}

class _MitraOrderListScreenState extends State<MitraOrderListScreen> {
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MitraProvider>().fetchOrders(status: _status);
    });
  }

  Future<void> _showActions(Map<String, dynamic> order) async {
    final colors = context.colors;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in const [
              ('confirmed', 'Konfirmasi', Icons.check_circle_rounded, Colors.blue),
              ('active', 'Tandai Aktif', Icons.local_shipping_rounded, Colors.orange),
              ('completed', 'Tandai Selesai', Icons.task_alt_rounded, Colors.green),
              ('cancelled', 'Batalkan', Icons.cancel_rounded, Colors.red),
            ])
              ListTile(
                leading: Icon(action.$3, color: action.$4),
                title: Text(action.$2),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await context.read<MitraProvider>().updateOrderStatus(
                        order['id'] as int,
                        action.$1,
                      );
                  messenger.showSnackBar(
                    SnackBar(content: Text(ok ? 'Status diperbarui' : 'Gagal')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<MitraProvider>();
    final orders = provider.orders;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Pesanan Masuk', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Semua')),
                    ButtonSegment(value: 'pending', label: Text('Pending')),
                    ButtonSegment(value: 'confirmed', label: Text('Confirmed')),
                    ButtonSegment(value: 'active', label: Text('Aktif')),
                    ButtonSegment(value: 'completed', label: Text('Selesai')),
                  ],
                  selected: {_status},
                  onSelectionChanged: (s) {
                    setState(() => _status = s.first);
                    provider.fetchOrders(status: _status);
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.fetchOrders(status: _status),
              child: provider.loading && orders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : orders.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Icon(Icons.receipt_long_rounded, size: 64, color: colors.textMuted),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Belum ada pesanan',
                                style: GoogleFonts.beVietnamPro(color: colors.textMuted),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final o = orders[i];
                            return _OrderTile(
                              data: o,
                              currency: currency,
                              dateFmt: dateFmt,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MitraOrderDetailScreen(orderId: o['id'] as int),
                                ),
                              ).then((_) => provider.fetchOrders(status: _status)),
                              onLongPress: () => _showActions(o),
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

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat currency;
  final DateFormat dateFmt;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _OrderTile({
    required this.data,
    required this.currency,
    required this.dateFmt,
    required this.onTap,
    this.onLongPress,
  });

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'active':
        return Colors.deepOrange;
      case 'completed':
      case 'success':
        return Colors.green;
      case 'cancelled':
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final start = (data['start_date'] as String?) != null ? DateTime.tryParse(data['start_date'] as String) : null;
    final end = (data['end_date'] as String?) != null ? DateTime.tryParse(data['end_date'] as String) : null;
    final status = data['status']?.toString() ?? 'pending';
    final totalPrice = (data['total_price'] as num?)?.toDouble() ?? 0;
    final color = _statusColor(status);

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['rental_code']?.toString() ?? '-',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.beVietnamPro(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.person_rounded, size: 14, color: colors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      data['customer_name']?.toString() ?? '-',
                      style: GoogleFonts.beVietnamPro(color: colors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (start != null && end != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: colors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${dateFmt.format(start)} - ${dateFmt.format(end)}',
                      style: GoogleFonts.beVietnamPro(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Text(
                currency.format(totalPrice),
                style: GoogleFonts.beVietnamPro(
                  color: Colors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
