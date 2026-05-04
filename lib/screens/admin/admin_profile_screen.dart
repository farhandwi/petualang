import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Profil Admin', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colors.primaryOrange.withValues(alpha: 0.15),
                  child: Icon(Icons.shield_rounded, color: colors.primaryOrange, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Admin',
                  style: GoogleFonts.beVietnamPro(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  user?.email ?? '-',
                  style: GoogleFonts.beVietnamPro(color: colors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ADMINISTRATOR',
                    style: GoogleFonts.beVietnamPro(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Material(
            color: colors.card,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _confirmLogout(context),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Anda akan keluar dari panel admin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    await context.read<AuthProvider>().logout();
  }
}
