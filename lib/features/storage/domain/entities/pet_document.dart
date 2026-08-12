import 'package:equatable/equatable.dart';

/// Represents a private health or vaccination document in the encrypted vault.
class PetDocument extends Equatable {
  const PetDocument({
    required this.id,
    required this.petId,
    required this.uploadedBy,
    required this.documentName,
    this.documentType = 'MEDICAL_REPORT',
    required this.filePath,
    this.signedUrl,
    this.fileSize,
    this.mimeType,
    required this.createdAt,
  });

  final String id;
  final String petId;
  final String uploadedBy;
  final String documentName;
  final String documentType;
  final String filePath;
  final String? signedUrl;
  final int? fileSize;
  final String? mimeType;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    petId,
    uploadedBy,
    documentName,
    documentType,
    filePath,
    signedUrl,
    fileSize,
    mimeType,
    createdAt,
  ];
}
