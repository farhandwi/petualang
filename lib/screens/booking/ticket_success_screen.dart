import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/mountain_model.dart';
import '../../models/ticket_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class TicketSuccessScreen extends StatelessWidget {
  final TicketModel ticket;
  final MountainModel mountain;
  final double totalPrice;
  final int climbersCount;
  final DateTime date;

  const TicketSuccessScreen({
    super.key,
    required this.ticket,
    required this.mountain,
    required this.totalPrice,
    required this.climbersCount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ContentConstrained.form(
            child: Column(
            children: [
              // Success Header
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                'Pemesanan Berhasil!',
                style: GoogleFonts.beVietnamPro(
                  color: context.colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tiket elektronik Anda telah diterbitkan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 40),

              // The Virtual Ticket
              Container(
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Mountain Header
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Stack(
                        children: [
                          Image.asset(
                            mountain.imageUrl,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 16,
                            child: Text(
                              mountain.name,
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ticket Info
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _TicketCell(
                                label: 'TANGGAL',
                                value: DateFormat('dd MMM yyyy', 'id_ID').format(date),
                              ),
                              _TicketCell(
                                label: 'PENDAKI',
                                value: '$climbersCount Orang',
                                crossAxisAlignment: CrossAxisAlignment.end,
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Divider(thickness: 1, height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _TicketCell(
                                label: 'KODE BOOKING',
                                value: ticket.bookingCode,
                              ),
                              _TicketCell(
                                label: 'STATUS',
                                value: 'DIBAYAR',
                                crossAxisAlignment: CrossAxisAlignment.end,
                                valueColor: Colors.green,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Mock QR Code Area
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.qr_code_2_rounded, size: 140, color: Colors.black),
                                const SizedBox(height: 12),
                                Text(
                                  'Tunjukkan QR ini saat Registrasi',
                                  style: GoogleFonts.beVietnamPro(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Selesai',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Syarat & Ketentuan Berlaku',
                style: GoogleFonts.beVietnamPro(
                  color: context.colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _TicketCell extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment crossAxisAlignment;
  final Color? valueColor;

  const _TicketCell({
    required this.label,
    required this.value,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            color: valueColor ?? context.colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
