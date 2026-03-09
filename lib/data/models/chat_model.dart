enum ChatRole { user, assistant, system }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.timestamp,
    this.isLiked,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime? timestamp;
  final bool? isLiked;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: ChatRole.values.byName(json['role'] as String),
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      isLiked: json['is_liked'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'content': content,
        'timestamp': timestamp?.toIso8601String(),
        'is_liked': isLiked,
      };
}

class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    this.projectId,
    this.isPinned = false,
    this.createdAt,
    this.messages = const [],
  });

  final String id;
  final String title;
  final String? projectId;
  final bool isPinned;
  final DateTime? createdAt;
  final List<ChatMessage> messages;
}
