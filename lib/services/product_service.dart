import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import 'storage_service.dart';
import 'pad_service.dart';
import '../models/product_model.dart';

class ProductService {
  static final ProductService instance = ProductService._();
  ProductService._();

  // ====== SEARCH ======
  Future<List<ProductModel>> search({
    String? modelId,
    String? materialIdInput,
    String? supplierId,
    int? priceMin,
    int? priceMax,
    int? stockMin,
    int? stockMax,
    bool priceChanged = false,
  }) async {
    final db = FirebaseService.instance.db;
    Query q = db.collection(FirebaseService.instance.productsCol);

    // Model equality (0 -> 000, 12 -> 012)
    if (modelId != null && modelId.trim().isNotEmpty) {
      final normalizedModel = PadService.normalizeModelId(modelId);
      q = q.where('model_id', isEqualTo: normalizedModel);
    }

    // Material equality (3 char) tanpa mengubah pola spasi user
    if (materialIdInput != null) {
      final padded = PadService.padMaterialForSearch(materialIdInput);
      if (padded != null) {
        q = q.where('material_id', isEqualTo: padded);
      }
    }

    // Supplier equality (uppercase)
    if (supplierId != null && supplierId.trim().isNotEmpty) {
      final s = supplierId.trim().toUpperCase();
      q = q.where('supplier_id', isEqualTo: s);
    }

    // Ambil kandidat tanpa inequality harga/stock (hindari composite index).
    final snap = await q.get();

    // Client-side filters untuk range dan priceChanged
    final list = <ProductModel>[];
    for (final d in snap.docs) {
      final data = d.data() as Map<String, dynamic>;
      final m = ProductModel.fromMap(d.id, data);

      if (priceMin != null && m.currentPrice < priceMin) continue;
      if (priceMax != null && m.currentPrice > priceMax) continue;
      if (stockMin != null && m.amount < stockMin) continue;
      if (stockMax != null && m.amount > stockMax) continue;
      if (priceChanged && m.currentPrice == m.oldPrice) continue;

      list.add(m);
    }

    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  // ====== GET DETAIL ======
  Future<ProductModel?> getById(String docId) async {
    final db = FirebaseService.instance.db;
    final doc = await db.collection(FirebaseService.instance.productsCol).doc(docId).get();
    final data = doc.data();
    if (data == null) return null;
    return ProductModel.fromMap(doc.id, data as Map<String, dynamic>);
  }

  // ====== ADD (TANPA SEQUENCE) ======
  Future<String> add({
    required String name,
    required String modelId,
    required String materialIdInput, // bisa ada spasi di depan/belakang
    required String supplierId,
    required int amount,
    required int currentPrice,
    required int oldPrice,
    File? imageFile,
  }) async {
    final db = FirebaseService.instance.db;
    final now = DateTime.now();

    // Normalisasi/padding
    final modelNorm = PadService.normalizeModelId(modelId);
    final materialPadded = PadService.padMaterialForStore(materialIdInput);
    final supplier = supplierId.trim().toUpperCase();

    // stock_id final = modelNorm + material(3 char) + "-" + supplier (TANPA sequence number)
    final stockId = '$modelNorm$materialPadded-$supplier';

    // Upload image jika ada
    String? imageURL;
    if (imageFile != null) {
      imageURL = await StorageService.instance.uploadProductImage(imageFile, stockId);
    }

    // docId = stock_id
    await db.collection(FirebaseService.instance.productsCol).doc(stockId).set({
      'name': name,
      'model_id': modelNorm,
      'material_id': materialPadded,
      'supplier_id': supplier,
      'stock_id': stockId,
      'amount': amount,
      'current_price': currentPrice,
      'old_price': oldPrice,
      'imageURL': imageURL,
      'createdAt': now,
      'updatedAt': now,
    });

    return stockId;
  }

  // ====== UPDATE (KEEP stock_id/docId) ======
  Future<void> update({
    required String docId,
    required String name,
    required String modelId,
    required String materialIdInput,
    required String supplierId,
    required int amount,
    required int currentPrice,
    required int oldPrice,
    required String stockId, // keep existing
    File? newImageFile,
  }) async {
    final db = FirebaseService.instance.db;
    final now = DateTime.now();

    final modelNorm = PadService.normalizeModelId(modelId);
    final materialPadded = PadService.padMaterialForStore(materialIdInput);
    final supplier = supplierId.trim().toUpperCase();

    String? imageURL;
    if (newImageFile != null) {
      imageURL = await StorageService.instance.uploadProductImage(newImageFile, stockId);
    }

    final payload = {
      'name': name,
      'model_id': modelNorm,
      'material_id': materialPadded,
      'supplier_id': supplier,
      'amount': amount,
      'current_price': currentPrice,
      'old_price': oldPrice,
      'updatedAt': now,
    };
    if (imageURL != null) payload['imageURL'] = imageURL;

    await db.collection(FirebaseService.instance.productsCol).doc(docId).update(payload);
  }

  // ====== DELETE ======
  Future<void> delete(String docId) async {
    final db = FirebaseService.instance.db;
    await db.collection(FirebaseService.instance.productsCol).doc(docId).delete();
  }
}
