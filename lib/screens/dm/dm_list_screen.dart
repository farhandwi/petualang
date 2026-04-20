import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/dm_provider.dart';
import '../../theme/app_theme.dart';
import 'dm_detail_screen.dart';
import 'dm_search_screen.dart';
import '../../widgets/level_avatar.dart';

class DmListScreen extends StatefulWidget {
  const DmListScreen({super.key});

  @override
  State<DmListScreen> createState() => _DmListScreenState();
}

class _DmListScreenState extends State<DmListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DmProvider>().fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          'Pesan',
          style: GoogleFonts.beVietnamPro(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
           IconButton(
             icon: Icon(Icons.search, color: context.colors.textPrimary),
             onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DmSearchScreen()),
                );
             },
           ),
        ],
      ),
      body: Consumer<DmProvider>(
        builder: (context, provider, child) {
          if (provider.isConversationsLoading && provider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
          }

          if (provider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: context.colors.textMuted.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada obrolan',
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cari pengguna dan mulai mengobrol',
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchConversations(),
            color: AppTheme.primaryOrange,
            child: ListView.separated(
              itemCount: provider.conversations.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: context.colors.border,
                indent: 80,
              ),
              itemBuilder: (context, index) {
                final conv = provider.conversations[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: LevelAvatar(
                    level: conv.otherUserLevel,
                    radius: 28,
                    avatarUrl: conv.otherUserAvatar,
                    name: conv.otherUserName,
                  ),
                  title: Text(
                    conv.otherUserName,
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.textPrimary,
                      fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    conv.lastMessage ?? 'Memulai percakapan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      color: conv.unreadCount > 0 ? context.colors.textPrimary : context.colors.textSecondary,
                      fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (conv.lastMessageTime != null)
                        Text(
                          _formatTime(conv.lastMessageTime!),
                          style: GoogleFonts.beVietnamPro(
                            color: conv.unreadCount > 0 ? AppTheme.primaryOrange : context.colors.textMuted,
                            fontSize: 12,
                            fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      if (conv.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryOrange,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${conv.unreadCount}',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    provider.clearUnread(conv.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DmDetailScreen(
                          conversationId: conv.id,
                          targetUserId: conv.otherUserId,
                          targetUserName: conv.otherUserName,
                          targetUserAvatar: conv.otherUserAvatar,
                          targetUserLevel: conv.otherUserLevel,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.push(
             context,
             MaterialPageRoute(builder: (_) => const DmSearchScreen()),
           );
        },
        backgroundColor: AppTheme.primaryOrange,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.year == time.year && now.month == time.month && now.day == time.day) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}/${time.year}';
  }
}
