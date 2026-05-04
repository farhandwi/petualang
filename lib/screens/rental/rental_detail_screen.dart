import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/rental_provider.dart';
import '../../models/rental_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';

class RentalDetailScreen extends StatefulWidget {
  final RentalItemModel item;

  const RentalDetailScreen({super.key, required this.item});

  @override
  State<RentalDetailScreen> createState() => _RentalDetailScreenState();
}

class _RentalDetailScreenState extends State<RentalDetailScreen> {
  int _quantity = 1;

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
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: context.colors.surface,
                      child: Center(
                        child: Icon(Icons.inventory_2_rounded, size: 80, color: context.colors.textMuted),
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
                    // Brand Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.colors.primaryOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.item.brand,
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.primaryOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Title
                    Text(
                      widget.item.name,
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Info Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _InfoChip(
                          icon: Icons.category_rounded,
                          label: 'Kategori',
                          value: widget.item.category,
                        ),
                        _InfoChip(
                          icon: Icons.verified_rounded,
                          label: 'Kondisi',
                          value: widget.item.condition,
                        ),
                        _InfoChip(
                          icon: Icons.inventory_2_rounded,
                          label: 'Stok',
                          value: '${widget.item.availableStock} unit',
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Description
                    Text(
                      'Deskripsi',
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.item.description,
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
      bottomNavigationBar: SafeArea(
        child: Container(
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
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Harga per hari',
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
                          .format(widget.item.pricePerDay),
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                // Quantity Selector
                Container(
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 20),
                        onPressed: _quantity > 1 
                          ? () => setState(() => _quantity--) 
                          : null,
                        color: context.colors.textPrimary,
                      ),
                      Text(
                        '$_quantity',
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        onPressed: _quantity < widget.item.availableStock
                          ? () => setState(() => _quantity++)
                          : null,
                        color: context.colors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.item.availableStock > 0 ? () {
                  context.read<RentalProvider>().addToCart(widget.item, _quantity);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.item.name} ditambahkan ke keranjang', style: GoogleFonts.beVietnamPro()),
                      backgroundColor: context.colors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  widget.item.availableStock > 0 ? '+ Keranjang' : 'Stok Habis',
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
