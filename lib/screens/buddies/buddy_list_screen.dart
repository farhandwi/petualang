import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/buddies_provider.dart';
import '../../theme/app_theme.dart';
import 'buddy_create_screen.dart';
import 'buddy_detail_screen.dart';
import '../../widgets/buddies/buddy_card.dart';

class BuddyListScreen extends StatefulWidget {
  const BuddyListScreen({super.key});

  @override
  State<BuddyListScreen> createState() => _BuddyListScreenState();
}

class _BuddyListScreenState extends State<BuddyListScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BuddiesProvider>().fetchBuddies();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<BuddiesProvider>();
    final buddies = provider.buddies;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Cari Barengan',
          style: GoogleFonts.beVietnamPro(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: provider.isLoading && buddies.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : buddies.isEmpty
              ? _Empty()
              : RefreshIndicator(
                  color: colors.primaryOrange,
                  onRefresh: () => provider.fetchBuddies(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: buddies.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BuddyCard(
                        buddy: buddies[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                BuddyDetailScreen(buddyId: buddies[i].id),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BuddyCreateScreen()),
        ),
        backgroundColor: colors.primaryOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Buat Ajakan',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, color: colors.textMuted, size: 64),
            const SizedBox(height: 12),
            Text(
              'Belum ada ajakan',
              style: GoogleFonts.beVietnamPro(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Jadi yang pertama buat ajakan mendaki bareng!',
              style: GoogleFonts.beVietnamPro(
                color: colors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
