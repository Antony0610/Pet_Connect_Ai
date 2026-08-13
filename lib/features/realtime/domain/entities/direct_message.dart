import 'package:equatable/equatable.dart';

/// Direct message domain entity for 1-to-1 live chat.
class DirectMessage extends Equatable {
  const DirectMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String messageText;
  final bool isRead;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    messageText,
    isRead,
    createdAt,
  ];
}
