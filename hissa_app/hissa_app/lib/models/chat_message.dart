class ChatMessage {
  final String text;
  final bool fromUser;
  final DateTime at;

  const ChatMessage({
    required this.text,
    required this.fromUser,
    required this.at,
  });

  ChatMessage.user(this.text) : fromUser = true, at = DateTime.now();

  ChatMessage.bot(this.text) : fromUser = false, at = DateTime.now();
}
