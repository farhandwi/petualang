import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/mountain_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'booking_form_screen.dart';

class MountainDetailScreen extends StatelessWidget {
  final MountainModel mountain;

  const MountainDetailScreen({super.key, required this.mountain});

  /// Routing tombol "Pesan Sekarang":
  /// - Jika gunung punya external booking aktif → buka URL eksternal di
  ///   browser (`launchUrl`).
  /// - Jika tidak → navigasi ke [BookingFormScreen] internal.
  Future<void> _onPesanPressed(BuildContext context) async {
    if (mountain.hasExternalBooking) {
      final uri = Uri.tryParse(mountain.externalBookingUrl!.trim());
      if (uri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL pembelian tidak valid')),
        );
        return;
      }
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka URL')),
        );
      }
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingFormScreen(mountain: mountain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.maxReadingWidth),
          child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with Hero and Back Button
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            backgroundColor: context.colors.background,
            leadingWidth: 70,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Hero(
                tag: 'mountain_image_${mountain.id}',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      mountain.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: context.colors.border,
                        child: Center(
                          child: Icon(Icons.terrain_rounded, size: 80, color: context.colors.textMuted),
                        ),
                      ),
                    ),
                    // Gradient Overlay
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black26,
                            Colors.transparent,
                            Colors.black54,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Difficulty
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mountain.name,
                                style: GoogleFonts.beVietnamPro(
                                  color: context.colors.textPrimary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 16, color: context.colors.primaryOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    mountain.location,
                                    style: GoogleFonts.beVietnamPro(
                                      color: context.colors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: mountain.difficulty == 'Sulit' 
                                ? Colors.red.withOpacity(0.1) 
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            mountain.difficulty,
                            style: GoogleFonts.beVietnamPro(
                              color: mountain.difficulty == 'Sulit' ? Colors.red : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Quick Info Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoChip(
                          icon: Icons.height_rounded,
                          label: 'Ketinggian',
                          value: '${mountain.elevation} mdpl',
                        ),
                        _InfoChip(
                          icon: Icons.access_time_rounded,
                          label: 'Estimasi',
                          value: '2-4 Hari',
                        ),
                        _InfoChip(
                          icon: Icons.star_rounded,
                          label: 'Rating',
                          value: '4.9/5.0',
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Description
                    Text(
                      'Tentang Gunung',
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mountain.description,
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textSecondary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
        ),
      ),
      bottomSheet: Container(
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
        child: Row(
          children: [
            // Harga tiket disembunyikan saat pembelian eksternal aktif —
            // pricing dikelola oleh website mitra eksternal.
            if (!mountain.hasExternalBooking) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Harga Tiket',
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
                        .format(mountain.price),
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _onPesanPressed(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  mountain.hasExternalBooking
                      ? Icons.open_in_new_rounded
                      : Icons.confirmation_number_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  'Pesan Sekarang',
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: context.colors.primaryOrange, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.beVietnamPro(
              color: context.colors.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              color: context.colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
