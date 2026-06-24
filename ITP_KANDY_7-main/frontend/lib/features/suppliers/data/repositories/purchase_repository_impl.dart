// ------------------------------------------------------------------------------
// File: purchase_repository_impl.dart
// Purpose: Concrete implementation of purchase data operations via REST API.
// Rationale: Translates domain-level CRUD for purchase records, supplier-
//   scoped queries, and settlement actions into HTTP calls via ApiClient.
// ------------------------------------------------------------------------------
import 'package:frontend/core/network/api_client.dart'; // Network: HTTP request dispatch
import 'package:frontend/features/suppliers/domain/entities/purchase.dart'; // Domain: Purchase model
import 'package:frontend/features/suppliers/domain/repositories/purchase_repository.dart'; // Contract: Repository interface
class PurchaseRepositoryImpl implements PurchaseRepository {
  // Fetches the complete history of all stock purchases made by the shop.
  @override
  Future<List<Purchase>> getAllPurchases({int? limit, String? lastId}) async {
    final Map<String, String> params = {};
    if (limit != null) params['limit'] = limit.toString();
    if (lastId != null) params['lastId'] = lastId;

    final response = await ApiClient.get('/purchases', queryParameters: params);
    return (response['data'] as List)
        .map((json) => Purchase.fromJson(json))
        .toList();
  }

  @override
  Future<Purchase?> getPurchaseById(String id) async {
    final response = await ApiClient.get('/purchases/$id');
    return Purchase.fromJson(response['data']);
  }

  // Records a new purchase transaction once stock is received from a supplier.
  @override
  Future<Purchase> createPurchase(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/purchases', data);
    return Purchase.fromJson(response['data']);
  }

  @override
  Future<Purchase?> updatePurchase(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/purchases/$id', data);
    return Purchase.fromJson(response['data']);
  }

  // Deletes a specific purchase record from the history.
  @override
  Future<bool> deletePurchase(String id) async {
    final response = await ApiClient.delete('/purchases/$id');
    return response['success'] ?? false;
  }

  @override
  Future<Purchase?> settlePurchase(String id) async {
    final response = await ApiClient.put('/purchases/$id/settle', {});
    return response['data'] != null ? Purchase.fromJson(response['data']) : null;
  }

  // Shows all purchases linked to a single supplier, useful for debt tracking.
  @override
  Future<List<Purchase>> getPurchasesBySupplier(String supplierId, {int? limit, String? lastId}) async {
    final Map<String, String> params = {};
    if (limit != null) params['limit'] = limit.toString();
    if (lastId != null) params['lastId'] = lastId;

    final response = await ApiClient.get('/purchases/supplier/$supplierId', queryParameters: params);
    return (response['data'] as List)
        .map((json) => Purchase.fromJson(json))
        .toList();
  }
}

