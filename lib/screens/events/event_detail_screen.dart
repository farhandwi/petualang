import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/events_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_image.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  EventModel? _event;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final result =
        await context.read<EventsProvider>().fetchEventDetail(widget.eventId);
    if (!mounted) return;
    setState(() {
      _event = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFmt = DateFormat('EEEE, d MMMM yyyy · HH:mm', 'id_ID');

    return Scaffold(
      backgroundColor: colors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _event == null
              ? _NotFound()
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 240,
                      pinned: true,
                      backgroundColor: colors.background,
                      foregroundColor: Colors.white,
                      flexibleSpace: FlexibleSpaceBar(
                        background: AppImage(
                          url: _event!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: colors.primaryOrange),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            _event!.title,
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            text: dateFmt.format(_event!.eventDate),
                          ),
                          if (_event!.location != null) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.location_on_rounded,
                              text: _event!.location!,
                            ),
                          ],
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.people_alt_rounded,
                            text: _event!.maxParticipants != null
                                ? '${_event!.currentParticipants}/${_event!.maxParticipants} peserta'
                                : '${_event!.currentParticipants} peserta',
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Tentang Event',
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _event!.description ?? 'Belum ada deskripsi.',
                            style: GoogleFonts.beVietnamPro(
                              color: colors.textSecondary,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Pendaftaran event akan segera tersedia'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primaryOrange,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Daftar Sekarang',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, color: colors.primaryOrange, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.beVietnamPro(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('Event tidak ditemukan')),
    );
  }
}
