// ------------------------------------------------------------------------------
// File: product_repository.dart
// Purpose: Inventory Management and CRUD Contract.
// Rationale: Defines the architectural blueprint for all shop inventory 
//   operations. Decouples business logic from the specific REST gateway, 
//   facilitating mock-based testing and future data source expansion.
// ------------------------------------------------------------------------------
import 'package:frontend/features/products/domain/entities/product.dart'; // Domain: Entity

abstract class ProductRepository {
  /// Paginated Fetch: Retrieves a batch of products, optionally resuming from [lastId].
  Future<List<Product>> getAllProducts({int? limit, String? lastId});

  /// Single Fetch: Retrieves a specific product by its database ID.
  Future<Product?> getProductById(String id);

  /// Creation: Persists a new product record from raw form data.
  Future<Product> createProduct(Map<String, dynamic> data);

  /// Mutation: Updates an existing product's attributes.
  Future<Product> updateProduct(String id, Map<String, dynamic> data);

  /// Destruction: Removes a product from the inventory database.
  Future<bool> deleteProduct(String id);
}

