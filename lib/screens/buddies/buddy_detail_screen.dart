import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/buddy_post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/buddies_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_image.dart';
import '../../widgets/level_avatar.dart';

class BuddyDetailScreen extends StatefulWidget {
  const BuddyDetailScreen({super.key, required this.buddyId});
  final int buddyId;

  @override
  State<BuddyDetailScreen> createState() => _BuddyDetailScreenState();
}

class _BuddyDetailScreenState extends State<BuddyDetailScreen> {
  final _messageController = TextEditingController();
  BuddyPostModel? _buddy;
  bool _loading = true;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final result =
        await context.read<BuddiesProvider>().fetchBuddyDetail(widget.buddyId);
    if (!mounted) return;
    setState(() {
      _buddy = result;
      _loading = false;
    });
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    final error = await context
        .read<BuddiesProvider>()
        .applyToBuddy(widget.buddyId, _messageController.text.trim());
    if (!mounted) return;
    setState(() => _applying = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan berhasil dikirim')),
      );
      _messageController.clear();
      _load();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final auth = context.watch<AuthProvider>();
    final dateFmt = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_buddy == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Ajakan tidak ditemukan')),
      );
    }

    final isOwner = auth.user?.id == _buddy!.userId;
    final canApply = !isOwner && _buddy!.spotsLeft > 0 && _buddy!.status == 'open';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Detail Ajakan',
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Mountain banner
                  if (_buddy!.mountainImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: AppImage(
                          url: _buddy!.mountainImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: colors.primaryOrange.withOpacity(0.2)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Text(
                    _buddy!.title,
                    style: GoogleFonts.beVietnamPro(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      LevelAvatar(
                        level: _buddy!.userLevel ?? 1,
                        radius: 18,
                        avatarUrl: _buddy!.userPicture,
                        name: _buddy!.userName ?? '?',
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _buddy!.userName ?? 'Anonim',
                          style: GoogleFonts.beVietnamPro(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _InfoTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Tanggal',
                    value: dateFmt.format(_buddy!.targetDate),
                  ),
                  if (_buddy!.mountainName != null)
                    _InfoTile(
                      icon: Icons.terrain_rounded,
                      label: 'Gunung',
                      value: _buddy!.mountainName!,
                    ),
                  _InfoTile(
                    icon: Icons.people_alt_rounded,
                    label: 'Slot',
                    value: '${_buddy!.currentBuddies}/${_buddy!.maxBuddies} terisi',
                  ),

                  if (_buddy!.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Deskripsi',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _buddy!.description!,
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // Disclaimer
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primaryOrange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: colors.primaryOrange.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: colors.primaryOrange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Verifikasi identitas pendaki sebelum bertemu di lokasi.',
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textSecondary,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Applications list
                  if (_buddy!.applications.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Permintaan Bergabung (${_buddy!.applications.length})',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buddy!.applications.map((app) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: LevelAvatar(
                              level: app.applicantLevel ?? 1,
                              radius: 16,
                              avatarUrl: app.applicantPicture,
                              name: app.applicantName ?? '?',
                            ),
                            title: Text(app.applicantName ?? 'Anonim',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: app.message != null
                                ? Text(app.message!, style: const TextStyle(fontSize: 12))
                                : null,
                          ),
                        )),
                  ],
                ],
              ),
            ),

            // Apply form
            if (canApply)
              Container(
                padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Tulis pesan singkat...',
                          hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: colors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.border),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applying ? null : _apply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _applying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Apply'),
                    ),
                  ],
                ),
              )
            else if (isOwner)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Text(
                  'Ini ajakan kamu',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: colors.primaryOrange, size: 18),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: GoogleFonts.beVietnamPro(
              color: colors.textMuted,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.beVietnamPro(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
