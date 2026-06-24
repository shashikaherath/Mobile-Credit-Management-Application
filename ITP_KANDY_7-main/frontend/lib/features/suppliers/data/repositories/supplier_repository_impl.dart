// ------------------------------------------------------------------------------
// File: supplier_repository_impl.dart
// Purpose: Concrete implementation of supplier data operations via REST API.
// Rationale: Translates domain-level CRUD for supplier profiles and summary
//   statistics into HTTP calls via ApiClient.
// ------------------------------------------------------------------------------
import 'package:frontend/core/network/api_client.dart'; // Network: HTTP request dispatch
import 'package:frontend/features/suppliers/domain/entities/supplier.dart'; // Domain: Supplier model
import 'package:frontend/features/suppliers/domain/repositories/supplier_repository.dart'; // Contract: Repository interface
class SupplierRepositoryImpl implements SupplierRepository {
  // Retrieves every supplier from the server's database.
  @override
  Future<List<Supplier>> getAllSuppliers({int? limit, String? lastId}) async {
    final Map<String, String> params = {};
    if (limit != null) params['limit'] = limit.toString();
    if (lastId != null) params['lastId'] = lastId;

    final response = await ApiClient.get('/suppliers', queryParameters: params);
    return (response['data'] as List)
        .map((json) => Supplier.fromJson(json))
        .toList();
  }

  @override
  Future<Supplier?> getSupplierById(String id) async {
    final response = await ApiClient.get('/suppliers/$id');
    return Supplier.fromJson(response['data']);
  }

  // Registers a new business partner as a supplier.
  @override
  Future<Supplier> createSupplier(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/suppliers', data);
    return Supplier.fromJson(response['data']);
  }

  @override
  Future<Supplier> updateSupplier(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/suppliers/$id', data);
    return Supplier.fromJson(response['data']);
  }

  // Deletes a supplier record from the system.
  @override
  Future<bool> deleteSupplier(String id) async {
    await ApiClient.delete('/suppliers/$id');
    return true;
  }

  @override
  Future<Map<String, dynamic>> getSupplierSummary() async {
    final response = await ApiClient.get('/suppliers/summary');
    return response['data'] as Map<String, dynamic>;
  }
}

