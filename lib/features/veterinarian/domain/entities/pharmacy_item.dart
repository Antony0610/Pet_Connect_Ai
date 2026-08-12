import 'package:equatable/equatable.dart';

/// Clinic Pharmacy Inventory Item entity.
class PharmacyItem extends Equatable {
  const PharmacyItem({
    required this.id,
    required this.clinicId,
    required this.itemName,
    this.category = 'Pharmacy',
    required this.sku,
    this.stockQuantity = 0,
    this.unit = 'units',
    this.status = 'Optimal',
    this.isCritical = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String itemName;
  final String category;
  final String sku;
  final int stockQuantity;
  final String unit;
  final String status;
  final bool isCritical;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    clinicId,
    itemName,
    category,
    sku,
    stockQuantity,
    unit,
    status,
    isCritical,
    createdAt,
    updatedAt,
  ];
}
