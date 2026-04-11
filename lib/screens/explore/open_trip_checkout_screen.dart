import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/explore_model.dart';
import '../../providers/open_trip_provider.dart';
import '../../providers/explore_provider.dart';
import '../../theme/app_theme.dart';

class OpenTripCheckoutScreen extends StatefulWidget {
  final OpenTripModel trip;

  const OpenTripCheckoutScreen({super.key, required this.trip});

  @override
  State<OpenTripCheckoutScreen> createState() => _OpenTripCheckoutScreenState();
}

class _OpenTripCheckoutScreenState extends State<OpenTripCheckoutScreen> {
  String _selectedPaymentMethod = 'transfer_bank';

  Future<void> _processCheckout() async {
    final provider = context.read<OpenTripProvider>();
    final success = await provider.joinTrip(widget.trip);

    if (!mounted) return;

    if (success) {
      // Refresh list Open trips di background
      context.read<ExploreProvider>().fetchExploreData();
      
      // Tampilkan sukses
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: context.colors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Booking Berhasil!',
                style: GoogleFonts.beVietnamPro(
                  color: context.colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Selamat! Anda telah bergabung dalam kloter ekspedisi ${widget.trip.title}. Silakan lakukan pembayaran pada halaman riwayat transaksi Anda.',
                style: GoogleFonts.beVietnamPro(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                  Navigator.pop(context); // Kembali ke list Open Trip / Detail
                  Navigator.pop(context); // Kembali ke Explore Tab
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text('Kembali ke Menu', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    } else {
      // Tampilkan error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Gagal melakukan booking. Silakan coba lagi.'),
          backgroundColor: context.colors.error,
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrange = context.colors.primaryOrange;
    final provider = context.watch<OpenTripProvider>();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          'Checkout Trip',
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: context.colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ringkasan Trip
            Text(
              'Ringkasan Pesanan',
              style: GoogleFonts.beVietnamPro(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isDark 
                  ? Border.all(color: Colors.white.withOpacity(0.05))
                  : Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.trip.imageUrl != null
                        ? Image.asset(widget.trip.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                        : Container(width: 60, height: 60, color: primaryOrange.withOpacity(0.2)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.trip.title,
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd MMM yyyy').format(widget.trip.startDate)}',
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metode Pembayaran
            Text(
              'Metode Pembayaran',
              style: GoogleFonts.beVietnamPro(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _PaymentMethodOption(
              value: 'transfer_bank',
              groupValue: _selectedPaymentMethod,
              title: 'Transfer Bank (Virtual Account)',
              icon: Icons.account_balance_rounded,
              onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
            ),
            _PaymentMethodOption(
              value: 'ewallet',
              groupValue: _selectedPaymentMethod,
              title: 'Dompet Digital (E-Wallet)',
              subtitle: 'Gopay, OVO, Dana, ShopeePay',
              icon: Icons.account_balance_wallet_rounded,
              onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
            ),
            _PaymentMethodOption(
              value: 'qris',
              groupValue: _selectedPaymentMethod,
              title: 'QRIS',
              icon: Icons.qr_code_2_rounded,
              onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
            ),

            const SizedBox(height: 32),

            // Rincian Pembayaran
            Text(
              'Rincian Tagihan',
              style: GoogleFonts.beVietnamPro(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Harga Tiket Trip', style: GoogleFonts.beVietnamPro(color: context.colors.textSecondary, fontSize: 14)),
                Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(widget.trip.price), 
                     style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Biaya Layanan Aplikasi', style: GoogleFonts.beVietnamPro(color: context.colors.textSecondary, fontSize: 14)),
                Text('Rp 2.500', style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Pembayaran', style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(widget.trip.price + 2500), 
                     style: GoogleFonts.beVietnamPro(color: primaryOrange, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : _processCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: provider.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Bayar Tagihan', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentMethodOption({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = value == groupValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? context.colors.primaryOrange : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: context.colors.primaryOrange,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Icon(icon, color: isSelected ? context.colors.primaryOrange : context.colors.textSecondary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
