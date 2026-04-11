import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/permission_helper.dart';

class CreatePostScreen extends StatefulWidget {
  final int communityId;
  final String? communityName;

  const CreatePostScreen({
    super.key,
    required this.communityId,
    this.communityName,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      // Professional Permission Check
      final granted = await PermissionHelper.checkPhotosPermission(context);
      if (!granted) return;

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null && mounted) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal membuka galeri. Pastikan ijin akses foto telah diberikan.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);

    final provider = context.read<CommunityProvider>();
    final success = await provider.createPost(
      communityId: widget.communityId,
      content: content,
      imageFile: _selectedImage,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Postingan berhasil dibuat!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal membuat postingan. Coba lagi.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasContent = _contentController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Buat Postingan',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: hasContent && !_isSubmitting ? _submit : null,
              style: TextButton.styleFrom(
                backgroundColor: hasContent ? colors.primaryOrange : colors.border,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text('Posting', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Community name label
            if (widget.communityName != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '📌 ${widget.communityName}',
                    style: TextStyle(color: colors.primaryOrange, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

            // Text input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                onChanged: (_) => setState(() {}),
                maxLines: null,
                minLines: 5,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Apa yang sedang terjadi? Bagikan pengalamanmu...',
                  hintStyle: TextStyle(color: colors.textSecondary, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(color: colors.textPrimary, fontSize: 16, height: 1.6),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            // Image preview
            if (_selectedImage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),

            // Bottom action bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.photo_library_rounded, color: colors.primaryOrange),
                    label: Text(
                      'Foto dari Galeri',
                      style: TextStyle(color: colors.primaryOrange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
