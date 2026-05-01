import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/explore_model.dart';
import '../../theme/app_theme.dart';
import '../../screens/explore/open_trip_detail_screen.dart';
import '../common/app_image.dart';

class ExploreTripCard extends StatelessWidget {
  const ExploreTripCard({super.key, required this.trip});

  final OpenTripModel trip;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('d MMM', 'id_ID');
    final priceFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final spotsLeft = trip.maxParticipants - trip.currentParticipants;
    final dateRange =
        '${dateFmt.format(trip.startDate)} – ${dateFmt.format(trip.endDate)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(
                  url: trip.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(colors),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dateRange,
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (spotsLeft > 0 && spotsLeft <= 3)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Sisa $spotsLeft',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.title,
                  style: GoogleFonts.beVietnamPro(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      color: colors.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trip.currentParticipants}/${trip.maxParticipants} pendaki',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga per orang',
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            priceFmt.format(trip.price),
                            style: GoogleFonts.beVietnamPro(
                              color: colors.primaryOrange,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OpenTripDetailScreen(trip: trip),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: Text(
                        'Lihat Detail',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  Widget _fallback(AppColors colors) => Container(
        color: colors.primaryOrange.withOpacity(0.12),
        alignment: Alignment.center,
        child: Icon(Icons.map_rounded, color: colors.primaryOrange, size: 48),
      );
}
