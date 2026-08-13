import 'package:petconnect_ai/features/ai_services/domain/entities/ai_conversation.dart';

class AiConversationModel extends AiConversation {
  const AiConversationModel({
    required super.id,
    required super.userId,
    super.petId,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AiConversationModel.fromJson(Map<String, dynamic> json) {
    return AiConversationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      petId: json['pet_id'] as String?,
      title: (json['title'] as String?) ?? 'Pet Care Chat',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'pet_id': petId, 'title': title};
  }
}
