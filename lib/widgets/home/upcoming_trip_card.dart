import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/explore_model.dart';
import '../../theme/app_theme.dart';
import '../../screens/explore/open_trip_detail_screen.dart';
import '../common/app_image.dart';

/// Card "Trip Mendatang" — sesuai mockup gambar 2 dengan countdown "X hari lagi".
class UpcomingTripCard extends StatelessWidget {
  const UpcomingTripCard({super.key, required this.trip});

  final OpenTripModel trip;

  int get _daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tripDay =
        DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    return tripDay.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');
    final daysUntil = _daysUntil;

    return SizedBox(
      width: 230,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OpenTripDetailScreen(trip: trip),
          ),
        ),
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
                  url: trip.imageUrl,
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
                      trip.title,
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
                      dateFmt.format(trip.startDate),
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (daysUntil >= 0)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: colors.primaryOrange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                daysUntil == 0
                                    ? 'Hari ini'
                                    : '$daysUntil hari lagi',
                                style: GoogleFonts.beVietnamPro(
                                  color: colors.primaryOrange,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OpenTripDetailScreen(trip: trip),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Detail',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
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
        ),
      ),
    );
  }

  Widget _fallback(AppColors colors) => Container(
        color: colors.primaryOrange.withOpacity(0.12),
        alignment: Alignment.center,
        child: Icon(Icons.map_rounded, color: colors.primaryOrange, size: 32),
      );
}
