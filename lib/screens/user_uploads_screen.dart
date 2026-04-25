import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserUploadsScreen extends StatefulWidget {
  const UserUploadsScreen({super.key});

  @override
  State<UserUploadsScreen> createState() => _UserUploadsScreenState();
}

class _UserUploadsScreenState extends State<UserUploadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Unggahan Konten Saya',
          style: GoogleFonts.beVietnamPro(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primaryOrange,
          labelColor: colors.primaryOrange,
          unselectedLabelColor: colors.textMuted,
          labelStyle: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Komunitas'),
            Tab(text: 'Jelajah'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKomunitasTab(colors),
          _buildJelajahTab(colors),
        ],
      ),
    );
  }

  Widget _buildKomunitasTab(AppColors colors) {
    // Sebagai kerangka awal, kita tampilkan empty state karena belum ada
    // endpoint khusus untuk "fetch posts by user_id".
    // Nantinya Anda bisa mengintegrasikan API di sini.
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_rounded, size: 64, color: colors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Postingan',
            style: GoogleFonts.beVietnamPro(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda belum mengunggah postingan apa pun\ndi Komunitas.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJelajahTab(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_rounded, size: 64, color: colors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Artikel',
            style: GoogleFonts.beVietnamPro(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda belum mengunggah artikel\natau tips petualang.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
