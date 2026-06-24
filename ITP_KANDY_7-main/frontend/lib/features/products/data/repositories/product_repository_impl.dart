// ------------------------------------------------------------------------------
// File: product_repository_impl.dart
// Purpose: Inventory Data Infrastructure Implementation.
// Rationale: Concrete adapter mapping Domain contracts to REST API endpoints. 
//   Handles high-fidelity JSON-to-entity transformation and cursor-based 
//   pagination for the /products resource.
// ------------------------------------------------------------------------------
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: HTTP engine
import 'package:frontend/features/products/domain/entities/product.dart'; // Domain: Entity
import 'package:frontend/features/products/domain/repositories/product_repository.dart'; // Domain: Contract

class ProductRepositoryImpl implements ProductRepository {
  /**
   * Logic: Paginated Product Listing.
   * Rationale: Uses cursor-based pagination (lastId) for scalable inventory loading.
   */
  @override
  Future<List<Product>> getAllProducts({int? limit, String? lastId}) async {
    final Map<String, String> queryParams = {};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (lastId != null) queryParams['lastId'] = lastId;

    final response = await ApiClient.get('/products', queryParameters: queryParams);
    final List data = response['data'];
    // Parsing: Convert raw JSON array into typed Product entities.
    return data.map((json) => Product.fromJson(json)).toList();
  }

  /**
   * Logic: Single Product Retrieval.
   * Rationale: Fetches full product details for edit screens and detail views.
   */
  @override
  Future<Product?> getProductById(String id) async {
    final response = await ApiClient.get('/products/$id');
    return Product.fromJson(response['data']);
  }

  /**
   * Logic: Inventory Registration.
   * Rationale: Persists a new product record from validated form data.
   */
  @override
  Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/products', data);
    return Product.fromJson(response['data']);
  }

  /**
   * Logic: Partial Product Update.
   * Rationale: Sends only modified fields to minimize network payload.
   */
  @override
  Future<Product> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/products/$id', data);
    return Product.fromJson(response['data']);
  }

  /**
   * Logic: Product Removal.
   * Rationale: Permanently deletes a product from the inventory database.
   */
  @override
  Future<bool> deleteProduct(String id) async {
    final response = await ApiClient.delete('/products/$id');
    return response['success'] ?? false;
  }
}

