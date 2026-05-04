import 'dart:io' as dart_io;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/mitra_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adaptive_image.dart';

class MitraShopProfileScreen extends StatefulWidget {
  const MitraShopProfileScreen({super.key});

  @override
  State<MitraShopProfileScreen> createState() => _MitraShopProfileScreenState();
}

class _MitraShopProfileScreenState extends State<MitraShopProfileScreen> {
  bool _editing = false;
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _imageUrl;
  bool _isOpen = true;

  bool _initialized = false;

  /// File yang baru di-pick lokal (preview optimis sebelum upload selesai).
  dart_io.File? _pickedImageFile;
  bool _uploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _address = TextEditingController();
    _phone = TextEditingController();
    _imageUrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MitraProvider>().fetchVendor();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _populateFromVendor(Map<String, dynamic> v) {
    _name.text = v['name']?.toString() ?? '';
    _address.text = v['address']?.toString() ?? '';
    _phone.text = v['contact_phone']?.toString() ?? '';
    _imageUrl.text = v['image_url']?.toString() ?? '';
    _isOpen = v['is_open'] as bool? ?? true;
    _pickedImageFile = null;
  }

  /// Pick foto toko dari galeri lalu upload ke server. Pada sukses URL
  /// hasil di-isi ke `_imageUrl` (akan di-save bersama field lain).
  Future<void> _pickShopImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;

    final file = dart_io.File(picked.path);
    setState(() {
      _pickedImageFile = file;
      _uploadingImage = true;
    });

    final url = await context.read<AuthProvider>().uploadImage(file);

    if (!mounted) return;
    setState(() {
      _uploadingImage = false;
      if (url != null) {
        _imageUrl.text = url;
      } else {
        _pickedImageFile = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunggah gambar')),
        );
      }
    });
  }

  void _clearShopImage() {
    setState(() {
      _imageUrl.clear();
      _pickedImageFile = null;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<MitraProvider>().updateVendor({
      'name': _name.text.trim(),
      'address': _address.text.trim(),
      'contact_phone': _phone.text.trim(),
      'image_url': _imageUrl.text.trim(),
      'is_open': _isOpen,
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });
    messenger.showSnackBar(SnackBar(content: Text(ok ? 'Toko diperbarui' : 'Gagal')));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Anda akan keluar dari panel mitra.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<MitraProvider>();
    final vendor = provider.vendor;

    if (vendor != null && !_initialized) {
      _populateFromVendor(vendor);
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Profil Toko', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800)),
        backgroundColor: colors.surface,
        elevation: 0,
        actions: [
          if (vendor != null)
            IconButton(
              onPressed: () {
                if (_editing) {
                  // batal
                  _populateFromVendor(vendor);
                }
                setState(() => _editing = !_editing);
              },
              icon: Icon(_editing ? Icons.close_rounded : Icons.edit_rounded),
            ),
        ],
      ),
      body: provider.loading && vendor == null
          ? const Center(child: CircularProgressIndicator())
          : vendor == null
              ? Center(
                  child: Text(
                    'Toko belum terhubung dengan akun Anda.\nHubungi admin.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(color: colors.textMuted),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _shopImageHeader(),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _field(_name, 'Nama Toko', enabled: _editing),
                          _field(_address, 'Alamat', enabled: _editing, maxLines: 2),
                          _field(_phone, 'No. Telepon', enabled: _editing, keyboard: TextInputType.phone),
                          SwitchListTile(
                            value: _isOpen,
                            onChanged: _editing
                                ? (v) => setState(() => _isOpen = v)
                                : null,
                            title: const Text('Toko Buka'),
                            subtitle: Text(
                              _isOpen ? 'Pelanggan dapat memesan' : 'Pelanggan tidak dapat memesan',
                              style: GoogleFonts.beVietnamPro(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${vendor['rating'] ?? 0} (${vendor['review_count'] ?? 0} ulasan)',
                                style: GoogleFonts.beVietnamPro(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (_editing) ...[
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Simpan Perubahan'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Material(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: _logout,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, color: Colors.red),
                              const SizedBox(width: 12),
                              Text(
                                'Logout',
                                style: GoogleFonts.beVietnamPro(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Header banner foto toko 16:9. Saat editing aktif:
  /// - kosong → tombol besar "Pilih Foto Toko"
  /// - ada gambar → preview + tombol bulat hapus & ganti di pojok bawah
  Widget _shopImageHeader() {
    final colors = context.colors;
    final hasLocal = _pickedImageFile != null;
    final hasUrl = _imageUrl.text.trim().isNotEmpty;
    final hasImage = hasLocal || hasUrl;

    Widget content;
    if (!hasImage) {
      // Empty state.
      content = InkWell(
        onTap: _editing && !_uploadingImage ? _pickShopImage : null,
        child: Container(
          color: colors.input,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_rounded,
                  color: _editing ? colors.primaryOrange : colors.textMuted,
                  size: 36),
              const SizedBox(height: 8),
              Text(
                _editing ? 'Pilih foto toko' : 'Belum ada foto toko',
                style: GoogleFonts.beVietnamPro(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          if (hasLocal)
            Image.file(_pickedImageFile!, fit: BoxFit.cover)
          else
            AdaptiveImage(
              url: _imageUrl.text.trim(),
              fit: BoxFit.cover,
              fallbackBuilder: (_) => Container(
                color: colors.input,
                alignment: Alignment.center,
                child: Icon(Icons.broken_image_rounded,
                    color: colors.textMuted, size: 40),
              ),
            ),
          if (_uploadingImage)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Colors.white),
            ),
          // Tombol overlay hanya ditampilkan saat editing aktif.
          if (_editing)
            Positioned(
              bottom: 8,
              right: 8,
              child: Row(
                children: [
                  _imgActionBtn(
                    icon: Icons.delete_rounded,
                    color: Colors.red,
                    tooltip: 'Hapus',
                    onTap: _uploadingImage ? null : _clearShopImage,
                  ),
                  const SizedBox(width: 8),
                  _imgActionBtn(
                    icon: Icons.edit_rounded,
                    color: colors.primaryOrange,
                    tooltip: 'Ganti',
                    onTap: _uploadingImage ? null : _pickShopImage,
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(aspectRatio: 16 / 9, child: content),
    );
  }

  Widget _imgActionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: onTap == null ? Colors.grey : color, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        enabled: enabled,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
