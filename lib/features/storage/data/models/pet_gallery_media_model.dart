import 'package:petconnect_ai/features/storage/domain/entities/pet_gallery_media.dart';

class PetGalleryMediaModel extends PetGalleryMedia {
  const PetGalleryMediaModel({
    required super.id,
    required super.petId,
    required super.uploadedBy,
    required super.mediaUrl,
    required super.storagePath,
    super.caption,
    super.fileSize,
    super.mimeType,
    required super.createdAt,
  });

  factory PetGalleryMediaModel.fromJson(Map<String, dynamic> json) {
    return PetGalleryMediaModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      mediaUrl: json['media_url'] as String,
      storagePath: json['storage_path'] as String,
      caption: json['caption'] as String?,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'uploaded_by': uploadedBy,
      'media_url': mediaUrl,
      'storage_path': storagePath,
      'caption': caption,
      'file_size': fileSize,
      'mime_type': mimeType,
    };
  }
}
