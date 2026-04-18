import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/dm_conversation_model.dart';
import '../models/dm_message_model.dart';
import '../services/dm_api_service.dart';

class DmProvider extends ChangeNotifier {
  final DmApiService _service = DmApiService();

  // State
  List<DMConversationModel> conversations = [];
  Map<int, List<DMMessageModel>> messagesByConversation = {};
  Map<int, bool> typingStatusByConversation = {}; // is the other user typing

  bool isConnected = false;
  bool isConversationsLoading = false;
  bool isMessagesLoading = false;
  int? connectedConversationId;

  String? _token;
  int? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  void setUser({required String? token, required int? userId, String? name, String? avatar}) {
    _token = token;
    _currentUserId = userId;
    _currentUserName = name;
    _currentUserAvatar = avatar;
  }

  // ─── REST ────────────────────────────────────────────────────

  Future<void> fetchConversations() async {
    if (_token == null) return;
    isConversationsLoading = true;
    notifyListeners();

    try {
      conversations = await _service.fetchConversations(_token!);
    } catch (_) {}

    isConversationsLoading = false;
    notifyListeners();
  }

  Future<void> fetchMessages(int conversationId, {bool refresh = false}) async {
    if (_token == null || _currentUserId == null) return;
    isMessagesLoading = true;
    notifyListeners();

    try {
      final current = messagesByConversation[conversationId] ?? [];
      final oldest = (current.isEmpty || refresh) ? null : current.first.id;
      final newMessages = await _service.fetchMessages(
        conversationId,
        _token!,
        currentUserId: _currentUserId!,
        beforeId: refresh ? null : oldest,
      );
      if (refresh) {
        messagesByConversation[conversationId] = newMessages;
      } else {
        messagesByConversation[conversationId] = [...newMessages, ...current];
      }
    } catch (_) {}

    isMessagesLoading = false;
    notifyListeners();
  }

  Future<int?> createOrGetConversation(int targetUserId) async {
    if (_token == null) return null;
    final convId = await _service.createOrGetConversation(_token!, targetUserId);
    if (convId != null) {
      // refresh list
      fetchConversations();
    }
    return convId;
  }

  Future<bool> toggleBlockUser(int targetUserId) async {
    if (_token == null) return false;
    return await _service.toggleBlockUser(_token!, targetUserId);
  }

  Future<List<dynamic>> searchUsers(String query) async {
    if (_token == null) return [];
    return await _service.searchUsers(_token!, query);
  }

  // ─── WebSocket ───────────────────────────────────────────────

  Future<void> connect(int conversationId) async {
    if (_token == null) return;
    if (connectedConversationId == conversationId && isConnected) return;

    disconnect(); // Close any existing connection

    connectedConversationId = conversationId;
    _reconnectAttempts = 0;
    await _doConnect(conversationId);
  }

  Future<void> _doConnect(int conversationId) async {
    _channel = _service.connect(conversationId, _token!);
    if (_channel == null) return;

    isConnected = true;
    notifyListeners();

    _subscription = _channel!.stream.listen(
      (data) => _onData(data as String, conversationId),
      onDone: () => _handleDisconnect(conversationId),
      onError: (_) => _handleDisconnect(conversationId),
      cancelOnError: false,
    );

    // Load message history
    await fetchMessages(conversationId, refresh: true);

    // Send read receipt if there are any unread messages from the other user
    final list = messagesByConversation[conversationId] ?? [];
    if (list.any((m) => !m.isMe && !m.isRead)) {
       sendReadReceipt();
    }
    // clear local badge
    clearUnread(conversationId);
  }

  void _onData(String raw, int conversationId) {
    try {
      final msg = json.decode(raw) as Map<String, dynamic>;
      final type = msg['type'] as String? ?? '';

      if (type == 'typing') {
        final userId = msg['userId'] as int?;
        final isTyping = msg['isTyping'] as bool? ?? false;
        if (userId == _currentUserId) return;

        typingStatusByConversation[conversationId] = isTyping;
        notifyListeners();
        return;
      }

      if (type == 'read_receipt') {
         // other user has read my messages
         final userId = msg['userId'] as int?;
         if (userId != _currentUserId) {
            // mark my messages as read
            final list = messagesByConversation[conversationId] ?? [];
            final updatedList = list.map((m) {
                if (m.senderId == _currentUserId) {
                   return DMMessageModel(
                      id: m.id,
                      senderId: m.senderId,
                      senderName: m.senderName,
                      senderAvatar: m.senderAvatar,
                      type: m.type,
                      content: m.content,
                      imageUrl: m.imageUrl,
                      isRead: true, // marked
                      isMe: m.isMe,
                      createdAt: m.createdAt,
                      isError: m.isError,
                   );
                }
                return m;
            }).toList();
            messagesByConversation[conversationId] = updatedList;
            notifyListeners();
         }
         return;
      }

      if (type == 'message' || type == 'system') {
        final message = DMMessageModel.fromJson(msg, currentUserId: _currentUserId);
        final list = messagesByConversation[conversationId] ?? [];
        
        if (message.isMe && type == 'message') {
           final idx = list.indexWhere((m) => m.id < 0 && (m.content == message.content || m.imageUrl == message.imageUrl));
           if (idx != -1) {
              list[idx] = message;
              messagesByConversation[conversationId] = [...list];
           } else {
              messagesByConversation[conversationId] = [...list, message];
           }
        } else {
           messagesByConversation[conversationId] = [...list, message];
        }
        
        // Send read receipt if we open it
        if (!message.isMe && type == 'message') {
           sendReadReceipt();
           clearUnread(conversationId); // force local update before fetch gets old data
        }
        // Update unread count in conversations list
        fetchConversations();
        notifyListeners();
      }
    } catch (_) {}
  }

  void _handleDisconnect(int conversationId) {
    isConnected = false;
    notifyListeners();

    // Auto-reconnect with backoff (max 5 attempts)
    if (_reconnectAttempts < 5 && connectedConversationId == conversationId) {
      _reconnectAttempts++;
      final delay = Duration(seconds: _reconnectAttempts * 2);
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () => _doConnect(conversationId));
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    isConnected = false;
    connectedConversationId = null;
    typingStatusByConversation.clear();
    notifyListeners();
  }

  // ─── Sending ─────────────────────────────────────────────────

  void sendTextMessage(String content) {
    if (_channel == null || !isConnected || content.trim().isEmpty) return;
    _channel!.sink.add(json.encode({'type': 'text', 'content': content.trim()}));

    // Optimistic local bubble
    if (connectedConversationId != null && _currentUserId != null) {
      final msg = DMMessageModel.optimistic(
        tempId: DateTime.now().millisecondsSinceEpoch * -1,
        senderId: _currentUserId!,
        senderName: _currentUserName ?? '',
        senderAvatar: _currentUserAvatar,
        content: content.trim(),
      );
      final list = messagesByConversation[connectedConversationId!] ?? [];
      messagesByConversation[connectedConversationId!] = [...list, msg];
      notifyListeners();
    }
  }

  Future<void> sendImage(dynamic imageFile, {String content = ''}) async {
    if (_token == null || !isConnected) return;
    
    // Optimistic local bubble
    if (connectedConversationId != null && _currentUserId != null) {
      final msg = DMMessageModel.optimistic(
        tempId: DateTime.now().millisecondsSinceEpoch * -1,
        senderId: _currentUserId!,
        senderName: _currentUserName ?? '',
        senderAvatar: _currentUserAvatar,
        content: content,
        imageUrl: 'uploading', // special tag or just local path
      );
      final list = messagesByConversation[connectedConversationId!] ?? [];
      messagesByConversation[connectedConversationId!] = [...list, msg];
      notifyListeners();
    }

    // Upload to api
    final imageUrl = await _service.uploadImage(imageFile, _token!);
    if (imageUrl != null && _channel != null) {
      _channel!.sink.add(json.encode({'type': 'image', 'content': content.trim(), 'imageUrl': imageUrl}));
    } else {
      // Failed to upload, optionally remove the optimistic bubble
      if (connectedConversationId != null) {
        final list = messagesByConversation[connectedConversationId!] ?? [];
        list.removeWhere((m) => m.id < 0 && m.imageUrl == 'uploading');
        messagesByConversation[connectedConversationId!] = [...list];
        notifyListeners();
      }
    }
  }

  void sendImageMessage(String imageUrl) {
    if (_channel == null || !isConnected) return;
    _channel!.sink.add(json.encode({'type': 'image', 'content': '', 'imageUrl': imageUrl}));
  }

  void sendTyping(bool isTyping) {
    if (_channel == null || !isConnected) return;
    _channel!.sink.add(json.encode({'type': 'typing', 'isTyping': isTyping}));
  }

  void sendReadReceipt() {
    if (_channel == null || !isConnected) return;
    _channel!.sink.add(json.encode({'type': 'read'}));
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  void clearUnread(int conversationId) {
     final index = conversations.indexWhere((c) => c.id == conversationId);
     if (index >= 0) {
        conversations[index] = DMConversationModel(
           id: conversations[index].id,
           otherUserId: conversations[index].otherUserId,
           otherUserName: conversations[index].otherUserName,
           otherUserAvatar: conversations[index].otherUserAvatar,
           lastMessage: conversations[index].lastMessage,
           lastMessageType: conversations[index].lastMessageType,
           lastMessageTime: conversations[index].lastMessageTime,
           lastMessageIsRead: true,
           lastMessageSender: conversations[index].lastMessageSender,
           unreadCount: 0,
           updatedAt: conversations[index].updatedAt,
        );
        notifyListeners();
     }
  }
}
