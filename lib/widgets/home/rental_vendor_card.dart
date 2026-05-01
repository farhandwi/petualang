import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/vendor_model.dart';
import '../../theme/app_theme.dart';
import '../../screens/rental/rental_main_screen.dart';
import '../common/app_image.dart';

class RentalVendorCard extends StatelessWidget {
  const RentalVendorCard({super.key, required this.vendor});

  final VendorModel vendor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      width: 180,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RentalMainScreen()),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: AppImage(
                  url: vendor.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(colors),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name,
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFBBC05),
                          size: 13,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          vendor.rating.toStringAsFixed(1),
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '· ${vendor.reviewCount} ulasan',
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textMuted,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: colors.textMuted,
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            vendor.address,
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
        color: const Color(0xFF10B981).withOpacity(0.12),
        alignment: Alignment.center,
        child: const Icon(
          Icons.storefront_rounded,
          color: Color(0xFF10B981),
          size: 32,
        ),
      );
}
