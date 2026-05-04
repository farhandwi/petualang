import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../utils/responsive.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Aktif', 'Pending', 'Selesai', 'Dibatalkan'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final orderProvider = context.watch<OrderProvider>();

    final hPad = context.responsive<double>(
        mobile: 20, tablet: 32, desktop: 40);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                maxWidth: Breakpoints.maxContentWidth),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pesanan Saya',
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (orderProvider.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                ],
              ),
            ),
            _buildTabBar(colors, hPad),
            const SizedBox(height: 16),
            Expanded(
              child: _buildBody(colors, orderProvider, hPad),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppColors colors, OrderProvider provider, double hPad) {
    if (provider.isLoading && provider.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: colors.error),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.fetchOrders(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final activeTab = _tabs[_selectedTabIndex];
    final filteredOrders = provider.orders.where((o) => o.mappedTabStatus == activeTab).toList();

    if (filteredOrders.isEmpty) {
      return _buildEmptyState(colors);
    }

    final cols = context.gridColumns(mobile: 1, tablet: 2, desktop: 2, large: 3);

    Widget orderCardFor(int index) {
      final order = filteredOrders[index];
      if (order.type == 'ticket') {
        return _buildTicketOrderCard(colors, order);
      } else {
        return _buildRentalOrderCard(colors, order);
      }
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchOrders(),
      child: cols == 1
          ? ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, index) => orderCardFor(index),
            )
          : GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filteredOrders.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 220,
              ),
              itemBuilder: (_, index) => orderCardFor(index),
            ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: colors.border),
          const SizedBox(height: 24),
          Text(
            'Belum ada pesanan',
            style: GoogleFonts.beVietnamPro(
              color: colors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesanan kamu yang statusnya ${_tabs[_selectedTabIndex]}\nakan muncul di sini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: colors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(AppColors colors, double hPad) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: colors.input,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    _tabs[index],
                    style: GoogleFonts.beVietnamPro(
                      color: isSelected ? colors.primaryOrange : colors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTicketOrderCard(AppColors colors, OrderModel order) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final priceStr = currencyFormat.format(order.totalPrice);
    final dateStr = order.date != null ? DateFormat('dd MMM yyyy', 'id_ID').format(order.date!) : '-';
    
    // Status Badge colors
    Color badgeBg = const Color(0xFFE8F3EA);
    Color badgeText = const Color(0xFF2E4C31);
    if (order.mappedTabStatus == 'Pending') {
      badgeBg = const Color(0xFFFFF3E0);
      badgeText = const Color(0xFFE65100);
    } else if (order.mappedTabStatus == 'Dibatalkan') {
      badgeBg = const Color(0xFFFFEBEE);
      badgeText = const Color(0xFFC62828);
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2E4C31),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A6B4F),
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A6B4F), Color(0xFF3F5E44)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                              Text(
                                'Tiket Gunung',
                                style: GoogleFonts.beVietnamPro(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.displayStatus,
                                  style: GoogleFonts.beVietnamPro(
                                    color: badgeText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.title,
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: colors.border, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          priceStr,
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(order.mappedTabStatus == 'Pending' ? 'Bayar' : 'Lihat E-Tiket'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalOrderCard(AppColors colors, OrderModel order) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final priceStr = currencyFormat.format(order.totalPrice);
    
    String dateStr = '-';
    if (order.startDate != null && order.endDate != null) {
      final startFmt = DateFormat('dd').format(order.startDate!);
      final endFmt = DateFormat('dd MMM yyyy', 'id_ID').format(order.endDate!);
      if (order.startDate!.month == order.endDate!.month) {
        dateStr = '$startFmt–$endFmt';
      } else {
        final startFull = DateFormat('dd MMM', 'id_ID').format(order.startDate!);
        dateStr = '$startFull – $endFmt';
      }
    } else if (order.startDate != null) {
      dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(order.startDate!);
    }
    
    // Status Badge colors
    Color badgeBg = const Color(0xFFE8F3EA);
    Color badgeText = const Color(0xFF2E4C31);
    if (order.mappedTabStatus == 'Pending') {
      badgeBg = const Color(0xFFFFF3E0);
      badgeText = const Color(0xFFE65100);
    } else if (order.mappedTabStatus == 'Dibatalkan') {
      badgeBg = const Color(0xFFFFEBEE);
      badgeText = const Color(0xFFC62828);
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2E4C31),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8A6C52),
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8A6C52), Color(0xFF755B45)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                              Text(
                                'Sewa Alat',
                                style: GoogleFonts.beVietnamPro(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  order.displayStatus,
                                  style: GoogleFonts.beVietnamPro(
                                    color: badgeText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.title,
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: colors.border, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Pembayaran',
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          priceStr,
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(order.mappedTabStatus == 'Pending' ? 'Bayar' : 'Detail Sewa'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
