import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/community_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/community_provider.dart';
import '../../services/dm_api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/permission_helper.dart';
import '../../widgets/community/category_chip.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController(text: 'Indonesia');
  final _descCtrl = TextEditingController();

  int _step = 0;
  File? _coverFile;
  File? _iconFile;
  String? _coverUrl;
  String? _iconUrl;

  String? _category;
  String _privacy = 'public';

  bool _uploading = false;
  bool _submitting = false;

  static const _categoriesAvailable = <String>[
    'Hiking & Trekking',
    'Camping & Outdoor',
    'Running',
    'Fotografi',
    'Climbing',
    'Lainnya',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool cover}) async {
    final granted = await PermissionHelper.checkPhotosPermission(context);
    if (!granted) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: cover ? 1600 : 600,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (cover) {
        _coverFile = File(picked.path);
      } else {
        _iconFile = File(picked.path);
      }
    });
  }

  Future<void> _next() async {
    if (!(_formKey1.currentState?.validate() ?? false)) return;
    setState(() => _step = 1);
  }

  Future<void> _submit() async {
    if (_category == null) {
      _showSnack('Pilih kategori terlebih dahulu');
      return;
    }
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) {
      _showSnack('Anda harus login');
      return;
    }

    setState(() => _submitting = true);
    try {
      // 1. Upload images jika ada
      setState(() => _uploading = true);
      final uploader = DmApiService();
      if (_coverFile != null) {
        _coverUrl = await uploader.uploadImage(_coverFile!, token);
      }
      if (_iconFile != null) {
        _iconUrl = await uploader.uploadImage(_iconFile!, token);
      }
      setState(() => _uploading = false);

      // 2. Create community
      final provider = context.read<CommunityProvider>();
      final created = await provider.createCommunity(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        category: _category,
        privacy: _privacy,
        coverImageUrl: _coverUrl,
        iconImageUrl: _iconUrl,
      );

      if (!mounted) return;
      if (created == null) {
        _showSnack('Gagal membuat komunitas, coba lagi');
        return;
      }
      // Refresh list & pop dengan model yang baru dibuat
      await provider.fetchCommunities();
      if (!mounted) return;
      Navigator.pop<CommunityModel?>(context, created);
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploading = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: colors.primaryOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.add_business_rounded, color: colors.primaryOrange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Buat Komunitas',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'Langkah ${_step + 1} dari 2',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _step == 0 ? 0.5 : 1,
            backgroundColor: colors.border,
            valueColor: AlwaysStoppedAnimation(colors.primaryOrange),
            minHeight: 4,
          ),
        ),
      ),
      body: IndexedStack(
        index: _step,
        children: [
          _Step1(
            formKey: _formKey1,
            nameCtrl: _nameCtrl,
            locationCtrl: _locationCtrl,
            descCtrl: _descCtrl,
            coverFile: _coverFile,
            iconFile: _iconFile,
            onPickCover: () => _pickImage(cover: true),
            onPickIcon: () => _pickImage(cover: false),
          ),
          _Step2(
            categories: _categoriesAvailable,
            selectedCategory: _category,
            onCategoryChanged: (c) => setState(() => _category = c),
            privacy: _privacy,
            onPrivacyChanged: (v) => setState(() => _privacy = v),
            previewName: _nameCtrl.text,
            previewLocation: _locationCtrl.text,
            previewDesc: _descCtrl.text,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (_step == 1)
                OutlinedButton(
                  onPressed: _submitting ? null : () => setState(() => _step = 0),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
              if (_step == 1) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : (_step == 0 ? _next : _submit),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _uploading ? 'Mengunggah gambar...' : 'Membuat...',
                              style: GoogleFonts.beVietnamPro(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          _step == 0 ? 'Lanjutkan →' : '🎉  Buat Komunitas',
                          style: GoogleFonts.beVietnamPro(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Step 1: Identitas ───────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController descCtrl;
  final File? coverFile;
  final File? iconFile;
  final VoidCallback onPickCover;
  final VoidCallback onPickIcon;

  const _Step1({
    required this.formKey,
    required this.nameCtrl,
    required this.locationCtrl,
    required this.descCtrl,
    required this.coverFile,
    required this.iconFile,
    required this.onPickCover,
    required this.onPickIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cover + icon picker
          SizedBox(
            height: 200,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: onPickCover,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E4C2E),
                      borderRadius: BorderRadius.circular(16),
                      image: coverFile != null
                          ? DecorationImage(
                              image: FileImage(coverFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            coverFile != null ? 'Ganti Cover' : 'Upload Cover',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 16,
                  child: GestureDetector(
                    onTap: onPickIcon,
                    child: Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: colors.primaryOrange,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.background, width: 4),
                        image: iconFile != null
                            ? DecorationImage(
                                image: FileImage(iconFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: iconFile == null
                          ? const Icon(Icons.image_rounded, color: Colors.white, size: 26)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Label('Nama Komunitas'),
          const SizedBox(height: 8),
          TextFormField(
            controller: nameCtrl,
            decoration: _inputDeco(context, hint: 'mis. Pendaki Jogja'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 16),
          _Label('Lokasi'),
          const SizedBox(height: 8),
          TextFormField(
            controller: locationCtrl,
            decoration: _inputDeco(context, hint: 'Indonesia'),
          ),
          const SizedBox(height: 16),
          _Label('Deskripsi'),
          const SizedBox(height: 8),
          TextFormField(
            controller: descCtrl,
            maxLines: 4,
            decoration: _inputDeco(context, hint: 'Ceritakan komunitasmu...'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(BuildContext context, {required String hint}) {
    final colors = context.colors;
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primaryOrange, width: 1.5),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.beVietnamPro(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: context.colors.textPrimary,
      ),
    );
  }
}

// ─── Step 2: Kategori, Privasi, Preview ──────────────────────

class _Step2 extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final String privacy;
  final ValueChanged<String> onPrivacyChanged;
  final String previewName;
  final String previewLocation;
  final String previewDesc;

  const _Step2({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.privacy,
    required this.onPrivacyChanged,
    required this.previewName,
    required this.previewLocation,
    required this.previewDesc,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.category_rounded, size: 18, color: colors.textPrimary),
            const SizedBox(width: 6),
            _Label('Kategori'),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories
              .map((c) => CategoryChip(
                    label: c,
                    selected: selectedCategory == c,
                    onTap: () => onCategoryChanged(c),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 18, color: colors.textPrimary),
            const SizedBox(width: 6),
            _Label('Privasi'),
          ],
        ),
        const SizedBox(height: 12),
        _PrivacyOption(
          value: 'public',
          groupValue: privacy,
          onChanged: onPrivacyChanged,
          icon: Icons.public_rounded,
          iconBg: Colors.blue.withOpacity(0.12),
          iconColor: Colors.blue.shade700,
          title: 'Publik',
          subtitle: 'Siapa saja bisa bergabung',
        ),
        const SizedBox(height: 8),
        _PrivacyOption(
          value: 'semi',
          groupValue: privacy,
          onChanged: onPrivacyChanged,
          icon: Icons.link_rounded,
          iconBg: Colors.purple.withOpacity(0.12),
          iconColor: Colors.purple.shade700,
          title: 'Semi-privat',
          subtitle: 'Butuh persetujuan admin',
        ),
        const SizedBox(height: 8),
        _PrivacyOption(
          value: 'private',
          groupValue: privacy,
          onChanged: onPrivacyChanged,
          icon: Icons.lock_rounded,
          iconBg: Colors.amber.withOpacity(0.12),
          iconColor: Colors.amber.shade800,
          title: 'Privat',
          subtitle: 'Hanya undangan',
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F5E5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Preview Komunitasmu',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                previewName.isEmpty ? '(Nama komunitas)' : previewName,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${selectedCategory ?? 'Kategori'} · ${previewLocation.isEmpty ? 'Lokasi' : previewLocation}',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              if (previewDesc.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  previewDesc,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: const Color(0xFF1B5E20),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PrivacyOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _PrivacyOption({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primaryOrange : colors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? colors.primaryOrange : colors.border,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: colors.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
