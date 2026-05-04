import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Pill-style chip yang dipakai pada filter dashboard & form kategori.
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.primaryOrange : colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? colors.primaryOrange : colors.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: selected ? Colors.white : colors.textPrimary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
