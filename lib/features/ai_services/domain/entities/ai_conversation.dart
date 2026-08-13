import 'package:equatable/equatable.dart';

/// Represents an AI conversation session.
class AiConversation extends Equatable {
  const AiConversation({
    required this.id,
    required this.userId,
    this.petId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? petId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, userId, petId, title, createdAt, updatedAt];
}
