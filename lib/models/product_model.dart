import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

class ProductModel {
  final String id; // Firestore docId
  final String name;
  final String modelId;      // model_id
  final String materialId;   // material_id (selalu 3 char padded)
  final String supplierId;   // supplier_id (uppercase disarankan)
  final String stockId;      // stock_id (unik)
  final int amount;          // stock
  final int currentPrice;
  final int oldPrice;
  final String? imageURL;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.modelId,
    required this.materialId,
    required this.supplierId,
    required this.stockId,
    required this.amount,
    required this.currentPrice,
    required this.oldPrice,
    this.imageURL,
    this.createdAt,
    this.updatedAt,
  });

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> data) {
    return ProductModel(
      id: id,
      name: (data['name'] ?? '').toString(),
      modelId: (data['model_id'] ?? '').toString(),
      materialId: (data['material_id'] ?? '').toString(),
      supplierId: (data['supplier_id'] ?? '').toString(),
      stockId: (data['stock_id'] ?? '').toString(),
      amount: _toInt(data['amount']),
      currentPrice: _toInt(data['current_price']),
      oldPrice: _toInt(data['old_price']),
      imageURL: data['imageURL'] as String?,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'model_id': modelId,
      'material_id': materialId,
      'supplier_id': supplierId,
      'stock_id': stockId,
      'amount': amount,
      'current_price': currentPrice,
      'old_price': oldPrice,
      'imageURL': imageURL,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
