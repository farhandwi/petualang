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
import '../../widgets/common/app_image.dart';
import '../../widgets/community/category_chip.dart';

class EditCommunityScreen extends StatefulWidget {
  final CommunityModel community;
  const EditCommunityScreen({super.key, required this.community});

  @override
  State<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends State<EditCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _descCtrl;

  late String? _category;
  File? _newCover;
  File? _newIcon;
  bool _saving = false;

  static const _categories = <String>[
    'Hiking & Trekking',
    'Camping & Outdoor',
    'Running',
    'Fotografi',
    'Climbing',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.community;
    _nameCtrl = TextEditingController(text: c.name);
    _locationCtrl = TextEditingController(text: c.location ?? '');
    _descCtrl = TextEditingController(text: c.description ?? '');
    _category = c.category;
  }

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
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: cover ? 1600 : 600,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (cover) {
        _newCover = File(picked.path);
      } else {
        _newIcon = File(picked.path);
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    setState(() => _saving = true);
    try {
      String? coverUrl;
      String? iconUrl;
      final uploader = DmApiService();
      if (_newCover != null) {
        coverUrl = await uploader.uploadImage(_newCover!, token);
      }
      if (_newIcon != null) {
        iconUrl = await uploader.uploadImage(_newIcon!, token);
      }

      final updated = await context.read<CommunityProvider>().updateCommunity(
            id: widget.community.id,
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            location: _locationCtrl.text.trim(),
            category: _category,
            coverImageUrl: coverUrl,
            iconImageUrl: iconUrl,
          );

      if (!mounted) return;
      if (updated != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komunitas berhasil diupdate')),
        );
        Navigator.pop<CommunityModel?>(context, updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengubah komunitas')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          'Edit Komunitas',
          style: GoogleFonts.beVietnamPro(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
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
                    onTap: () => _pickImage(cover: true),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E4C2E),
                        borderRadius: BorderRadius.circular(16),
                        image: _newCover != null
                            ? DecorationImage(
                                image: FileImage(_newCover!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_newCover == null)
                            AppImage(
                              url: widget.community.coverImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF2E4C2E),
                              ),
                            ),
                          Container(color: Colors.black.withOpacity(0.35)),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.image_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _newCover != null
                                        ? 'Ganti Cover Baru'
                                        : 'Ubah Cover',
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
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => _pickImage(cover: false),
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: colors.primaryOrange,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.background, width: 4),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _newIcon != null
                            ? Image.file(_newIcon!, fit: BoxFit.cover)
                            : (widget.community.iconImageUrl != null &&
                                    widget.community.iconImageUrl!.isNotEmpty)
                                ? AppImage(
                                    url: widget.community.iconImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  )
                                : const Icon(Icons.image_rounded,
                                    color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _label('Nama Komunitas'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: _inputDeco(context, hint: 'Nama komunitas'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),
            _label('Lokasi'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _locationCtrl,
              decoration: _inputDeco(context, hint: 'Indonesia'),
            ),
            const SizedBox(height: 16),
            _label('Deskripsi'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: _inputDeco(context, hint: 'Ceritakan komunitasmu...'),
            ),
            const SizedBox(height: 20),
            _label('Kategori'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories
                  .map((c) => CategoryChip(
                        label: c,
                        selected: _category == c,
                        onTap: () => setState(() => _category = c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
            child: Material(
              color: _saving
                  ? colors.primaryOrange.withOpacity(0.5)
                  : colors.primaryOrange,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _saving ? null : _save,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_saving)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      else
                        Text(
                          'Simpan Perubahan',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.beVietnamPro(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: context.colors.textPrimary,
        ),
      );

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
