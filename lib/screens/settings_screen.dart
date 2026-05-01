import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'identity_verification_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  void _showThemeDialog(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: parentContext.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Tema Tampilan',
                      style: GoogleFonts.beVietnamPro(
                        color: parentContext.colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ThemeOption(
                      title: 'Tema Sistem',
                      icon: Icons.brightness_auto_rounded,
                      isSelected: themeProvider.themeMode == ThemeMode.system,
                      onTap: () => themeProvider.setTheme(ThemeMode.system),
                    ),
                    _ThemeOption(
                      title: 'Mode Terang',
                      icon: Icons.light_mode_rounded,
                      isSelected: themeProvider.themeMode == ThemeMode.light,
                      onTap: () => themeProvider.setTheme(ThemeMode.light),
                    ),
                    _ThemeOption(
                      title: 'Mode Gelap',
                      icon: Icons.dark_mode_rounded,
                      isSelected: themeProvider.themeMode == ThemeMode.dark,
                      onTap: () => themeProvider.setTheme(ThemeMode.dark),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Keluar Akun?',
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Petualang Anda?',
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.beVietnamPro(
                color: context.colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // close settings
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.beVietnamPro(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final verificationStatus = user?.verificationStatus ?? 'unverified';

    // Badge config per status verifikasi
    final Map<String, Map<String, dynamic>> verifConfig = {
      'unverified': {
        'badge': 'Belum Diverifikasi',
        'badgeColor': context.colors.textMuted,
        'badgeBg': context.colors.input,
        'subtitle': 'Verifikasi identitas untuk akses penuh',
      },
      'pending': {
        'badge': 'Menunggu Review',
        'badgeColor': const Color(0xFFFFC107),
        'badgeBg': const Color(0xFFFFC107),
        'subtitle': 'Sedang diproses oleh tim kami',
      },
      'verified': {
        'badge': 'Terverifikasi ✓',
        'badgeColor': const Color(0xFF00B894),
        'badgeBg': const Color(0xFF00B894),
        'subtitle': 'Identitas Anda telah diverifikasi',
      },
      'rejected': {
        'badge': 'Ditolak',
        'badgeColor': context.colors.error,
        'badgeBg': context.colors.error,
        'subtitle': 'Kirim ulang dokumen yang valid',
      },
    };
    final vcfg = verifConfig[verificationStatus] ?? verifConfig['unverified']!;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
        backgroundColor: context.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Akun',
              style: GoogleFonts.beVietnamPro(
                color: context.colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _SettingsMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Edit Profil',
              subtitle: 'Ubah data diri dan informasi penting',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EditProfileScreen()),
                );
              },
            ),
            // ── Verifikasi Identitas ─────────────────────────────────────
            _SettingsMenuItemWithBadge(
              icon: Icons.shield_outlined,
              title: 'Verifikasi Identitas',
              subtitle: vcfg['subtitle'] as String,
              badgeText: vcfg['badge'] as String,
              badgeColor: (vcfg['badgeColor'] as Color).withAlpha(200),
              badgeBg: (vcfg['badgeBg'] as Color).withAlpha(25),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const IdentityVerificationScreen()),
                );
              },
            ),
            _SettingsMenuItem(
              icon: Icons.history_rounded,
              title: 'Riwayat Trip',
              subtitle: 'Lihat perjalanan Anda sebelumnya',
              onTap: () {},
            ),
            _SettingsMenuItem(
              icon: Icons.handyman_outlined,
              title: 'Sewa Saya',
              subtitle: 'Status penyewaan alat naik gunung',
              onTap: () {},
            ),
            _SettingsMenuItem(
              icon: Icons.palette_outlined,
              title: 'Tema Tampilan',
              subtitle: 'Atur mode terang atau gelap',
              onTap: () => _showThemeDialog(context),
            ),
            const SizedBox(height: 32),
            Text(
              'Lainnya',
              style: GoogleFonts.beVietnamPro(
                color: context.colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _SettingsMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Pusat Bantuan',
              onTap: () {},
            ),
            _SettingsMenuItem(
              icon: Icons.info_outline_rounded,
              title: 'Tentang Aplikasi',
              onTap: () {},
            ),
            const SizedBox(height: 40),
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: Icon(Icons.logout_rounded, color: context.colors.error),
                label: Text(
                  'Keluar Akun',
                  style: GoogleFonts.beVietnamPro(
                    color: context.colors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: context.colors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.colors.input,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: context.colors.primaryOrange, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: GoogleFonts.beVietnamPro(
                  color: context.colors.textMuted,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: context.colors.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Item pengaturan dengan badge status (untuk Verifikasi Identitas)
class _SettingsMenuItemWithBadge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBg;
  final VoidCallback onTap;

  const _SettingsMenuItemWithBadge({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.input,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    Icon(icon, color: context.colors.primaryOrange, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge status verifikasi
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.beVietnamPro(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: context.colors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? context.colors.primaryOrange.withAlpha(25)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? context.colors.primaryOrange
                  : context.colors.textMuted,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.beVietnamPro(
                  color: isSelected
                      ? context.colors.primaryOrange
                      : context.colors.textPrimary,
                  fontSize: 16,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: context.colors.primaryOrange,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
