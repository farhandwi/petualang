import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/rental_provider.dart';
import '../../theme/app_theme.dart';
import '../../config/app_config.dart';
import 'rental_detail_screen.dart';
import 'rental_cart_screen.dart';

class RentalListScreen extends StatefulWidget {
  const RentalListScreen({super.key});

  @override
  State<RentalListScreen> createState() => _RentalListScreenState();
}

class _RentalListScreenState extends State<RentalListScreen> {
  final List<String> _categories = [
    'Semua',
    'Shelter',
    'Carrier',
    'Cooking',
    'Navigasi',
    'Penerangan',
    'Pakaian'
  ];

  @override
  void initState() {
    super.initState();
    // Fetch items is already triggered by RentalSearchScreen before navigating here
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalProvider>();

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: provider.totalItemsInCart > 0 
        ? FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const RentalCartScreen())
              );
            },
            backgroundColor: context.colors.primaryOrange,
            icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
            label: Text(
              '${provider.totalItemsInCart} Item',
              style: GoogleFonts.beVietnamPro(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        : null,
      body: SafeArea(
        child: Column(
          children: [
            // Context Header Banner
            if (provider.selectedMountain != null)
              Container(
                margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.colors.primaryOrange, context.colors.primaryOrange.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.terrain_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alat untuk ${provider.selectedMountain!.name}',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('dd MMM').format(provider.startDate!)} - ${DateFormat('dd MMM yyyy').format(provider.endDate!)}',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Naik: ${provider.entryRoute?.name} • Turun: ${provider.exitRoute?.name}',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_location_alt_rounded, color: Colors.white),
                      tooltip: 'Ganti Lokasi',
                      onPressed: () {
                        provider.clearRentalTarget();
                      },
                    ),
                  ],
                ),
              ),

            // Search Bar header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => provider.setSearchQuery(val),
                      style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Cari alat sewa...',
                        hintStyle: GoogleFonts.beVietnamPro(color: context.colors.textHint),
                        prefixIcon: Icon(Icons.search_rounded, color: context.colors.textMuted),
                        filled: true,
                        fillColor: context.colors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Categories
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = provider.selectedCategory == cat;
                  
                  return GestureDetector(
                    onTap: () => provider.setCategory(cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? context.colors.primaryOrange : context.colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? context.colors.primaryOrange : context.colors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: GoogleFonts.beVietnamPro(
                          color: isSelected ? Colors.white : context.colors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Grid Items
            Expanded(
              child: provider.isLoading 
                ? Center(child: CircularProgressIndicator(color: context.colors.primaryOrange))
                : provider.filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada alat ditemukan',
                        style: GoogleFonts.beVietnamPro(color: context.colors.textMuted),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.fetchItems(),
                      color: context.colors.primaryOrange,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.55,
                        ),
                        itemCount: provider.filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = provider.filteredItems[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RentalDetailScreen(item: item),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: context.colors.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: context.colors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  Expanded(
                                    flex: 12,
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          child: Image.asset(
                                            item.imageUrl,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => Container(
                                              color: context.colors.surface,
                                              child: Icon(Icons.inventory_2_rounded, color: context.colors.textMuted, size: 40),
                                            ),
                                          ),
                                        ),
                                        // Condition Badge
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.condition,
                                              style: GoogleFonts.beVietnamPro(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Details
                                  Expanded(
                                    flex: 11,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.brand,
                                                style: GoogleFonts.beVietnamPro(
                                                  color: context.colors.textMuted,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.name,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.beVietnamPro(
                                                  color: context.colors.textPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(item.pricePerDay)}/hari',
                                                style: GoogleFonts.beVietnamPro(
                                                  color: context.colors.primaryOrange,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Sisa stok: ${item.availableStock}',
                                                style: GoogleFonts.beVietnamPro(
                                                  color: context.colors.textSecondary,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
