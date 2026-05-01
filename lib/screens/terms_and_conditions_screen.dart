import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  /// Jika [onAccept] disediakan, tampilkan tombol "Setuju" di bagian bawah
  final VoidCallback? onAccept;

  const TermsAndConditionsScreen({super.key, this.onAccept});

  @override
  State<TermsAndConditionsScreen> createState() =>
      _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState
    extends State<TermsAndConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  static const Color _accent = Color(0xFF00B894);

  @override
  void initState() {
    super.initState();
    if (widget.onAccept != null) {
      _scrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (!_hasScrolledToBottom &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 80) {
      setState(() => _hasScrolledToBottom = true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isModal = widget.onAccept != null;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back_ios_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Syarat & Ketentuan',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(colors),
                  const SizedBox(height: 24),
                  _buildSection(colors,
                    icon: Icons.info_outline_rounded,
                    title: '1. Ketentuan Umum',
                    content:
                        'Dengan menggunakan layanan Petualang, Anda menyetujui syarat dan ketentuan ini. Layanan Petualang adalah platform digital yang menghubungkan para pencinta aktivitas outdoor, pendakian, dan petualangan alam bebas.\n\n'
                        'Anda harus berusia minimal 17 tahun untuk menggunakan layanan ini. Penggunaan akun Anda sepenuhnya menjadi tanggung jawab Anda.',
                  ),
                  _buildSection(colors,
                    icon: Icons.verified_user_outlined,
                    title: '2. Verifikasi Identitas',
                    content:
                        'Verifikasi identitas (KYC) diperlukan untuk mengakses fitur-fitur tertentu pada platform Petualang, termasuk peminjaman alat outdoor, bergabung dalam ekspedisi, dan transaksi keuangan.\n\n'
                        'Data yang Anda berikan — termasuk foto KTP dan foto selfie — akan diproses secara aman dan hanya digunakan untuk keperluan verifikasi identitas. Data tidak akan disebarkan kepada pihak ketiga tanpa izin tertulis Anda.\n\n'
                        'Tim Petualang berhak menolak atau menangguhkan verifikasi jika dokumen tidak valid, tidak terbaca, atau mencurigai adanya pemalsuan data.',
                  ),
                  _buildSection(colors,
                    icon: Icons.lock_outline_rounded,
                    title: '3. Keamanan & Privasi Data',
                    content:
                        'Kami berkomitmen menjaga keamanan dan kerahasiaan data pribadi Anda sesuai dengan Undang-Undang Perlindungan Data Pribadi (UU PDP) Republik Indonesia.\n\n'
                        'Data pribadi Anda disimpan menggunakan enkripsi tingkat enterprise. Kami tidak pernah menjual atau menyewakan data pribadi Anda kepada pihak ketiga untuk kepentingan komersial.\n\n'
                        'Anda memiliki hak untuk mengakses, memperbarui, atau menghapus data pribadi Anda kapan saja melalui pengaturan akun.',
                  ),
                  _buildSection(colors,
                    icon: Icons.photo_camera_outlined,
                    title: '4. Dokumen yang Diperlukan',
                    content:
                        'Untuk keperluan verifikasi identitas, Anda diminta untuk mengunggah:\n\n'
                        '• Foto KTP (Kartu Tanda Penduduk) yang masih berlaku\n'
                        '• Foto selfie sambil memegang KTP\n\n'
                        'Pastikan foto yang diunggah:\n'
                        '• Jelas dan tidak buram\n'
                        '• Seluruh bagian dokumen terlihat\n'
                        '• Tidak diedit atau dimanipulasi\n'
                        '• Diambil dalam kondisi cahaya yang cukup',
                  ),
                  _buildSection(colors,
                    icon: Icons.gavel_rounded,
                    title: '5. Hak & Kewajiban Pengguna',
                    content:
                        'Sebagai pengguna Petualang, Anda berhak:\n'
                        '• Mendapatkan layanan sesuai yang dijanjikan\n'
                        '• Melaporkan keluhan dan mendapat respons dalam 3×24 jam\n'
                        '• Membatalkan verifikasi sebelum data diproses\n\n'
                        'Anda berkewajiban untuk:\n'
                        '• Memberikan data yang benar dan akurat\n'
                        '• Menjaga keamanan akun Anda\n'
                        '• Tidak menyalahgunakan platform untuk kepentingan ilegal',
                  ),
                  _buildSection(colors,
                    icon: Icons.warning_amber_rounded,
                    title: '6. Tanggung Jawab & Risiko',
                    content:
                        'Petualang tidak bertanggung jawab atas kerugian yang timbul akibat aktivitas outdoor yang Anda lakukan. Setiap aktivitas petualangan memiliki risiko tersendiri dan menjadi tanggung jawab penuh Anda.\n\n'
                        'Platform Petualang hanya berfungsi sebagai media penghubung dan penyedia informasi. Pastikan Anda selalu mengikuti prosedur keselamatan yang berlaku.',
                  ),
                  _buildSection(colors,
                    icon: Icons.update_rounded,
                    title: '7. Perubahan Ketentuan',
                    content:
                        'Petualang berhak mengubah syarat dan ketentuan ini sewaktu-waktu. Perubahan akan diinformasikan melalui notifikasi aplikasi atau email terdaftar setidaknya 7 hari sebelum berlaku.\n\n'
                        'Penggunaan layanan setelah pemberitahuan perubahan dianggap sebagai persetujuan terhadap ketentuan yang baru.',
                  ),
                  _buildSection(colors,
                    icon: Icons.support_agent_rounded,
                    title: '8. Hubungi Kami',
                    content:
                        'Jika Anda memiliki pertanyaan atau keberatan mengenai syarat dan ketentuan ini, silakan hubungi:\n\n'
                        '📧 legal@petualang.id\n'
                        '📞 +62 21 xxxx-xxxx\n'
                        '🌐 www.petualang.id/help\n\n'
                        'Jam operasional: Senin–Jumat, 09.00–17.00 WIB',
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Terakhir diperbarui: 1 Januari 2025',
                      style: GoogleFonts.poppins(
                        color: colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (isModal) _buildAcceptButton(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _accent.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withAlpha(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accent, Color(0xFF6C63FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Syarat & Ketentuan Petualang',
                  style: GoogleFonts.poppins(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Baca dengan seksama sebelum melanjutkan verifikasi identitas Anda.',
                  style: GoogleFonts.poppins(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    AppColors colors, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accent.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 14),
            Text(
              content,
              style: GoogleFonts.poppins(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptButton(AppColors colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_hasScrolledToBottom)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Scroll ke bawah untuk menyetujui',
                style: GoogleFonts.poppins(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _hasScrolledToBottom
                  ? () {
                      Navigator.pop(context);
                      widget.onAccept?.call();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _hasScrolledToBottom ? _accent : colors.border,
                disabledBackgroundColor: colors.border,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                'Saya Setuju dengan Syarat & Ketentuan',
                style: GoogleFonts.poppins(
                  color: _hasScrolledToBottom
                      ? Colors.white
                      : colors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
