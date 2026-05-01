import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/events_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/explore/explore_event_card.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<EventsProvider>().fetchEvents();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<EventsProvider>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Event Pendaki',
          style: GoogleFonts.beVietnamPro(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: provider.isLoading && provider.events.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.events.isEmpty
              ? _Empty()
              : RefreshIndicator(
                  color: colors.primaryOrange,
                  onRefresh: () => provider.fetchEvents(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: provider.events.length,
                    itemBuilder: (_, i) =>
                        ExploreEventCard(event: provider.events[i]),
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
            Icon(Icons.event_outlined, color: colors.textMuted, size: 64),
            const SizedBox(height: 12),
            Text(
              'Belum ada event mendatang',
              style: GoogleFonts.beVietnamPro(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
