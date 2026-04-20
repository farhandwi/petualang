import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/chat_message_model.dart';
import '../../theme/app_theme.dart';
import '../community/report_bottom_sheet.dart';
import '../level_avatar.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isMe = message.isMe;
    final isSystem = message.type == 'system';

    if (isSystem) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.border,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          left: isMe ? 60 : 12,
          right: isMe ? 12 : 60,
          top: 2,
          bottom: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _SmallAvatar(name: message.senderName ?? '?', url: message.senderAvatar, level: message.senderLevel),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: () => ReportBottomSheet.show(
                  context,
                  targetType: 'message',
                  targetId: message.id,
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (!isMe)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 2),
                        child: Text(
                          message.senderName ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.primaryOrange,
                          ),
                        ),
                      ),
                    Container(
                      padding: _padding,
                      decoration: BoxDecoration(
                        color: isMe ? colors.primaryOrange : colors.surface,
                        border: isMe ? null : Border.all(color: colors.border),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildContent(colors, isMe),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(fontSize: 10, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  EdgeInsets get _padding {
    if (message.type == 'image') return const EdgeInsets.all(4);
    return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  }

  Widget _buildContent(dynamic colors, bool isMe) {
    if (message.type == 'image' && message.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          AppConfig.resolveImageUrl(message.imageUrl),
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded),
        ),
      );
    }
    return Text(
      message.isDeleted ? '🗑 Pesan telah dihapus' : message.content,
      style: TextStyle(
        fontSize: 14,
        color: isMe ? Colors.white : colors.textPrimary,
        fontStyle: message.isDeleted ? FontStyle.italic : FontStyle.normal,
        height: 1.4,
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _SmallAvatar extends StatelessWidget {
  final String name;
  final String? url;
  final int level;
  
  const _SmallAvatar({required this.name, this.url, required this.level});

  @override
  Widget build(BuildContext context) {
    return LevelAvatar(
      level: level,
      radius: 14,
      avatarUrl: url,
      name: name,
    );
  }
}
