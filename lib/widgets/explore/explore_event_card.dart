import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../theme/app_theme.dart';
import '../../screens/events/event_detail_screen.dart';
import '../common/app_image.dart';

class ExploreEventCard extends StatelessWidget {
  const ExploreEventCard({super.key, required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('d MMM yyyy · HH:mm', 'id_ID');
    final daysUntil = event.daysUntil;

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
                  url: event.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(colors),
                ),
                if (daysUntil >= 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: daysUntil <= 7
                            ? colors.error
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        daysUntil == 0
                            ? 'HARI INI'
                            : '$daysUntil hari lagi',
                        style: GoogleFonts.beVietnamPro(
                          color:
                              daysUntil <= 7 ? Colors.white : Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
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
                  event.title,
                  style: GoogleFonts.beVietnamPro(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      color: colors.textMuted,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        dateFmt.format(event.eventDate),
                        style: GoogleFonts.beVietnamPro(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (event.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: colors.textMuted,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            color: colors.textMuted,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.maxParticipants != null
                                ? '${event.currentParticipants}/${event.maxParticipants} peserta'
                                : '${event.currentParticipants} peserta',
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EventDetailScreen(eventId: event.id),
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
        child: Icon(Icons.event_rounded, color: colors.primaryOrange, size: 48),
      );
}
