import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/mountain_model.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'ticket_success_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final MountainModel mountain;

  const BookingFormScreen({super.key, required this.mountain});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  DateTime _selectedDate = DateTime.now();
  int _climbersCount = 1;
  RouteModel? _selectedRoute;

  @override
  void initState() {
    super.initState();
    if (widget.mountain.routes.isNotEmpty) {
      _selectedRoute = widget.mountain.routes.first;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: context.colors.primaryOrange,
              primary: context.colors.primaryOrange,
              onPrimary: Colors.white,
              surface: context.colors.card,
              onSurface: context.colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleSubmit() async {
    final bookingProvider = context.read<BookingProvider>();
    final double totalPrice = widget.mountain.price * _climbersCount;

    final ticket = await bookingProvider.bookTicket(
      mountainId: widget.mountain.id,
      mountainRouteId: _selectedRoute?.id,
      date: _selectedDate,
      climbersCount: _climbersCount,
      totalPrice: totalPrice,
    );

    if (!mounted) return;

    if (ticket != null) {
      final paymentUrl = bookingProvider.lastPaymentUrl;
      
      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        final uri = Uri.parse(paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => TicketSuccessScreen(
            ticket: ticket,
            mountain: widget.mountain,
            totalPrice: totalPrice,
            climbersCount: _climbersCount,
            date: _selectedDate,
          ),
        ),
        (route) => route.isFirst,
      );
    } else if (bookingProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.errorMessage!),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<BookingProvider>().isLoading;
    final double totalPrice = widget.mountain.price * _climbersCount;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          'Detail Pemesanan',
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ContentConstrained.form(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mountain static info
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            widget.mountain.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.mountain.name,
                                style: GoogleFonts.beVietnamPro(
                                  color: context.colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${widget.mountain.elevation} mdpl',
                                style: GoogleFonts.beVietnamPro(
                                  color: context.colors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),

                    // Route Selection
                    Text(
                      'Pilih Jalur Pendakian',
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.mountain.routes.isEmpty)
                      Text(
                        'Belum ada jalur yang tersedia',
                        style: GoogleFonts.beVietnamPro(color: context.colors.textMuted),
                      )
                    else
                      DropdownButtonFormField<RouteModel>(
                        initialValue: _selectedRoute,
                        items: widget.mountain.routes.map((route) {
                          return DropdownMenuItem(
                            value: route,
                            child: Text(
                              route.name,
                              style: GoogleFonts.beVietnamPro(
                                color: context.colors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedRoute = val),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: context.colors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: context.colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: context.colors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Date Picker
                    Text(
                      'Tanggal Pendakian',
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: context.colors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: context.colors.primaryOrange, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate),
                              style: GoogleFonts.beVietnamPro(
                                color: context.colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Climbers Counter
                    Text(
                      'Jumlah Pendaki',
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _CounterButton(
                          icon: Icons.remove_rounded,
                          onPressed: _climbersCount > 1
                              ? () => setState(() => _climbersCount--)
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            '$_climbersCount',
                            style: GoogleFonts.beVietnamPro(
                              color: context.colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _CounterButton(
                          icon: Icons.add_rounded,
                          onPressed: () => setState(() => _climbersCount++),
                        ),
                        const Spacer(),
                        Text(
                          'Maks. 10 Orang',
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Summary
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.colors.primaryOrange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.colors.primaryOrange.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ringkasan Biaya',
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(Icons.receipt_long_rounded, color: context.colors.primaryOrange, size: 20),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tiket x$_climbersCount',
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
                              .format(totalPrice),
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedRoute != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jalur',
                            style: GoogleFonts.beVietnamPro(
                              color: context.colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _selectedRoute!.name,
                            style: GoogleFonts.beVietnamPro(
                              color: context.colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Bayar',
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
                              .format(totalPrice),
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.primaryOrange,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Checkout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Bayar Sekarang',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CounterButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.border, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: onPressed == null ? context.colors.textMuted : context.colors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
