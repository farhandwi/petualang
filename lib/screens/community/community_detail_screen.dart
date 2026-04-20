import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/community_model.dart';
import '../../providers/community_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/community/post_card.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/chat/typing_indicator.dart';
import '../../widgets/chat/date_separator.dart';
import '../../widgets/level_avatar.dart';
import '../../utils/permission_helper.dart';
import '../../config/app_config.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  final CommunityModel community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatInputController = TextEditingController();
  final _chatScrollController = ScrollController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _onTabChanged() {
    if (_tabController.index == 1 && !_tabController.indexIsChanging) {
      _connectChat();
    }
  }

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;

    final provider = context.read<CommunityProvider>();
    await provider.fetchPosts(widget.community.id, refresh: true);
    await provider.fetchMembers(widget.community.id);
  }

  Future<void> _connectChat() async {
    final chat = context.read<ChatProvider>();
    await chat.connect(widget.community.id);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _joinOrLeave() async {
    final provider = context.read<CommunityProvider>();
    final community = widget.community;
    
    // Find latest community state from provider
    final current = provider.communities.firstWhere(
      (c) => c.id == community.id,
      orElse: () => community,
    );

    if (current.isMember) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Keluar Komunitas'),
          content: Text('Yakin ingin keluar dari ${current.name}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirmed == true) await provider.leaveCommunity(current.id);
    } else {
      await provider.joinCommunity(current.id);
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final granted = await PermissionHelper.checkPhotosPermission(context);
      if (!granted) return;

      final chat = context.read<ChatProvider>();
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null || !mounted) return;

      final token = context.read<AuthProvider>().token;
      if (token == null) return;

      final imageUrl = await context.read<CommunityProvider>().service.uploadImage(File(picked.path), token);
      if (imageUrl != null) {
        chat.sendImageMessage(imageUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal membuka galeri. Pastikan ijin akses foto telah diberikan.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatInputController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.watch<CommunityProvider>();
    
    final currentCommunity = provider.communities.firstWhere(
      (c) => c.id == widget.community.id,
      orElse: () => widget.community,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colors.background,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                currentCommunity.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (currentCommunity.coverImageUrl != null)
                    Image.network(
                      AppConfig.resolveImageUrl(currentCommunity.coverImageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.primaryOrange, colors.primaryOrange.withOpacity(0.5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.landscape, color: Colors.white, size: 48),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colors.primaryOrange, colors.primaryOrange.withOpacity(0.5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  Container(color: Colors.black38),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: colors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people_rounded, size: 14, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${currentCommunity.memberCount} anggota',
                              style: TextStyle(fontSize: 13, color: colors.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            if (currentCommunity.category != null) ...[
                              Icon(Icons.label_rounded, size: 14, color: colors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                currentCommunity.category!,
                                style: TextStyle(fontSize: 13, color: colors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                        if (currentCommunity.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            currentCommunity.description!,
                            style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _joinOrLeave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentCommunity.isMember ? Colors.transparent : colors.primaryOrange,
                      foregroundColor: currentCommunity.isMember ? colors.textPrimary : Colors.white,
                      elevation: 0,
                      minimumSize: Size.zero, // Add this to override theme's double.infinity
                      side: BorderSide(
                        color: currentCommunity.isMember ? colors.border : colors.primaryOrange,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      currentCommunity.isMember ? '✓ Bergabung' : 'Gabung',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: colors.primaryOrange,
                unselectedLabelColor: colors.textSecondary,
                indicatorColor: colors.primaryOrange,
                indicatorWeight: 2,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Diskusi'),
                  Tab(text: 'Chat'),
                  Tab(text: 'Anggota'),
                ],
              ),
              colors.background,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _DiscussionTab(communityId: widget.community.id),
            _ChatTab(
              communityId: widget.community.id,
              isMember: currentCommunity.isMember,
              chatInputController: _chatInputController,
              chatScrollController: _chatScrollController,
              onScrollToBottom: _scrollToBottom,
              onPickImage: _pickAndSendImage,
            ),
            _MembersTab(members: provider.selectedMembers),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0 && currentCommunity.isMember
          ? FloatingActionButton(
              mini: true,
              backgroundColor: colors.primaryOrange,
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreatePostScreen(
                      communityId: widget.community.id,
                      communityName: currentCommunity.name,
                    ),
                  ),
                );

                if (result == true && mounted) {
                  context.read<CommunityProvider>().fetchPosts(widget.community.id, refresh: true);
                }
              },
              child: const Icon(Icons.edit_rounded, color: Colors.white),
            )
          : null,
    );
  }
}

class _DiscussionTab extends StatelessWidget {
  final int communityId;

  const _DiscussionTab({required this.communityId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final posts = provider.postsByGroup[communityId] ?? [];

    if (provider.isLoadingPosts && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 64, color: context.colors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Belum ada diskusi',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jadilah yang pertama memulai obrolan!',
              style: TextStyle(color: context.colors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: context.colors.primaryOrange,
      onRefresh: () =>
          context.read<CommunityProvider>().fetchPosts(communityId, refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return PostCard(
            post: post,
            showCommunityName: false,
            onLike: () =>
                context.read<CommunityProvider>().toggleLike(post.id, communityId),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(
                  postId: post.id,
                  communityId: communityId,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  final int communityId;
  final bool isMember;
  final TextEditingController chatInputController;
  final ScrollController chatScrollController;
  final VoidCallback onScrollToBottom;
  final VoidCallback onPickImage;

  const _ChatTab({
    required this.communityId,
    required this.isMember,
    required this.chatInputController,
    required this.chatScrollController,
    required this.onScrollToBottom,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (!isMember) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 64, color: colors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Chat Khusus Anggota',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Bergabunglah dengan komunitas ini untuk mulai mengobrol dengan anggota lainnya.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final chat = context.watch<ChatProvider>();
    final messages = chat.messagesByCommunity[communityId] ?? [];
    final typingUsers = chat.typingUsersByCommunity[communityId] ?? {};

    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada pesan',
                    style: TextStyle(color: colors.textMuted),
                  ),
                )
              : ListView.builder(
                  controller: chatScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final createdAt = message.createdAt;

                    bool showDate = false;
                    if (index == 0 && createdAt != null) {
                      showDate = true;
                    } else if (createdAt != null) {
                      final prevDate = messages[index - 1].createdAt;
                      if (prevDate != null &&
                          (prevDate.day != createdAt.day ||
                              prevDate.month != createdAt.month ||
                              prevDate.year != createdAt.year)) {
                        showDate = true;
                      }
                    }

                    return Column(
                      children: [
                        if (showDate && createdAt != null) DateSeparator(date: createdAt),
                        MessageBubble(message: message),
                      ],
                    );
                  },
                ),
        ),
        if (typingUsers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TypingIndicator(
              typingUsers: typingUsers,
            ),
          ),
        ChatInputBar(
          controller: chatInputController,
          onSend: () {
            chat.sendTextMessage(chatInputController.text);
            chatInputController.clear();
            onScrollToBottom();
          },
          onPickImage: onPickImage,
          onTypingChanged: (isTyping) {
            chat.sendTyping(isTyping);
          },
        ),
      ],
    );
  }
}

class _MembersTab extends StatelessWidget {
  final List<dynamic> members;

  const _MembersTab({required this.members});

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final colors = context.colors;

        return ListTile(
          leading: LevelAvatar(
            level: member['level'] as int? ?? 1,
            radius: 20,
            avatarUrl: member['profile_picture'] as String?,
            name: (member['name'] ?? member['username'] ?? '?') as String,
          ),
          title: Text(
            (member['name'] ?? member['username'] ?? '') as String,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            member['role'] ?? 'Anggota',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          trailing: member['role'] == 'admin'
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Admin',
                    style: TextStyle(color: colors.primaryOrange, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar || oldDelegate.backgroundColor != backgroundColor;
  }
}
