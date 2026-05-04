import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/custom_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? context.colors.error : context.colors.success,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary),
              ),
            ),
          ],
        ),
        backgroundColor: context.colors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();

    final result = await auth.resetPassword(
      email: widget.email,
      token: _tokenController.text.trim(),
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      _showSnackbar(result.message, isError: false);
      // Navigate all the way back to the login screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showSnackbar(result.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ContentConstrained.form(
            child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Icon Header
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.colors.primaryOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.mark_email_read_rounded,
                    color: context.colors.primaryOrange,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Masukkan OTP',
                  style: GoogleFonts.beVietnamPro(
                    color: context.colors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  'Kode pemulihan 6-digit telah dikirim ke:\n${widget.email}',
                  style: GoogleFonts.beVietnamPro(
                    color: context.colors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),

                // OTP Field
                CustomTextField(
                  label: 'Kode OTP',
                  hint: '123456',
                  prefixIcon: Icons.pin_outlined,
                  controller: _tokenController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Kode OTP wajib diisi';
                    if (v.length < 6) return 'Kode harus 6 digit';
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // New Password Field
                CustomTextField(
                  label: 'Sandi Baru',
                  hint: 'Masukkan sandi baru',
                  prefixIcon: Icons.lock_outline_rounded,
                  controller: _passwordController,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Sandi baru wajib diisi';
                    if (v.length < 6) return 'Sandi minimal 6 karakter';
                    return null;
                  },
                ),

                const SizedBox(height: 48),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primaryOrange,
                      disabledBackgroundColor: context.colors.primaryOrange.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Atur Ulang Sandi',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}
