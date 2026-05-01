import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/mountain_model.dart';
import '../../providers/buddies_provider.dart';
import '../../providers/explore_provider.dart';
import '../../theme/app_theme.dart';

class BuddyCreateScreen extends StatefulWidget {
  const BuddyCreateScreen({super.key});

  @override
  State<BuddyCreateScreen> createState() => _BuddyCreateScreenState();
}

class _BuddyCreateScreenState extends State<BuddyCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  MountainModel? _selectedMountain;
  DateTime? _targetDate;
  int _maxBuddies = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load mountains via ExploreProvider kalau belum ada
      final provider = context.read<ExploreProvider>();
      if (provider.exploreData == null) {
        provider.fetchExploreData();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal target')),
      );
      return;
    }

    final error = await context.read<BuddiesProvider>().createBuddy(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          mountainId: _selectedMountain?.id,
          targetDate: _targetDate!,
          maxBuddies: _maxBuddies,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red.shade700),
      );
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajakan berhasil dibuat')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mountains =
        context.watch<ExploreProvider>().exploreData?.popularMountains ?? [];
    final isCreating = context.watch<BuddiesProvider>().isCreating;
    final dateFmt = DateFormat('d MMM yyyy', 'id_ID');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Buat Ajakan',
          style: GoogleFonts.beVietnamPro(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _Label('Judul ajakan'),
              TextFormField(
                controller: _titleController,
                decoration: _decoration(colors, hint: 'Mis. Naik Semeru via Ranu Pane'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _Label('Gunung tujuan (opsional)'),
              DropdownButtonFormField<MountainModel?>(
                value: _selectedMountain,
                decoration: _decoration(colors),
                items: [
                  const DropdownMenuItem<MountainModel?>(
                    value: null,
                    child: Text('— Belum dipilih —'),
                  ),
                  ...mountains.map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.name),
                      )),
                ],
                onChanged: (m) => setState(() => _selectedMountain = m),
              ),
              const SizedBox(height: 16),

              _Label('Tanggal target'),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          color: colors.textMuted, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _targetDate != null
                            ? dateFmt.format(_targetDate!)
                            : 'Pilih tanggal',
                        style: TextStyle(
                          color: _targetDate != null
                              ? colors.textPrimary
                              : colors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _Label('Berapa orang dibutuhkan?'),
              Row(
                children: [
                  IconButton(
                    onPressed: _maxBuddies > 1
                        ? () => setState(() => _maxBuddies--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(
                      '$_maxBuddies orang',
                      style: GoogleFonts.beVietnamPro(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _maxBuddies < 10
                        ? () => setState(() => _maxBuddies++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _Label('Deskripsi (opsional)'),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: _decoration(colors,
                    hint: 'Cerita lebih detail tentang rencana pendakian...'),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isCreating ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Posting Ajakan',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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

  InputDecoration _decoration(AppColors colors, {String? hint}) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: colors.surface,
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
          borderSide: BorderSide(color: colors.primaryOrange),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.beVietnamPro(
          color: context.colors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
