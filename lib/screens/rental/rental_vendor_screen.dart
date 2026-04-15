import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/vendor_model.dart';
import '../../providers/rental_provider.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import 'rental_list_screen.dart';


class RentalVendorScreen extends StatefulWidget {
  const RentalVendorScreen({super.key});

  @override
  State<RentalVendorScreen> createState() => _RentalVendorScreenState();
}

class _RentalVendorScreenState extends State<RentalVendorScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RentalProvider>().fetchVendors();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    // Trigger load more 200px sebelum akhir list
    if (current >= maxScroll - 200) {
      context.read<RentalProvider>().loadMoreVendors();
    }
  }

  void _showLocationSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _LocationSearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalProvider>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Sewa Alat',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.bold, color: colors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: colors.textSecondary),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // ── Location Header ──
          GestureDetector(
            onTap: _showLocationSearch,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: colors.surface,
              child: Row(
                children: [
                  Icon(CupertinoIcons.location_solid, color: colors.primaryOrange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lokasi Anda',
                            style: GoogleFonts.beVietnamPro(fontSize: 11, color: colors.textSecondary)),
                        Text(
                          provider.currentLocationName,
                          style: GoogleFonts.beVietnamPro(
                              fontSize: 14, fontWeight: FontWeight.w700, color: colors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_down, color: colors.textSecondary, size: 14),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: colors.border),

          // ── Filter chips ──
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // Sort: Terdekat
                _FilterChip(
                  label: 'Terdekat',
                  selected: provider.vendorSortMode == VendorSortMode.nearest,
                  onTap: () => provider.setVendorSortMode(VendorSortMode.nearest),
                ),
                const SizedBox(width: 8),
                // Sort: Rating Tertinggi
                _FilterChip(
                  label: 'Rating Tertinggi',
                  selected: provider.vendorSortMode == VendorSortMode.topRated,
                  onTap: () => provider.setVendorSortMode(VendorSortMode.topRated),
                ),
                const SizedBox(width: 8),
                // Filter independen: Buka Sekarang
                _FilterChip(
                  label: 'Buka Sekarang',
                  selected: provider.showOpenOnly,
                  onTap: () => provider.toggleShowOpenOnly(),
                  isToggle: true,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.border),

          // ── Content ──
          Expanded(
            child: provider.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: colors.primaryOrange),
                        const SizedBox(height: 12),
                        Text('Memuat toko terdekat...',
                            style: GoogleFonts.beVietnamPro(color: colors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  )
                : provider.vendors.isEmpty
                    ? _EmptyState(
                        onRetry: () => provider.fetchVendors(),
                        isOpenFilter: provider.showOpenOnly,
                        onShowAll: () => provider.toggleShowOpenOnly(),
                      )
                    : RefreshIndicator(
                        color: colors.primaryOrange,
                        onRefresh: () => provider.fetchVendors(),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: provider.vendorsPage.length + (provider.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (ctx, i) {
                            if (i == provider.vendorsPage.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(color: colors.primaryOrange),
                                ),
                              );
                            }
                            try {
                              return _VendorCard(vendor: provider.vendorsPage[i]);
                            } catch (e) {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Filter Chip Widget
// ─────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  /// Jika true, chip berperilaku sebagai toggle independen (icon berbeda)
  final bool isToggle;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryOrange.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.primaryOrange : colors.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon khusus untuk toggle "Buka Sekarang"
            if (isToggle) ...[
              Icon(
                selected ? Icons.check_circle_rounded : Icons.store_rounded,
                size: 13,
                color: selected ? colors.primaryOrange : colors.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                color: selected ? colors.primaryOrange : colors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (!isToggle) ...[
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_down,
                size: 12,
                color: selected ? colors.primaryOrange : colors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty State Widget
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  /// Apakah state kosong ini disebabkan oleh filter "Buka Sekarang"
  final bool isOpenFilter;
  /// Callback untuk menampilkan semua toko (matikan filter buka)
  final VoidCallback? onShowAll;

  const _EmptyState({
    required this.onRetry,
    this.isOpenFilter = false,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final title = isOpenFilter
        ? 'Semua toko sedang tutup'
        : 'Tidak ada toko di area ini';
    final subtitle = isOpenFilter
        ? 'Tidak ada toko yang buka saat ini di area Anda'
        : 'Coba ubah lokasi atau perluas area pencarian';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOpenFilter
                  ? CupertinoIcons.moon_zzz_fill
                  : CupertinoIcons.building_2_fill,
              size: 72,
              color: colors.textMuted.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.beVietnamPro(
                  color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            // Jika filter buka sekarang aktif, tawarkan opsi "Lihat Semua"
            if (isOpenFilter && onShowAll != null)
              ElevatedButton.icon(
                onPressed: onShowAll,
                icon: const Icon(Icons.store_mall_directory_rounded, size: 16),
                label: Text(
                  'Lihat Semua Toko',
                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('Coba Lagi', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primaryOrange,
                  side: BorderSide(color: colors.primaryOrange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Vendor Card Widget
// ─────────────────────────────────────────────
class _VendorCard extends StatelessWidget {
  final VendorModel vendor;
  const _VendorCard({required this.vendor});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dist = vendor.distance;
    final String distStr;
    final Color distColor;
    if (dist == null) {
      distStr = 'Jarak tidak diketahui';
      distColor = Colors.white70;
    } else if (dist < 5) {
      distStr = '${(dist * 1000).toStringAsFixed(0)} m';
      distColor = const Color(0xFF4ADE80); // hijau
    } else if (dist < 100) {
      distStr = '${dist.toStringAsFixed(1)} km';
      distColor = const Color(0xFF4ADE80);
    } else if (dist < 500) {
      distStr = '${dist.toStringAsFixed(0)} km';
      distColor = const Color(0xFFFBBF24); // kuning
    } else {
      distStr = '${dist.toStringAsFixed(0)} km';
      distColor = const Color(0xFFF87171); // merah
    }

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () {
          context.read<RentalProvider>().selectVendor(vendor);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RentalListScreen()));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Banner Image ──
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(context),
                  // Status badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: vendor.isOpen ? const Color(0xFF22C55E) : Colors.grey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vendor.isOpen ? 'BUKA' : 'TUTUP',
                        style: GoogleFonts.beVietnamPro(
                            color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                   // Distance badge — always visible
                   Positioned(
                     bottom: 0,
                     left: 0, right: 0,
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           begin: Alignment.topCenter,
                           end: Alignment.bottomCenter,
                           colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                         ),
                       ),
                       child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           Icon(CupertinoIcons.location_fill, color: distColor, size: 10),
                           const SizedBox(width: 4),
                           Text(distStr,
                               style: GoogleFonts.beVietnamPro(
                                   color: distColor, fontSize: 11, fontWeight: FontWeight.w700)),
                           const Spacer(),
                           Text(
                             vendor.isOpen ? '● BUKA' : '● TUTUP',
                             style: GoogleFonts.beVietnamPro(
                               color: vendor.isOpen ? const Color(0xFF4ADE80) : Colors.grey,
                               fontSize: 10, fontWeight: FontWeight.w700,
                             ),
                           ),
                         ],
                       ),
                     ),
                   ),
                ],
              ),
            ),

            // ── Info Section ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          vendor.name,
                          style: GoogleFonts.beVietnamPro(
                              fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.star_fill, color: Color(0xFFF59E0B), size: 13),
                          const SizedBox(width: 3),
                          Text(
                            vendor.rating.toStringAsFixed(1),
                            style: GoogleFonts.beVietnamPro(
                                fontSize: 13, fontWeight: FontWeight.w700, color: colors.textPrimary),
                          ),
                          Text(' (${vendor.reviewCount})',
                              style: GoogleFonts.beVietnamPro(
                                  fontSize: 11, color: colors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Address
                  Row(
                    children: [
                      Icon(CupertinoIcons.location, size: 11, color: colors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          vendor.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(fontSize: 12, color: colors.textSecondary),
                        ),
                      ),
                    ],
                  ),

                  // Categories
                  if (vendor.categories.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: vendor.categories.take(4).map((cat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.primaryOrange.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: colors.primaryOrange.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            cat.toUpperCase(),
                            style: GoogleFonts.beVietnamPro(
                              color: colors.primaryOrange,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryOrange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        context.read<RentalProvider>().selectVendor(vendor);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RentalListScreen()));
                      },
                      child: Text('Lihat Alat Toko',
                          style: GoogleFonts.beVietnamPro(
                              fontSize: 13, fontWeight: FontWeight.w700)),
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

  Widget _buildImage(BuildContext context) {
    final url = vendor.imageUrl;
    if (url == null || url.isEmpty) return _imagePlaceholder(context);

    if (url.startsWith('assets/')) {
      return Image.asset(url, fit: BoxFit.cover,
          errorBuilder: (c, e, s) => _imagePlaceholder(context));
    }
    final resolved = url.startsWith('http') ? url : 'http://10.0.2.2:8080/$url';
    return Image.network(resolved, fit: BoxFit.cover,
        errorBuilder: (c, e, s) => _imagePlaceholder(context));
  }

  Widget _imagePlaceholder(BuildContext context) {
    return Container(
      color: context.colors.surface,
      child: Center(
        child: Icon(CupertinoIcons.photo,
            size: 48, color: context.colors.textMuted.withValues(alpha: 0.3)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Location Search Bottom Sheet
// ─────────────────────────────────────────────
class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet();
  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final TextEditingController _ctrl = TextEditingController();
  List<LocationResult> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 3) {
      if (mounted) setState(() => _results = []);
      return;
    }
    if (mounted) setState(() => _searching = true);
    final res = await LocationService.searchPlace(query);
    if (mounted) setState(() { _results = res; _searching = false; });
  }

  void _select(LocationResult loc) {
    context.read<RentalProvider>().setLocationFromSearch(loc);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              height: 4, width: 40,
              decoration: BoxDecoration(
                color: colors.textMuted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Cari Lokasi',
                  style: GoogleFonts.beVietnamPro(
                      fontSize: 18, fontWeight: FontWeight.w700, color: colors.textPrimary)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _search,
                style: GoogleFonts.beVietnamPro(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Ketik nama kota, kawasan, atau jalan...',
                  hintStyle: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 14),
                  filled: true,
                  fillColor: colors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: Icon(CupertinoIcons.search, color: colors.textMuted, size: 18),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: colors.textMuted, size: 18),
                          onPressed: () { _ctrl.clear(); setState(() => _results = []); })
                      : null,
                ),
              ),
            ),
            if (_searching)
              LinearProgressIndicator(
                  color: colors.primaryOrange,
                  backgroundColor: colors.primaryOrange.withValues(alpha: 0.1)),

            // Popular cities
            if (_results.isEmpty && !_searching) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('KOTA POPULER',
                      style: GoogleFonts.beVietnamPro(
                          fontSize: 11, color: colors.textSecondary,
                          fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ['Jakarta', 'Bandung', 'Yogyakarta', 'Semarang',
                    'Surabaya', 'Banyuwangi', 'Malang', 'Denpasar', 'Lombok']
                      .map((city) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CityChip(
                              city: city,
                              onTap: () { _ctrl.text = city; _search(city); },
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            Divider(color: colors.border, height: 1),

            // Results
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _results.length,
                separatorBuilder: (_, __) =>
                    Divider(color: colors.border, height: 1, indent: 56),
                itemBuilder: (_, i) {
                  final r = _results[i];
                  return ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: colors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(CupertinoIcons.location_solid,
                          color: colors.primaryOrange, size: 16),
                    ),
                    title: Text(r.shortName,
                        style: GoogleFonts.beVietnamPro(
                            color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(r.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(
                            color: colors.textSecondary, fontSize: 12)),
                    onTap: () => _select(r),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityChip extends StatelessWidget {
  final String city;
  final VoidCallback onTap;
  const _CityChip({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.location, size: 11, color: colors.textSecondary),
            const SizedBox(width: 4),
            Text(city,
                style: GoogleFonts.beVietnamPro(
                    color: colors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
