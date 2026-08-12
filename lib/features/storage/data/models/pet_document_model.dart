import 'package:petconnect_ai/features/storage/domain/entities/pet_document.dart';

class PetDocumentModel extends PetDocument {
  const PetDocumentModel({
    required super.id,
    required super.petId,
    required super.uploadedBy,
    required super.documentName,
    super.documentType = 'MEDICAL_REPORT',
    required super.filePath,
    super.signedUrl,
    super.fileSize,
    super.mimeType,
    required super.createdAt,
  });

  factory PetDocumentModel.fromJson(Map<String, dynamic> json) {
    return PetDocumentModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      documentName: json['document_name'] as String,
      documentType: (json['document_type'] as String?) ?? 'MEDICAL_REPORT',
      filePath: json['file_path'] as String,
      signedUrl: json['signed_url'] as String?,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pet_id': petId,
      'uploaded_by': uploadedBy,
      'document_name': documentName,
      'document_type': documentType,
      'file_path': filePath,
      'file_size': fileSize,
      'mime_type': mimeType,
    };
  }

  PetDocumentModel copyWith({String? signedUrl}) {
    return PetDocumentModel(
      id: id,
      petId: petId,
      uploadedBy: uploadedBy,
      documentName: documentName,
      documentType: documentType,
      filePath: filePath,
      signedUrl: signedUrl ?? this.signedUrl,
      fileSize: fileSize,
      mimeType: mimeType,
      createdAt: createdAt,
    );
  }
}
