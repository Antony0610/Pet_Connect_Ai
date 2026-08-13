import 'package:equatable/equatable.dart';

/// Represents an individual chat message in an AI conversation.
class AiChatMessage extends Equatable {
  const AiChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderRole,
    required this.messageText,
    this.metadata = const {},
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderRole; // user, assistant, system
  final String messageText;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderRole,
    messageText,
    metadata,
    createdAt,
  ];
}
