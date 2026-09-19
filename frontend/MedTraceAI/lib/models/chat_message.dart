class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? tags;
  final String? codeSnippet;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.tags,
    this.codeSnippet,
  }) : timestamp = timestamp ?? DateTime.now();
}
