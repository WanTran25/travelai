class AiLog {
  final int id;
  final int? userId;
  final String userPrompt;
  final String aiResponseJson;
  final int createdAt;

  AiLog({
    this.id = 0,
    this.userId,
    required this.userPrompt,
    required this.aiResponseJson,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userPrompt': userPrompt,
        'aiResponseJson': aiResponseJson,
        'createdAt': createdAt,
      };

  factory AiLog.fromMap(Map<String, dynamic> map) => AiLog(
        id: map['id'] as int,
        userId: map['userId'] as int?,
        userPrompt: map['userPrompt'] as String,
        aiResponseJson: map['aiResponseJson'] as String,
        createdAt: map['createdAt'] as int,
      );
}
