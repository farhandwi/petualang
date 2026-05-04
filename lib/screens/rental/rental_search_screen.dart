import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/mountain_model.dart';
import '../../providers/booking_provider.dart';
import '../../providers/rental_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'rental_list_screen.dart';

class RentalSearchScreen extends StatefulWidget {
  const RentalSearchScreen({super.key});

  @override
  State<RentalSearchScreen> createState() => _RentalSearchScreenState();
}

class _RentalSearchScreenState extends State<RentalSearchScreen> {
  MountainModel? _selectedMountain;
  RouteModel? _entryRoute;
  RouteModel? _exitRoute;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchMountains();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _submit() {
    if (_selectedMountain == null ||
        _startDate == null ||
        _endDate == null ||
        _entryRoute == null ||
        _exitRoute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harap lengkapi semua data sewa.'),
          backgroundColor: context.colors.error,
        ),
      );
      return;
    }

    final provider = context.read<RentalProvider>();
    provider.setRentalTarget(
      mountain: _selectedMountain!,
      start: _startDate!,
      end: _endDate!,
      entry: _entryRoute!,
      exit: _exitRoute!,
    );
    provider.fetchItems(); // Automatically refetch items mapped to this mountain
    // RentalMainScreen will automatically rebuild and show RentalListScreen!
  }

  @override
  Widget build(BuildContext context) {
    final mProvider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Rencana Pendakian (Pre-Sewa)'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: () {
              // Validasi manual cepat untuk disable tombol 
              if (_selectedMountain == null || _startDate == null || _endDate == null || _entryRoute == null || _exitRoute == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lengkapi semua field dulu'), backgroundColor: context.colors.error));
                return;
              }
              _submit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primaryOrange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'Lanjutkan Cari Alat',
              style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
      body: mProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: context.colors.primaryOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ContentConstrained.form(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pilih Destinasi Gunung',
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MountainModel>(
                        value: _selectedMountain,
                        hint: Text('Pilih Gunung', style: GoogleFonts.beVietnamPro(color: context.colors.textMuted)),
                        isExpanded: true,
                        dropdownColor: context.colors.surface,
                        style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary),
                        items: mProvider.mountains.map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(m.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedMountain = val;
                            // reset routes if mountain changes
                            _entryRoute = null;
                            _exitRoute = null;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  Text(
                    'Tanggal Operasional',
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _selectDateRange(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, color: context.colors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _startDate != null && _endDate != null
                                  ? '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                                  : 'Pilih Tanggal Mulai - Selesai',
                              style: GoogleFonts.beVietnamPro(
                                color: _startDate != null ? context.colors.textPrimary : context.colors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_selectedMountain != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Rute / Pos Titik Pengambilan Alat',
                      style: GoogleFonts.beVietnamPro(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Pos Masuk', style: GoogleFonts.beVietnamPro(color: context.colors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<RouteModel>(
                          value: _entryRoute,
                          hint: Text('Pilih Pos Masuk', style: GoogleFonts.beVietnamPro(color: context.colors.textMuted)),
                          isExpanded: true,
                          dropdownColor: context.colors.surface,
                          style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary),
                          items: _selectedMountain!.routes.map((r) {
                            return DropdownMenuItem(value: r, child: Text(r.name));
                          }).toList(),
                          onChanged: (val) => setState(() => _entryRoute = val),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text('Pos Keluar', style: GoogleFonts.beVietnamPro(color: context.colors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<RouteModel>(
                          value: _exitRoute,
                          hint: Text('Pilih Pos Keluar', style: GoogleFonts.beVietnamPro(color: context.colors.textMuted)),
                          isExpanded: true,
                          dropdownColor: context.colors.surface,
                          style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary),
                          items: _selectedMountain!.routes.map((r) {
                            return DropdownMenuItem(value: r, child: Text(r.name));
                          }).toList(),
                          onChanged: (val) => setState(() => _exitRoute = val),
                        ),
                      ),
                    ),
                    if (_entryRoute != null && _exitRoute != null && _entryRoute!.id != _exitRoute!.id)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: context.colors.primaryOrange, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pos masuk dan keluar berbeda. Akan ada tambahan biaya delivery antar jemput alat Rp 50.000.',
                                style: GoogleFonts.beVietnamPro(color: context.colors.textSecondary, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                      ),
                  ],
                ],
              ),
              ),
            ),
    );
  }
}
