import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';

class AdminMountainFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const AdminMountainFormScreen({super.key, this.initial});

  @override
  State<AdminMountainFormScreen> createState() => _AdminMountainFormScreenState();
}

class _AdminMountainFormScreenState extends State<AdminMountainFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _elevation;
  late final TextEditingController _difficulty;
  late final TextEditingController _price;
  late final TextEditingController _imageUrl;
  late final TextEditingController _description;
  late final TextEditingController _externalBookingUrl;
  late bool _isFeatured;
  late bool _useExternalBooking;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?['name']?.toString() ?? '');
    _location = TextEditingController(text: i?['location']?.toString() ?? '');
    _elevation = TextEditingController(text: i?['elevation']?.toString() ?? '');
    _difficulty = TextEditingController(text: i?['difficulty']?.toString() ?? 'Sedang');
    _price = TextEditingController(text: i?['price']?.toString() ?? '');
    _imageUrl = TextEditingController(text: i?['image_url']?.toString() ?? '');
    _description = TextEditingController(text: i?['description']?.toString() ?? '');
    _externalBookingUrl = TextEditingController(
      text: i?['external_booking_url']?.toString() ?? '',
    );
    _isFeatured = i?['is_featured'] == true;
    _useExternalBooking = i?['use_external_booking'] == true;
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _elevation.dispose();
    _difficulty.dispose();
    _price.dispose();
    _imageUrl.dispose();
    _description.dispose();
    _externalBookingUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final body = {
      'name': _name.text.trim(),
      'location': _location.text.trim(),
      'elevation': int.tryParse(_elevation.text.trim()),
      'difficulty': _difficulty.text.trim(),
      'price': double.tryParse(_price.text.trim()),
      'image_url': _imageUrl.text.trim(),
      'description': _description.text.trim(),
      'is_featured': _isFeatured,
      'external_booking_url': _externalBookingUrl.text.trim(),
      'use_external_booking': _useExternalBooking,
    };

    final provider = context.read<AdminProvider>();
    final ok = _isEdit
        ? await provider.updateMountain(widget.initial!['id'] as int, body)
        : await provider.createMountain(body);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Tersimpan' : 'Gagal menyimpan')),
    );
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Gunung' : 'Tambah Gunung',
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
            _field(_name, 'Nama Gunung', required: true),
            _field(_location, 'Lokasi', required: true),
            _field(_elevation, 'Ketinggian (mdpl)', required: true, keyboard: TextInputType.number),
            _difficultyDropdown(),
            _field(_price, 'Harga Tiket (Rp)', required: true, keyboard: TextInputType.number),
            _field(_imageUrl, 'URL Gambar'),
            _field(_description, 'Deskripsi', maxLines: 4),
            SwitchListTile(
              value: _isFeatured,
              onChanged: (v) => setState(() => _isFeatured = v),
              title: const Text('Featured'),
              subtitle: const Text('Tampilkan di beranda sebagai unggulan'),
            ),
            const SizedBox(height: 8),
            _externalBookingSection(),
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
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Gunung'),
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

  /// Section "Pembelian Eksternal": toggle on/off, dan URL field yang
  /// muncul saat toggle aktif. Ketika aktif, tombol "Pesan Sekarang" di
  /// halaman detail gunung akan redirect ke URL ini.
  Widget _externalBookingSection() {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: _useExternalBooking,
            onChanged: (v) => setState(() => _useExternalBooking = v),
            title: Row(
              children: [
                const Icon(Icons.open_in_new_rounded, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Pembelian Eksternal',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            subtitle: const Text(
              'Saat aktif, tombol "Pesan Sekarang" akan membuka website pihak ketiga.',
              style: TextStyle(fontSize: 12),
            ),
          ),
          if (_useExternalBooking)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextFormField(
                controller: _externalBookingUrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'URL Pembelian',
                  hintText: 'https://...',
                  prefixIcon: const Icon(Icons.link_rounded),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  if (!_useExternalBooking) return null;
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return 'URL wajib diisi saat fitur aktif';
                  if (!s.startsWith('http://') && !s.startsWith('https://')) {
                    return 'URL harus diawali http:// atau https://';
                  }
                  return null;
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _difficultyDropdown() {
    const options = ['Mudah', 'Sedang', 'Sulit', 'Sangat Sulit'];
    final value = options.contains(_difficulty.text) ? _difficulty.text : 'Sedang';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) => _difficulty.text = v ?? 'Sedang',
        decoration: const InputDecoration(
          labelText: 'Tingkat Kesulitan',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
