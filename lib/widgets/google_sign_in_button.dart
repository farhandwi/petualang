import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, this.onSuccess});

  /// Dipanggil setelah login Google sukses (untuk navigate dst).
  final VoidCallback? onSuccess;

  Future<void> _handlePressed(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithGoogle();
    if (!context.mounted) return;

    if (success) {
      onSuccess?.call();
      return;
    }

    // Hanya tampilkan toast jika ada error message (bukan user cancel).
    final msg = auth.errorMessage;
    if (msg != null && msg.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: context.colors.error, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: GoogleFonts.beVietnamPro(
                    color: context.colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: context.colors.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : () => _handlePressed(context),
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.textPrimary,
          side: BorderSide(color: colors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const _GoogleLogo(size: 20),
        label: Text(
          'Lanjutkan dengan Google',
          style: GoogleFonts.beVietnamPro(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

/// Logo Google "G" sederhana berbasis CustomPaint — tidak butuh asset.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final r = w * 0.45;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Warna brand Google
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;

    // Top-right (red): -90° to 0°
    canvas.drawArc(rect, -1.5708, 1.5708, false, paint..color = red);
    // Bottom-right (yellow): 0° to 90°
    canvas.drawArc(rect, 0, 1.5708, false, paint..color = yellow);
    // Bottom-left (green): 90° to 180°
    canvas.drawArc(rect, 1.5708, 1.5708, false, paint..color = green);
    // Top-left (blue): 180° to 270°
    canvas.drawArc(rect, 3.1416, 1.5708, false, paint..color = blue);

    // "Bar" horizontal khas logo G — kotak biru di sisi kanan
    final barPaint = Paint()..color = blue;
    final barRect = Rect.fromLTWH(cx, cy - w * 0.09, r + w * 0.04, w * 0.18);
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
