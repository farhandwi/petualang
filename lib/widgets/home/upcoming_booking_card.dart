import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/upcoming_booking_model.dart';
import '../../theme/app_theme.dart';
import '../common/app_image.dart';

/// Card "Trip Mendatang" — booking gunung user yang akan datang.
/// Pakai data dari `UpcomingBookingModel` (tickets table).
class UpcomingBookingCard extends StatelessWidget {
  const UpcomingBookingCard({super.key, required this.booking});

  final UpcomingBookingModel booking;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');
    final daysUntil = booking.daysUntil;

    return SizedBox(
      width: 230,
      child: Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: AppImage(
                url: booking.mountainImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(colors),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.mountainName ?? 'Pendakian',
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFmt.format(booking.date),
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.primaryOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      daysUntil == 0
                          ? 'Hari ini!'
                          : '$daysUntil hari lagi',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.primaryOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(AppColors colors) => Container(
        color: colors.primaryOrange.withOpacity(0.12),
        alignment: Alignment.center,
        child: Icon(
          Icons.confirmation_number_rounded,
          color: colors.primaryOrange,
          size: 32,
        ),
      );
}
