import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _nikController;
  late TextEditingController _ktpAddressController;
  late TextEditingController _domicileAddressController;
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyPhoneController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isSameAsKtp = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone ?? '');
    _nikController = TextEditingController(text: user.nik ?? '');
    _ktpAddressController = TextEditingController(text: user.ktpAddress ?? '');
    _domicileAddressController = TextEditingController(text: user.domicileAddress ?? '');
    _emergencyNameController = TextEditingController(text: user.emergencyContactName ?? '');
    _emergencyPhoneController = TextEditingController(text: user.emergencyContactPhone ?? '');
    _heightController = TextEditingController(text: user.heightCm?.toString() ?? '');
    _weightController = TextEditingController(text: user.weightKg?.toString() ?? '');
    
    _selectedDate = user.dateOfBirth;
    _selectedGender = user.gender;

    if (user.ktpAddress != null && user.ktpAddress == user.domicileAddress) {
      _isSameAsKtp = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nikController.dispose();
    _ktpAddressController.dispose();
    _domicileAddressController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: context.colors.primaryOrange,
              primary: context.colors.primaryOrange,
              onPrimary: Colors.white,
              surface: context.colors.card,
              onSurface: context.colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_isSameAsKtp) {
        _domicileAddressController.text = _ktpAddressController.text;
      }

      // Helper: kirim null jika string kosong agar COALESCE di DB
      // tidak menimpa nilai lama dengan string kosong.
      String? orNull(String s) => s.trim().isEmpty ? null : s.trim();

      final data = {
        'name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        'phone': orNull(_phoneController.text),
        'nik': orNull(_nikController.text),
        'date_of_birth': _selectedDate?.toIso8601String(),
        'gender': _selectedGender,
        'ktp_address': orNull(_ktpAddressController.text),
        'domicile_address': orNull(_domicileAddressController.text),
        'emergency_contact_name': orNull(_emergencyNameController.text),
        'emergency_contact_phone': orNull(_emergencyPhoneController.text),
        'height_cm': int.tryParse(_heightController.text),
        'weight_kg': int.tryParse(_weightController.text),
      };

      final success = await context.read<AuthProvider>().updateProfile(data);
      
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: context.colors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        final error = context.read<AuthProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal memperbarui profil'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user!;
    final completeness = user.profileCompleteness;
    
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Edit Profil'),
        actions: [
          TextButton(
            onPressed: authProvider.isLoading ? null : _saveProfile,
            child: authProvider.isLoading 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Simpan'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Progress Bar
            Container(
              color: context.colors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kelengkapan Data',
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(completeness * 100).toInt()}%',
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.primaryOrange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completeness,
                      backgroundColor: context.colors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(context.colors.primaryOrange),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Data Identitas'),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      icon: Icons.person_rounded,
                      validator: (val) => val!.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nikController,
                      label: 'Nomor Induk Kependudukan (NIK)',
                      icon: Icons.badge_rounded,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Nomor Telepon',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: context.colors.input,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: context.colors.textMuted, size: 20),
                            const SizedBox(width: 16),
                            Text(
                              _selectedDate == null 
                                ? 'Tanggal Lahir' 
                                : DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate!),
                              style: GoogleFonts.beVietnamPro(
                                color: _selectedDate == null ? context.colors.textHint : context.colors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Jenis Kelamin',
                        prefixIcon: Icon(Icons.people_alt_rounded),
                      ),
                      items: ['Laki-laki', 'Perempuan'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),

                    const SizedBox(height: 32),
                    _SectionTitle(title: 'Alamat'),
                    _buildTextField(
                      controller: _ktpAddressController,
                      label: 'Alamat sesuai KTP',
                      icon: Icons.home_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: _isSameAsKtp,
                          onChanged: (val) {
                            setState(() {
                              _isSameAsKtp = val ?? false;
                              if (_isSameAsKtp) {
                                _domicileAddressController.text = _ktpAddressController.text;
                              }
                            });
                          },
                          activeColor: context.colors.primaryOrange,
                        ),
                        Text(
                          'Alamat domisili sama dengan KTP',
                          style: GoogleFonts.beVietnamPro(
                            color: context.colors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (!_isSameAsKtp) ...[
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _domicileAddressController,
                        label: 'Alamat Domisili',
                        icon: Icons.location_on_rounded,
                        maxLines: 3,
                      ),
                    ],

                    const SizedBox(height: 32),
                    _SectionTitle(title: 'Kontak Darurat'),
                    _buildTextField(
                      controller: _emergencyNameController,
                      label: 'Nama Kontak Darurat',
                      icon: Icons.health_and_safety_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emergencyPhoneController,
                      label: 'Nomor Kontak Darurat',
                      icon: Icons.phone_in_talk_rounded,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 32),
                    _SectionTitle(title: 'Data Fisik'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _heightController,
                            label: 'Tinggi (cm)',
                            icon: Icons.height_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _weightController,
                            label: 'Berat (kg)',
                            icon: Icons.monitor_weight_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _saveProfile,
                        child: Text('Simpan Perubahan'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.beVietnamPro(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: validator,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.beVietnamPro(
          color: context.colors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
