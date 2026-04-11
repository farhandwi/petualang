import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  // State
  Map<int, List<ChatMessageModel>> messagesByCommunity = {};
  Map<int, Set<String>> typingUsersByCommunity = {};

  bool isConnected = false;
  bool isLoading = false;
  int? connectedCommunityId;

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

  Future<void> fetchMessages(int communityId, {bool refresh = false}) async {
    if (_token == null || _currentUserId == null) return;
    isLoading = true;
    notifyListeners();

    try {
      final current = messagesByCommunity[communityId] ?? [];
      final oldest = (current.isEmpty || refresh) ? null : current.first.id;
      final newMessages = await _service.fetchMessages(
        communityId,
        _token!,
        currentUserId: _currentUserId!,
        beforeId: refresh ? null : oldest,
      );
      if (refresh) {
        messagesByCommunity[communityId] = newMessages;
      } else {
        messagesByCommunity[communityId] = [...newMessages, ...current];
      }
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int communityId) async {
    if (_token == null) return;
    await _service.markAsRead(communityId, _token!);
  }

  // ─── WebSocket ───────────────────────────────────────────────

  Future<void> connect(int communityId) async {
    if (_token == null) return;
    if (connectedCommunityId == communityId && isConnected) return;

    disconnect(); // Close any existing connection

    connectedCommunityId = communityId;
    _reconnectAttempts = 0;
    await _doConnect(communityId);
  }

  Future<void> _doConnect(int communityId) async {
    _channel = _service.connect(communityId, _token!);
    if (_channel == null) return;

    isConnected = true;
    notifyListeners();

    _subscription = _channel!.stream.listen(
      (data) => _onData(data as String, communityId),
      onDone: () => _handleDisconnect(communityId),
      onError: (_) => _handleDisconnect(communityId),
      cancelOnError: false,
    );

    // Load message history
    await fetchMessages(communityId, refresh: true);
    await markAsRead(communityId);
  }

  void _onData(String raw, int communityId) {
    try {
      final msg = json.decode(raw) as Map<String, dynamic>;
      final type = msg['type'] as String? ?? '';

      if (type == 'typing') {
        final userId = msg['userId'] as int?;
        final userName = msg['userName'] as String? ?? '';
        final isTyping = msg['isTyping'] as bool? ?? false;
        if (userId == _currentUserId) return;

        final set = typingUsersByCommunity[communityId] ?? {};
        if (isTyping) {
          set.add(userName);
        } else {
          set.remove(userName);
        }
        typingUsersByCommunity[communityId] = set;
        notifyListeners();
        return;
      }

      if (type == 'message' || type == 'system') {
        final message = ChatMessageModel.fromJson(msg, currentUserId: _currentUserId);
        final list = messagesByCommunity[communityId] ?? [];
        messagesByCommunity[communityId] = [...list, message];
        notifyListeners();
      }
    } catch (_) {}
  }

  void _handleDisconnect(int communityId) {
    isConnected = false;
    notifyListeners();

    // Auto-reconnect with backoff (max 5 attempts)
    if (_reconnectAttempts < 5 && connectedCommunityId == communityId) {
      _reconnectAttempts++;
      final delay = Duration(seconds: _reconnectAttempts * 2);
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(delay, () => _doConnect(communityId));
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _subscription = null;
    isConnected = false;
    connectedCommunityId = null;
    notifyListeners();
  }

  // ─── Sending ─────────────────────────────────────────────────

  void sendTextMessage(String content) {
    if (_channel == null || !isConnected || content.trim().isEmpty) return;
    _channel!.sink.add(json.encode({'type': 'text', 'content': content.trim()}));

    // Optimistic local bubble
    if (connectedCommunityId != null && _currentUserId != null) {
      final msg = ChatMessageModel.optimistic(
        tempId: DateTime.now().millisecondsSinceEpoch * -1,
        conversationId: connectedCommunityId!,
        senderId: _currentUserId!,
        senderName: _currentUserName ?? '',
        senderAvatar: _currentUserAvatar,
        content: content.trim(),
      );
      final list = messagesByCommunity[connectedCommunityId!] ?? [];
      messagesByCommunity[connectedCommunityId!] = [...list, msg];
      notifyListeners();
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

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
