import 'package:frontend/features/suppliers/domain/entities/purchase.dart';

abstract class PurchaseRepository {
  Future<List<Purchase>> getAllPurchases({int? limit, String? lastId});
  Future<Purchase?> getPurchaseById(String id);
  Future<Purchase> createPurchase(Map<String, dynamic> data);
  Future<Purchase?> updatePurchase(String id, Map<String, dynamic> data);
  Future<bool> deletePurchase(String id);
  Future<Purchase?> settlePurchase(String id);
  Future<List<Purchase>> getPurchasesBySupplier(String supplierId, {int? limit, String? lastId});
}

