import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/booking_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'mountain_detail_screen.dart';

class MountainListScreen extends StatefulWidget {
  const MountainListScreen({super.key});

  @override
  State<MountainListScreen> createState() => _MountainListScreenState();
}

class _MountainListScreenState extends State<MountainListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchMountains();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final filteredMountains = bookingProvider.filteredMountains;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          'Pilih Gunung',
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: context.colors.card,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: Breakpoints.maxContentWidth),
          child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => bookingProvider.setSearchQuery(value),
                style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Cari nama gunung atau jalur...',
                  hintStyle: GoogleFonts.beVietnamPro(color: context.colors.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: context.colors.primaryOrange),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            bookingProvider.setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: bookingProvider.isLoading
                ? Center(child: CircularProgressIndicator(color: context.colors.primaryOrange))
                : bookingProvider.errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 60, color: context.colors.error),
                            const SizedBox(height: 16),
                            Text(
                              bookingProvider.errorMessage!,
                              style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => bookingProvider.fetchMountains(),
                              style: ElevatedButton.styleFrom(backgroundColor: context.colors.primaryOrange),
                              child: Text(
                                'Coba Lagi',
                                style: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      )
                    : filteredMountains.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 60, color: context.colors.textMuted),
                                const SizedBox(height: 16),
                                Text(
                                  'Gunung atau jalur tidak ditemukan',
                                  style: GoogleFonts.beVietnamPro(color: context.colors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : context.isMobile
                            ? ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredMountains.length,
                                itemBuilder: (c, index) => _buildMountainCard(c, filteredMountains[index]),
                              )
                            : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredMountains.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: context.gridColumns(
                                  mobile: 1, tablet: 2, desktop: 2, large: 3),
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 380,
                            ),
                            itemBuilder: (context, index) {
                              final mountain = filteredMountains[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MountainDetailScreen(mountain: mountain),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: context.colors.card,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Cover Image
                                      Hero(
                                        tag: 'mountain_image_${mountain.id}',
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                          child: Image.asset(
                                            mountain.imageUrl,
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              height: 200,
                                              color: context.colors.border,
                                              child: Center(
                                                child: Icon(Icons.terrain_rounded, size: 64, color: context.colors.textMuted),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Details
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    mountain.name,
                                                    style: GoogleFonts.beVietnamPro(
                                                      color: context.colors.textPrimary,
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: context.colors.primaryOrange.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '${mountain.elevation} mdpl',
                                                    style: GoogleFonts.beVietnamPro(
                                                      color: context.colors.primaryOrange,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on_rounded, size: 16, color: context.colors.textMuted),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    mountain.location,
                                                    style: GoogleFonts.beVietnamPro(
                                                      color: context.colors.textSecondary,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                if (mountain.hasExternalBooking)
                                                  // Saat pembelian eksternal aktif, ganti
                                                  // harga dengan label kecil agar layout
                                                  // tetap balance dengan tombol arrow.
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.purple.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.open_in_new_rounded,
                                                            size: 14, color: Colors.purple),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'Pembelian Eksternal',
                                                          style: GoogleFonts.beVietnamPro(
                                                            color: Colors.purple,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                else
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'Harga Tiket',
                                                        style: GoogleFonts.beVietnamPro(
                                                          color: context.colors.textMuted,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      Text(
                                                        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
                                                            .format(mountain.price),
                                                        style: GoogleFonts.beVietnamPro(
                                                          color: context.colors.textPrimary,
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: context.colors.primaryOrange,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.arrow_forward_rounded,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildMountainCard(BuildContext context, dynamic mountain) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MountainDetailScreen(mountain: mountain),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'mountain_image_${mountain.id}',
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.asset(
                  mountain.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: context.colors.border,
                    child: Center(
                      child: Icon(Icons.terrain_rounded,
                          size: 64, color: context.colors.textMuted),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          mountain.name,
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.colors.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${mountain.elevation} mdpl',
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.primaryOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 16, color: context.colors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mountain.location,
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textSecondary,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (mountain.hasExternalBooking)
                        // Saat pembelian eksternal aktif, harga di-hide; ganti
                        // dengan badge label kecil agar layout tetap balance.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_new_rounded,
                                  size: 14, color: Colors.purple),
                              const SizedBox(width: 4),
                              Text(
                                'Pembelian Eksternal',
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.purple,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harga Tiket',
                              style: GoogleFonts.beVietnamPro(
                                color: context.colors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp',
                                      decimalDigits: 0)
                                  .format(mountain.price),
                              style: GoogleFonts.beVietnamPro(
                                color: context.colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
