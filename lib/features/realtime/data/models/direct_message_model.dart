import 'package:petconnect_ai/features/realtime/domain/entities/direct_message.dart';

class DirectMessageModel extends DirectMessage {
  const DirectMessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.messageText,
    super.isRead = false,
    required super.createdAt,
  });

  factory DirectMessageModel.fromJson(Map<String, dynamic> json) {
    return DirectMessageModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      messageText: json['message_text'] as String,
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_text': messageText,
      'is_read': isRead,
    };
  }
}
