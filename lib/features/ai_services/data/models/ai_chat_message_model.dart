import 'package:petconnect_ai/features/ai_services/domain/entities/ai_chat_message.dart';

class AiChatMessageModel extends AiChatMessage {
  const AiChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderRole,
    required super.messageText,
    super.metadata = const {},
    required super.createdAt,
  });

  factory AiChatMessageModel.fromJson(Map<String, dynamic> json) {
    return AiChatMessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderRole: (json['sender_role'] as String?) ?? 'user',
      messageText: json['message_text'] as String,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'sender_role': senderRole,
      'message_text': messageText,
      'metadata': metadata,
    };
  }
}
