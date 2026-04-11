import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/explore_model.dart';
import '../../providers/explore_provider.dart';
import '../../theme/app_theme.dart';
import 'open_trip_detail_screen.dart';

class OpenTripListScreen extends StatefulWidget {
  const OpenTripListScreen({super.key});

  @override
  State<OpenTripListScreen> createState() => _OpenTripListScreenState();
}

class _OpenTripListScreenState extends State<OpenTripListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().fetchExploreData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExploreProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryOrange = context.colors.primaryOrange;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          'Jadwal Open Trip',
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
      body: provider.isLoading && provider.exploreData == null
          ? Center(child: CircularProgressIndicator(color: primaryOrange))
          : provider.error != null && provider.exploreData == null
              ? Center(
                  child: Text(
                    provider.error!,
                    style: GoogleFonts.beVietnamPro(color: context.colors.error),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: provider.exploreData?.openTrips.length ?? 0,
                  itemBuilder: (context, index) {
                    final trip = provider.exploreData!.openTrips[index];
                    return _VerticalOpenTripCard(trip: trip, isDark: isDark, primaryOrange: primaryOrange);
                  },
                ),
    );
  }
}

class _VerticalOpenTripCard extends StatelessWidget {
  final OpenTripModel trip;
  final bool isDark;
  final Color primaryOrange;

  const _VerticalOpenTripCard({
    required this.trip,
    required this.isDark,
    required this.primaryOrange,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFull = trip.currentParticipants >= trip.maxParticipants;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OpenTripDetailScreen(trip: trip)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isDark 
              ? Border.all(color: Colors.white.withOpacity(0.05))
              : Border.all(color: Colors.grey.shade100),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: trip.imageUrl != null
                    ? DecorationImage(image: AssetImage(trip.imageUrl!), fit: BoxFit.cover)
                    : null,
                color: trip.imageUrl == null ? primaryOrange.withOpacity(0.2) : null,
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isFull ? Colors.red : primaryOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isFull ? 'Penuh' : 'Tersedia',
                        style: GoogleFonts.beVietnamPro(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 16, color: primaryOrange),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('dd MMM').format(trip.startDate)} - ${DateFormat('dd MMM yyyy').format(trip.endDate)}',
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.group_rounded, size: 16, color: context.colors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '${trip.currentParticipants}/${trip.maxParticipants} Kuota Terisi',
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(trip.price),
                        style: GoogleFonts.beVietnamPro(
                          color: primaryOrange,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
    );
  }
}
