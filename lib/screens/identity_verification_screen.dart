import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'terms_and_conditions_screen.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nikCtrl = TextEditingController();
  final _birthPlaceCtrl = TextEditingController();

  File? _ktpPhotoFile;
  File? _selfieKtpFile;

  bool _termsAccepted = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  /// Brand accent — dipakai untuk elemen KYC (hijau teal)
  static const Color _accent = Color(0xFF00B894);
  static const Color _accentDark = Color(0xFF00A67E);
  static const Color _indigo = Color(0xFF6C63FF);

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameCtrl.text = user.name;
      if (user.nik != null) _nikCtrl.text = user.nik!;
      if (user.birthPlace != null) _birthPlaceCtrl.text = user.birthPlace!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nikCtrl.dispose();
    _birthPlaceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isKtp) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      if (isKtp) {
        _ktpPhotoFile = File(picked.path);
      } else {
        _selfieKtpFile = File(picked.path);
      }
    });
  }

  Future<void> _openCamera(bool isKtp) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() {
      if (isKtp) {
        _ktpPhotoFile = File(picked.path);
      } else {
        _selfieKtpFile = File(picked.path);
      }
    });
  }

  void _showImageSourceSheet(bool isKtp) {
    final colors = context.colors;
    final label = isKtp ? 'Foto KTP' : 'Foto Selfie + KTP';
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pilih $label',
              style: GoogleFonts.poppins(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            _sourceOption(colors, Icons.camera_alt_rounded, 'Kamera',
                () { Navigator.pop(context); _openCamera(isKtp); }),
            const SizedBox(height: 12),
            _sourceOption(colors, Icons.photo_library_rounded, 'Galeri Foto',
                () { Navigator.pop(context); _pickImage(isKtp); }),
          ],
        ),
      ),
    );
  }

  Widget _sourceOption(AppColors colors, IconData icon, String label,
      VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: _accent, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.poppins(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                )),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: colors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ktpPhotoFile == null) {
      _showSnack('Silakan unggah foto KTP Anda', isError: true);
      return;
    }
    if (_selfieKtpFile == null) {
      _showSnack('Silakan unggah foto selfie dengan KTP Anda', isError: true);
      return;
    }
    if (!_termsAccepted) {
      _showSnack('Anda harus menyetujui syarat & ketentuan', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();

      _showSnack('Mengunggah foto KTP...', isError: false);
      final ktpUrl = await authProvider.uploadImage(_ktpPhotoFile!);
      if (ktpUrl == null) {
        _showSnack('Gagal mengunggah foto KTP. Coba lagi.', isError: true);
        return;
      }

      _showSnack('Mengunggah foto selfie...', isError: false);
      final selfieUrl = await authProvider.uploadImage(_selfieKtpFile!);
      if (selfieUrl == null) {
        _showSnack('Gagal mengunggah foto selfie. Coba lagi.', isError: true);
        return;
      }

      final success = await authProvider.verifyIdentity({
        'name': _nameCtrl.text.trim(),
        'nik': _nikCtrl.text.trim(),
        'birth_place': _birthPlaceCtrl.text.trim(),
        'ktp_photo_url': ktpUrl,
        'selfie_ktp_url': selfieUrl,
      });

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        _showSnack(
          authProvider.errorMessage ?? 'Gagal mengirim data verifikasi',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: isError ? const Color(0xFFE53E3E) : _accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    final colors = context.colors;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accent, _accentDark],
                ),
                borderRadius: BorderRadius.circular(99),
              ),
              child:
                  const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Data Terkirim!',
                style: GoogleFonts.poppins(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                )),
            const SizedBox(height: 10),
            Text(
              'Data verifikasi identitas Anda sedang dalam proses review. Biasanya selesai dalam 1×24 jam.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Kembali ke Profil',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = context.watch<AuthProvider>().user;
    final status = user?.verificationStatus ?? 'unverified';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verifikasi Identitas',
          style: GoogleFonts.poppins(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: colors.border),
        ),
      ),
      body: status == 'verified'
          ? _buildVerifiedState(colors)
          : status == 'pending'
              ? _buildPendingState(colors)
              : _buildForm(colors, status, isDark),
    );
  }

  Widget _buildVerifiedState(AppColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: [_accent, _accentDark]),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withAlpha(80),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.verified_rounded,
                  color: Colors.white, size: 56),
            ),
            const SizedBox(height: 24),
            Text('Identitas Terverifikasi',
                style: GoogleFonts.poppins(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                )),
            const SizedBox(height: 12),
            Text(
              'Selamat! Identitas Anda telah berhasil diverifikasi. Anda kini memiliki akses penuh ke semua fitur Petualang.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingState(AppColors colors) {
    const amber = Color(0xFFFFC107);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [amber, Color(0xFFFF9800)]),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: amber.withAlpha(80),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: Colors.white, size: 52),
            ),
            const SizedBox(height: 24),
            Text('Sedang Diproses',
                style: GoogleFonts.poppins(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                )),
            const SizedBox(height: 12),
            Text(
              'Data verifikasi Anda sedang dalam proses review oleh tim kami. Biasanya selesai dalam 1×24 jam.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AppColors colors, String status, bool isDark) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (status == 'rejected') _buildRejectedBanner(colors),
          _buildStatusHeader(colors),
          const SizedBox(height: 24),

          _sectionLabel(colors, 'Data Diri', Icons.person_outline_rounded),
          const SizedBox(height: 12),
          _buildInputField(
            colors: colors,
            controller: _nameCtrl,
            label: 'Nama Lengkap (sesuai KTP)',
            icon: Icons.badge_outlined,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
              if (v.trim().length < 3) return 'Nama terlalu pendek';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildInputField(
            colors: colors,
            controller: _nikCtrl,
            label: 'Nomor KTP (NIK)',
            icon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'NIK wajib diisi';
              if (v.trim().length != 16) return 'NIK harus 16 digit';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildInputField(
            colors: colors,
            controller: _birthPlaceCtrl,
            label: 'Tempat Lahir',
            icon: Icons.location_city_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return 'Tempat lahir wajib diisi';
              return null;
            },
          ),
          const SizedBox(height: 28),

          _sectionLabel(
              colors, 'Dokumen Identitas', Icons.folder_open_rounded),
          const SizedBox(height: 12),
          _buildUploadCard(
            colors: colors,
            label: 'Foto KTP',
            description: 'Pastikan seluruh bagian KTP terlihat jelas',
            icon: Icons.credit_card_rounded,
            file: _ktpPhotoFile,
            onTap: () => _showImageSourceSheet(true),
          ),
          const SizedBox(height: 14),
          _buildUploadCard(
            colors: colors,
            label: 'Foto Selfie dengan KTP',
            description: 'Pegang KTP di samping wajah Anda',
            icon: Icons.camera_front_rounded,
            file: _selfieKtpFile,
            onTap: () => _showImageSourceSheet(false),
          ),
          const SizedBox(height: 28),

          _sectionLabel(colors, 'Persetujuan', Icons.handshake_outlined),
          const SizedBox(height: 12),
          _buildTermsCard(colors),
          const SizedBox(height: 32),

          _buildSubmitButton(colors),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner(AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.error.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.error.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Verifikasi sebelumnya ditolak. Pastikan dokumen Anda valid dan coba kirim ulang.',
              style: GoogleFonts.poppins(
                color: colors.error,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _accent.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: _accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lengkapi data di bawah untuk memverifikasi identitas Anda. Data akan diproses secara aman.',
              style: GoogleFonts.poppins(
                color: colors.textSecondary,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(AppColors colors, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 18),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.poppins(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            )),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: colors.border, thickness: 1)),
      ],
    );
  }

  Widget _buildInputField({
    required AppColors colors,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.poppins(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.poppins(color: colors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        filled: true,
        fillColor: colors.input,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        errorStyle: GoogleFonts.poppins(fontSize: 11, color: colors.error),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildUploadCard({
    required AppColors colors,
    required String label,
    required String description,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
  }) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: hasFile ? _accent.withAlpha(20) : colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile ? _accent.withAlpha(120) : colors.border,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: hasFile
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(file,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(170),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 14,
                    right: 14,
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: _accent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(label,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Ganti',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24, horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colors.input,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Icon(icon, color: _accent, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: GoogleFonts.poppins(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              )),
                          const SizedBox(height: 4),
                          Text(description,
                              style: GoogleFonts.poppins(
                                color: colors.textSecondary,
                                fontSize: 12,
                              )),
                        ],
                      ),
                    ),
                    Icon(Icons.add_photo_alternate_rounded,
                        color: _accent, size: 28),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTermsCard(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _termsAccepted ? _accent.withAlpha(100) : colors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: _termsAccepted,
                  onChanged: (v) =>
                      setState(() => _termsAccepted = v ?? false),
                  activeColor: _accent,
                  checkColor: Colors.white,
                  side: BorderSide(color: colors.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text.rich(
                    TextSpan(
                      style: GoogleFonts.poppins(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'Saya menyetujui '),
                        TextSpan(
                          text: 'Syarat & Ketentuan',
                          style: TextStyle(
                            color: _accent,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: _accent,
                          ),
                        ),
                        const TextSpan(
                            text:
                                ' dan memberikan persetujuan untuk memproses data pribadi saya.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TermsAndConditionsScreen(
                      onAccept: () =>
                          setState(() => _termsAccepted = true),
                    ),
                  ),
                );
              },
              icon: Icon(Icons.open_in_new_rounded,
                  size: 16, color: _indigo),
              label: Text(
                'Baca Syarat & Ketentuan Lengkap',
                style: GoogleFonts.poppins(
                  color: _indigo,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _indigo.withAlpha(20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppColors colors) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _isSubmitting
              ? null
              : const LinearGradient(colors: [_accent, _accentDark]),
          color: _isSubmitting ? null : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isSubmitting ? colors.border : Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            padding: EdgeInsets.zero,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Kirim Data Verifikasi',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        )),
                  ],
                ),
        ),
      ),
    );
  }
}
