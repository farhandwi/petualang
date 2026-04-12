import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/rental_provider.dart';
import '../../theme/app_theme.dart';

class RentalCartScreen extends StatefulWidget {
  const RentalCartScreen({super.key});

  @override
  State<RentalCartScreen> createState() => _RentalCartScreenState();
}

class _RentalCartScreenState extends State<RentalCartScreen> {
  bool _isCheckingOut = false;

  Future<void> _checkout() async {
    setState(() => _isCheckingOut = true);
    final provider = context.read<RentalProvider>();
    final token = context.read<AuthProvider>().token;

    if (token == null) return;

    final result = await provider.checkout(
      token: token,
    );

    setState(() => _isCheckingOut = false);

    if (!mounted) return;

    if (result['success']) {
      provider.clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: context.colors.success,
        ),
      );
      
      final urlStr = result['payment_url'] as String?;
      if (urlStr != null && urlStr.isNotEmpty) {
        final uri = Uri.parse(urlStr);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      Navigator.pop(context); // back to list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final provider = context.read<RentalProvider>();
    final initialStart = provider.startDate ?? DateTime.now();
    final initialEnd = provider.endDate ?? DateTime.now().add(const Duration(days: 1));

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: context.colors.primaryOrange,
              primary: context.colors.primaryOrange,
              onPrimary: Colors.white,
              surface: context.colors.background,
              onSurface: context.colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setRentalDates(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalProvider>();
    final startDate = provider.startDate;
    final endDate = provider.endDate;
    final validDays = (startDate != null && endDate != null) 
      ? (endDate.difference(startDate).inDays >= 0 ? endDate.difference(startDate).inDays + 1 : 1)
      : 0;
    
    double totalPerDay = 0;
    for (var c in provider.cart) {
      totalPerDay += c.item.pricePerDay * c.quantity;
    }
    final daysMultiplier = validDays > 0 ? validDays : 1;
    final grandTotal = (totalPerDay * daysMultiplier) + provider.deliveryFee;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Keranjang Sewa'),
      ),
      body: provider.cart.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: context.colors.textMuted),
                const SizedBox(height: 16),
                Text(
                  'Keranjang kosong',
                  style: GoogleFonts.beVietnamPro(
                    color: context.colors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        : Column(
            children: [
              // Date Info (Clickable)
              InkWell(
                onTap: () => _selectDateRange(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: context.colors.surface,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: context.colors.primaryOrange),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              validDays > 0 ? 'Tanggal Sewa ($validDays Hari)' : 'Pilih Tanggal Sewa',
                              style: GoogleFonts.beVietnamPro(
                                color: context.colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (startDate != null && endDate != null)
                                ? '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}'
                                : 'Ketuk untuk atur jadwal',
                              style: GoogleFonts.beVietnamPro(
                                color: context.colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: context.colors.textMuted),
                    ],
                  ),
                ),
              ),

              // Items
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: provider.cart.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final cartItem = provider.cart[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              cartItem.item.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (c,e,s) => Container(
                                width: 80, height: 80, color: context.colors.surface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cartItem.item.name,
                                  style: GoogleFonts.beVietnamPro(
                                    color: context.colors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
                                      .format(cartItem.item.pricePerDay),
                                  style: GoogleFonts.beVietnamPro(
                                    color: context.colors.primaryOrange,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: context.colors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                            icon: const Icon(Icons.remove, size: 16),
                                            onPressed: () => provider.updateQuantity(cartItem.item.id, cartItem.quantity - 1),
                                            color: context.colors.textPrimary,
                                          ),
                                          Text(
                                            '${cartItem.quantity}',
                                            style: GoogleFonts.beVietnamPro(
                                              color: context.colors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(4),
                                            icon: const Icon(Icons.add, size: 16),
                                            onPressed: () => provider.updateQuantity(cartItem.item.id, cartItem.quantity + 1),
                                            color: context.colors.textPrimary,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      onPressed: () => provider.removeFromCart(cartItem.item.id),
                                      icon: Icon(Icons.delete_outline_rounded, color: context.colors.error, size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Sheet
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(validDays > 0 ? 'Sewa Alat ($validDays Hari)' : 'Belum pilih tanggal', style: GoogleFonts.beVietnamPro(color: context.colors.textSecondary)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(totalPerDay * daysMultiplier),
                          style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (provider.deliveryFee > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Biaya Antar/Jemput', style: GoogleFonts.beVietnamPro(color: context.colors.textSecondary)),
                          Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(provider.deliveryFee),
                            style: GoogleFonts.beVietnamPro(color: context.colors.primaryOrange, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Pembayaran', style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary, fontWeight: FontWeight.w700)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(grandTotal),
                          style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isCheckingOut ? null : _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primaryOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isCheckingOut 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              'Bayar Sekarang',
                              style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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
