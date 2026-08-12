import 'package:petconnect_ai/features/veterinarian/domain/entities/pharmacy_item.dart';

class PharmacyItemModel extends PharmacyItem {
  const PharmacyItemModel({
    required super.id,
    required super.clinicId,
    required super.itemName,
    super.category = 'Pharmacy',
    required super.sku,
    super.stockQuantity = 0,
    super.unit = 'units',
    super.status = 'Optimal',
    super.isCritical = false,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PharmacyItemModel.fromJson(Map<String, dynamic> json) {
    return PharmacyItemModel(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      itemName: json['item_name'] as String,
      category: (json['category'] as String?) ?? 'Pharmacy',
      sku: json['sku'] as String,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      unit: (json['unit'] as String?) ?? 'units',
      status: (json['status'] as String?) ?? 'Optimal',
      isCritical: (json['is_critical'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clinic_id': clinicId,
      'item_name': itemName,
      'category': category,
      'sku': sku,
      'stock_quantity': stockQuantity,
      'unit': unit,
      'status': status,
      'is_critical': isCritical,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
