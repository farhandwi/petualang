import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/rental_provider.dart';
import 'rental_list_screen.dart';
import 'rental_search_screen.dart';

class RentalMainScreen extends StatelessWidget {
  const RentalMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RentalProvider>();

    // Jika prasyarat penyewaan belum diisi sama sekali,
    // tampilkan form pencarian (RentalSearchScreen).
    if (provider.selectedMountain == null || provider.startDate == null) {
      return const RentalSearchScreen();
    }

    // Jika prasyarat sudah diisi, tampilkan list item.
    return const RentalListScreen();
  }
}
