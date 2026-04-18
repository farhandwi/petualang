import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/dm_provider.dart';
import '../../theme/app_theme.dart';
import 'dm_detail_screen.dart';

class DmSearchScreen extends StatefulWidget {
  const DmSearchScreen({super.key});

  @override
  State<DmSearchScreen> createState() => _DmSearchScreenState();
}

class _DmSearchScreenState extends State<DmSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<dynamic> _users = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _users = [];
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await context.read<DmProvider>().searchUsers(query);
      setState(() => _users = results);
    } catch (_) {
      // Ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openChat(Map<String, dynamic> user) async {
    final provider = context.read<DmProvider>();
    // Start loader maybe
    final convId = await provider.createOrGetConversation(user['id'] as int);
    if (!mounted) return;

    if (convId != null) {
      // Replace with detail screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DmDetailScreen(
            conversationId: convId,
            targetUserId: user['id'] as int,
            targetUserName: user['name'] as String,
            targetUserAvatar: user['profile_picture'] as String?,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat percakapan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Cari pengguna...',
            hintStyle: GoogleFonts.beVietnamPro(color: context.colors.textMuted),
            border: InputBorder.none,
          ),
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textPrimary,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange))
          : _users.isEmpty && _searchController.text.isNotEmpty
              ? Center(
                  child: Text(
                    'Pengguna tidak ditemukan',
                    style: GoogleFonts.beVietnamPro(color: context.colors.textSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index] as Map<String, dynamic>;
                    final bool isBlocked = user['is_blocked'] == true;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user['profile_picture'] != null && user['profile_picture'].toString().isNotEmpty
                            ? NetworkImage(user['profile_picture'] as String)
                            : null,
                        child: user['profile_picture'] == null || user['profile_picture'].toString().isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(
                        user['name'] ?? '',
                        style: GoogleFonts.beVietnamPro(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        isBlocked ? '(Terblokir)' : user['email'] ?? '',
                        style: GoogleFonts.beVietnamPro(
                          color: isBlocked ? AppTheme.errorColor : context.colors.textSecondary,
                        ),
                      ),
                      onTap: isBlocked ? null : () => _openChat(user),
                    );
                  },
                ),
    );
  }
}
