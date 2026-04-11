import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

class PermissionHelper {
  /// Checks and requests photos/gallery permission with a professional flow.
  /// Returns [true] if permission is granted, [false] otherwise.
  static Future<bool> checkPhotosPermission(BuildContext context) async {
    // 1. Initial Check
    PermissionStatus status = await Permission.photos.status;

    // On Android 13+, photos permission is more specific. 
    // On older Android, it's storage. Handle based on library's abstraction.
    if (status.isGranted || status.isLimited) {
      return true;
    }

    // 2. If Denied (not permanently yet), show professional Rationale Dialog
    if (status.isDenied) {
      final shouldRequest = await showRationaleDialog(
        context,
        title: 'Akses Galeri Diperlukan',
        message: 'Aplikasi memerlukan akses ke galeri foto Anda agar Anda dapat mengunggah foto petualangan ke komunitas.',
        icon: Icons.photo_library_rounded,
      );

      if (shouldRequest != true) return false;

      // Request now
      status = await Permission.photos.request();
      
      // Secondary check for older android/ios storage permission if photos fails
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
    }

    // 3. If Permanently Denied, show Settings Redirect
    if (status.isPermanentlyDenied) {
      await showSettingsDialog(context);
      return false;
    }

    return status.isGranted || status.isLimited;
  }

  /// Professional Rationale Dialog
  static Future<bool?> showRationaleDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    final colors = context.colors;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.primaryOrange, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryOrange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Izinkan', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog when permission is permanently denied
  static Future<void> showSettingsDialog(BuildContext context) {
    final colors = context.colors;
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Izin Dinonaktifkan',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Izin akses galeri telah dinonaktifkan secara permanen. Silakan aktifkan di Pengaturan Aplikasi agar dapat mengunggah foto.',
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }
}
