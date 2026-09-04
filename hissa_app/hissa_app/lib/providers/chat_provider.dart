import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  final List<ChatMessage> _messages = [];
  bool _typing = false;
  Timer? _pending;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get typing => _typing;
  bool get isEmpty => _messages.isEmpty;

  void send(String text, {required bool isAr}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _typing) return;

    _messages.add(ChatMessage.user(trimmed));
    _typing = true;
    notifyListeners();

    final answer = _service.reply(trimmed, isAr: isAr);
    _pending?.cancel();
    _pending = Timer(_service.typingDelay(answer), () {
      _messages.add(ChatMessage.bot(answer));
      _typing = false;
      notifyListeners();
    });
  }

  void clear() {
    _pending?.cancel();
    _messages.clear();
    _typing = false;
    notifyListeners();
  }

  void reset() => clear();

  @override
  void dispose() {
    _pending?.cancel();
    super.dispose();
  }
}
