import 'package:equatable/equatable.dart';

/// Represents a media item in a pet's gallery.
class PetGalleryMedia extends Equatable {
  const PetGalleryMedia({
    required this.id,
    required this.petId,
    required this.uploadedBy,
    required this.mediaUrl,
    required this.storagePath,
    this.caption,
    this.fileSize,
    this.mimeType,
    required this.createdAt,
  });

  final String id;
  final String petId;
  final String uploadedBy;
  final String mediaUrl;
  final String storagePath;
  final String? caption;
  final int? fileSize;
  final String? mimeType;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    petId,
    uploadedBy,
    mediaUrl,
    storagePath,
    caption,
    fileSize,
    mimeType,
    createdAt,
  ];
}
