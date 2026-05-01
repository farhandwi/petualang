import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../screens/booking/mountain_list_screen.dart';
import '../../screens/rental/rental_main_screen.dart';
import '../../screens/community/community_screen.dart';
import '../../screens/buddies/buddy_list_screen.dart';

/// 4 service cards di home — sesuai mockup gambar 2:
/// Tiket Gunung, Sewa Alat, Komunitas, Cari Barengan
class ServiceCardsGrid extends StatelessWidget {
  const ServiceCardsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      _Service(
        label: 'Tiket\nGunung',
        icon: Icons.confirmation_number_rounded,
        color: const Color(0xFFFF6B35),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MountainListScreen()),
        ),
      ),
      _Service(
        label: 'Sewa\nAlat',
        icon: Icons.backpack_rounded,
        color: const Color(0xFF10B981),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RentalMainScreen()),
        ),
      ),
      _Service(
        label: 'Komunitas',
        icon: Icons.people_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CommunityScreen()),
        ),
      ),
      _Service(
        label: 'Cari\nBarengan',
        icon: Icons.handshake_rounded,
        color: const Color(0xFFFBBC05),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BuddyListScreen()),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: services
            .asMap()
            .entries
            .map((e) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: e.key < services.length - 1 ? 10 : 0,
                    ),
                    child: _ServiceCard(service: e.value),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _Service {
  _Service({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});
  final _Service service;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: service.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: service.color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(service.icon, color: service.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              service.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: GoogleFonts.beVietnamPro(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
