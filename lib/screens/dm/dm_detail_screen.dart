import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/dm_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/permission_helper.dart';
import '../../models/dm_message_model.dart';
import '../../config/app_config.dart';
import '../../widgets/level_avatar.dart';

class DmDetailScreen extends StatefulWidget {
  final int conversationId;
  final int targetUserId;
  final String targetUserName;
  final String? targetUserAvatar;
  final int targetUserLevel;

  const DmDetailScreen({
    super.key,
    required this.conversationId,
    required this.targetUserId,
    required this.targetUserName,
    this.targetUserAvatar,
    this.targetUserLevel = 1,
  });

  @override
  State<DmDetailScreen> createState() => _DmDetailScreenState();
}

class _DmDetailScreenState extends State<DmDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DmProvider>();
      provider.connect(widget.conversationId);
    });

    _messageController.addListener(() {
      final isTypingNow = _messageController.text.isNotEmpty;
      if (isTypingNow != _isTyping) {
        _isTyping = isTypingNow;
        context.read<DmProvider>().sendTyping(_isTyping);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
        final provider = context.read<DmProvider>();
        if (!provider.isMessagesLoading) {
           provider.fetchMessages(widget.conversationId);
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text;
    
    if (_selectedImage != null) {
      context.read<DmProvider>().sendImage(_selectedImage!, content: text);
      setState(() => _selectedImage = null);
    } else {
      if (text.trim().isEmpty) return;
      context.read<DmProvider>().sendTextMessage(text);
    }
    
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    try {
      final granted = await PermissionHelper.checkPhotosPermission(context);
      if (!granted) return;

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih gambar.')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: AppTheme.errorColor),
              title: Text(
                'Blokir Pengguna',
                style: GoogleFonts.beVietnamPro(color: AppTheme.errorColor),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final isBlocked = await context.read<DmProvider>().toggleBlockUser(widget.targetUserId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isBlocked ? 'Pengguna diblokir' : 'Blokir dibuka')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal mengubah status blokir.')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 1,
        titleSpacing: 0,
        leading: BackButton(
          color: context.colors.textPrimary,
          onPressed: () {
            context.read<DmProvider>().disconnect();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            LevelAvatar(
              level: widget.targetUserLevel,
              radius: 18,
              avatarUrl: widget.targetUserAvatar,
              name: widget.targetUserName,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.targetUserName,
                    style: GoogleFonts.beVietnamPro(
                      color: context.colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Consumer<DmProvider>(
                    builder: (context, provider, child) {
                      final isTyping = provider.typingStatusByConversation[widget.conversationId] ?? false;
                      if (!provider.isConnected) {
                        return Text('Offline', style: GoogleFonts.beVietnamPro(color: context.colors.textMuted, fontSize: 12));
                      }
                      if (isTyping) {
                        return Text('Sedang mengetik...', style: GoogleFonts.beVietnamPro(color: AppTheme.primaryOrange, fontSize: 12));
                      }
                      return Text('Online', style: GoogleFonts.beVietnamPro(color: AppTheme.successColor, fontSize: 12));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: context.colors.textPrimary),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<DmProvider>(
              builder: (context, provider, child) {
                final messages = provider.messagesByConversation[widget.conversationId] ?? [];
                
                if (provider.isMessagesLoading && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange));
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Newest at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[messages.length - 1 - index];
                    return _MessageBubble(message: msg);
                  },
                );
              },
            ),
          ),
          
          // Chat input container
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: context.colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedImage != null) ...[
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 8, left: 48),
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4, // Actually left 48 + 120 = 168. So left 168-24=144. Let's just make the image part of smaller stack
                        left: 144,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate_rounded, color: context.colors.textMuted),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.colors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.beVietnamPro(color: context.colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan...',
                          hintStyle: GoogleFonts.beVietnamPro(color: context.colors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final DMMessageModel message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.type == 'system' || message.isError) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: message.isError ? AppTheme.errorColor.withOpacity(0.1) : context.colors.input,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              color: message.isError ? AppTheme.errorColor : context.colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    final isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            LevelAvatar(
              level: message.senderLevel,
              radius: 14,
              avatarUrl: message.senderAvatar,
              name: message.senderName ?? '?',
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryOrange : context.colors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: message.imageUrl == 'uploading'
                            ? _buildUploadingPlaceholder()
                            : Image.network(
                                AppConfig.resolveImageUrl(message.imageUrl!),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: GoogleFonts.beVietnamPro(
                        color: isMe ? Colors.white : context.colors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.createdAt != null
                            ? DateFormat('HH:mm').format(message.createdAt!)
                            : '...',
                        style: GoogleFonts.beVietnamPro(
                          color: isMe ? Colors.white70 : context.colors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all, // double ticks for sent
                          size: 14,
                          color: message.isRead ? Colors.blue : (isMe ? Colors.white70 : context.colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) const SizedBox(width: 22),
        ],
      ),
    );
  }

  Widget _buildUploadingPlaceholder() {
    return Container(
      width: 150,
      height: 150,
      color: Colors.black12,
      child: const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryOrange),
      ),
    );
  }
}
