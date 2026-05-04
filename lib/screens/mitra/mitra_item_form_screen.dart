import 'dart:io' as dart_io;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/mitra_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adaptive_image.dart';

class MitraItemFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const MitraItemFormScreen({super.key, this.initial});

  @override
  State<MitraItemFormScreen> createState() => _MitraItemFormScreenState();
}

class _MitraItemFormScreenState extends State<MitraItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _availableStock;
  late final TextEditingController _brand;
  late final TextEditingController _condition;
  late final TextEditingController _imageUrl;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  /// Saat user pick gambar baru, simpan di sini sebelum di-upload pada save.
  /// Pada platform tanpa file system (Web) tetap pakai URL TextField.
  dart_io.File? _pickedImageFile;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  static const _categories = [
    'TENDA', 'CARRIER', 'SLEEPING BAG', 'SEPATU', 'COOKING',
    'PENERANGAN', 'PAKAIAN', 'NAVIGASI', 'MATRAS', 'Shelter',
  ];
  static const _conditions = ['Sangat Baik', 'Baik', 'Cukup', 'Perlu Perbaikan'];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?['name']?.toString() ?? '');
    _category = TextEditingController(text: i?['category']?.toString() ?? 'TENDA');
    _description = TextEditingController(text: i?['description']?.toString() ?? '');
    _price = TextEditingController(text: i?['price_per_day']?.toString() ?? '');
    _stock = TextEditingController(text: i?['stock']?.toString() ?? '0');
    _availableStock = TextEditingController(text: i?['available_stock']?.toString() ?? '0');
    _brand = TextEditingController(text: i?['brand']?.toString() ?? 'No Brand');
    _condition = TextEditingController(text: i?['condition']?.toString() ?? 'Baik');
    _imageUrl = TextEditingController(text: i?['image_url']?.toString() ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _availableStock.dispose();
    _brand.dispose();
    _condition.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  /// Pick gambar dari galeri lalu upload ke server. Jika sukses, set
  /// `_imageUrl.text` ke URL hasil upload. File lokal disimpan ke
  /// [_pickedImageFile] sementara untuk preview optimis.
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) return;

    final file = dart_io.File(picked.path);
    setState(() {
      _pickedImageFile = file;
      _uploading = true;
    });

    final auth = context.read<AuthProvider>();
    final url = await auth.uploadImage(file);

    if (!mounted) return;
    setState(() {
      _uploading = false;
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

  void _clearImage() {
    setState(() {
      _imageUrl.clear();
      _pickedImageFile = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'category': _category.text.trim(),
      'description': _description.text.trim(),
      'price_per_day': double.tryParse(_price.text.trim()) ?? 0,
      'stock': int.tryParse(_stock.text.trim()) ?? 0,
      'available_stock': int.tryParse(_availableStock.text.trim()) ?? 0,
      'brand': _brand.text.trim(),
      'condition': _condition.text.trim(),
      'image_url': _imageUrl.text.trim(),
    };

    final provider = context.read<MitraProvider>();
    final ok = _isEdit
        ? await provider.updateItem(widget.initial!['id'] as int, body)
        : await provider.createItem(body);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Tersimpan' : 'Gagal menyimpan')),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Alat' : 'Tambah Alat',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800),
        ),
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Nama Alat', required: true),
            _categoryDropdown(),
            _conditionDropdown(),
            _field(_brand, 'Merek'),
            _field(_description, 'Deskripsi', maxLines: 3),
            _field(_price, 'Harga per Hari (Rp)', required: true, keyboard: TextInputType.number),
            Row(
              children: [
                Expanded(child: _field(_stock, 'Stok Total', keyboard: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: _field(_availableStock, 'Stok Tersedia', keyboard: TextInputType.number)),
              ],
            ),
            _imagePickerField(),
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
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Alat'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null
            : null,
      ),
    );
  }

  /// Field gambar adaptif:
  /// - kosong → tombol besar "Pilih Gambar dari Galeri"
  /// - terisi → preview 16:9 + tombol Hapus & Ganti
  /// - sedang upload → overlay loader
  Widget _imagePickerField() {
    final colors = context.colors;
    final hasLocal = _pickedImageFile != null;
    final hasUrl = _imageUrl.text.trim().isNotEmpty;
    final hasImage = hasLocal || hasUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Gambar Alat',
              style: GoogleFonts.beVietnamPro(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!hasImage)
            // Empty state — tombol besar untuk pick gambar.
            InkWell(
              onTap: _uploading ? null : _pickImage,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: colors.input,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.border,
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        color: colors.primaryOrange, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih gambar dari galeri',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'JPG / PNG, maks. ~2 MB',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Preview state — tampilkan gambar + tombol aksi.
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
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
                    if (_uploading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(color: Colors.white),
                      ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Row(
                        children: [
                          _imgActionButton(
                            icon: Icons.delete_rounded,
                            color: Colors.red,
                            tooltip: 'Hapus',
                            onTap: _uploading ? null : _clearImage,
                          ),
                          const SizedBox(width: 8),
                          _imgActionButton(
                            icon: Icons.edit_rounded,
                            color: colors.primaryOrange,
                            tooltip: 'Ganti',
                            onTap: _uploading ? null : _pickImage,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _imgActionButton({
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

  Widget _categoryDropdown() {
    final value = _categories.contains(_category.text) ? _category.text : 'TENDA';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => _category.text = v ?? 'TENDA',
        decoration: const InputDecoration(
          labelText: 'Kategori',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _conditionDropdown() {
    final value = _conditions.contains(_condition.text) ? _condition.text : 'Baik';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => _condition.text = v ?? 'Baik',
        decoration: const InputDecoration(
          labelText: 'Kondisi',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
