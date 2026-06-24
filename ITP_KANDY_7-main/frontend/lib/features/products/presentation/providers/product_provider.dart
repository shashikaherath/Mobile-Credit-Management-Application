// ------------------------------------------------------------------------------
// File: product_provider.dart
// Purpose: Inventory Lifecycle and Stock Health Orchestration.
// Rationale: Manages the comprehensive product state including paginated data 
//   fetching, cloud-based media persistence (Cloudinary), and reactive stock 
//   health metrics for dashboard diagnostics.
// ------------------------------------------------------------------------------
import 'dart:typed_data'; // Infrastructure: Byte manipulation for Web blobs
import 'package:image_picker/image_picker.dart'; // Media: Local file selection
import 'package:flutter/material.dart'; // Core: Flutter reactive system
import 'package:cloudinary_public/cloudinary_public.dart'; // Cloud: Image storage API
import 'package:frontend/core/config/cloudinary_config.dart'; // Config: Cloud credentials
import 'package:frontend/core/error/exceptions.dart'; // Infrastructure: Custom exceptions
import 'package:frontend/features/products/domain/entities/product.dart'; // Domain: Entity
import 'package:frontend/features/products/data/repositories/product_repository_impl.dart'; // Data: Adapter
import 'package:frontend/core/network/api_client.dart'; // Network: API Client

class ProductProvider extends ChangeNotifier {
  final ProductRepositoryImpl _repository = ProductRepositoryImpl(); // Logic: Backend adapter

  // --- Reactive State ---
  List<Product> _products = []; // Cache: In-memory product list
  bool _isLoading = false; // Status: Initial load indicator
  bool _isFetchingMore = false; // Status: Pagination load indicator
  bool _hasMore = true; // Pagination: Whether more pages exist
  String? _error; // Feedback: User-facing error message
  String? _technicalDetails; // Diagnostics: Raw error detail for troubleshooting
  final int _pageSize = 20; // Config: Items per pagination page

  // --- Public Getters ---
  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get technicalDetails => _technicalDetails;

  // --- Derived Stock Health Metrics ---

  /// Returns only products flagged as critically low on stock by the backend.
  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();

  // Global stats fetched from dashboard endpoint to ensure accuracy during pagination
  int _globalTotalItemsInStock = 0;
  double _globalTotalInventoryValue = 0.0;
  
  /// Aggregates the total monetary value of all loaded inventory (global stat if available, fallback to loaded).
  double get totalInventoryValue => _globalTotalInventoryValue > 0
      ? _globalTotalInventoryValue
      : _products.fold(0.0, (sum, p) => sum + p.inventoryValue);
 
  /// Returns the total unit count across all products (global stat if available, fallback to loaded).
  int get totalItemsInStock => _globalTotalItemsInStock > 0 
      ? _globalTotalItemsInStock 
      : _products.fold(0, (sum, p) => sum + p.stockQuantity);
 
  /// Count of products below their minimum stock level (for dashboard badges).
  int get lowStockCount => _products.where((p) => p.isLowStock).length;
 
  /// Filtered list of products that need immediate reordering.
  List<Product> get lowStockItems => _products.where((p) => p.isLowStock).toList();

  /*
   * Logic: Paginated Product Fetch.
   * Rationale: Supports both initial load (refresh=true) and infinite scroll
   * (refresh=false) using cursor-based pagination via the lastId parameter.
   */
  Future<void> fetchProducts({bool refresh = true}) async {
    if (refresh) {
      // Logic: Only trigger the full-screen loading state if no products are cached.
      // Rationale: Prevents jarring UI jumps during pull-to-refresh.
      if (_products.isEmpty) {
        _isLoading = true;
      }
      _hasMore = true;
      _error = null;
      notifyListeners();
    } else if (!_hasMore || _isFetchingMore) {
      return;
    } else {
      _isFetchingMore = true;
      notifyListeners();
    }

    try {
      final lastId = !refresh && _products.isNotEmpty ? _products.last.id : null;
      final fetchedProducts = await _repository.getAllProducts(
        limit: _pageSize,
        lastId: lastId,
      );

      // Fetch global stats to ensure accuracy during pagination
      if (refresh) {
        try {
          final dashResult = await ApiClient.get('/dashboard');
          if (dashResult['data'] != null) {
            _globalTotalItemsInStock = dashResult['data']['totalItemsInStock'] ?? 0;
            _globalTotalInventoryValue = (dashResult['data']['totalInventoryValue'] ?? 0.0).toDouble();
          }
        } catch (_) {
          // Silent fallback
        }
      }

      if (refresh) {
        _products = fetchedProducts;
      } else {
        _products.addAll(fetchedProducts);
      }

      _hasMore = fetchedProducts.length == _pageSize;
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  /*
   * Logic: Cloud Image Upload Pipeline.
   * Rationale: Uploads product images to Cloudinary for CDN-backed delivery.
   * Returns the secure URL on success, or null on failure/missing config.
   */
  Future<String?> _uploadImage(XFile imageFile) async {
    if (CloudinaryConfig.cloudName.isEmpty ||
        CloudinaryConfig.uploadPreset.isEmpty) {
      debugPrint('Cloudinary config is missing. Skipping upload.');
      return null;
    }

    try {
      final cloudinary = CloudinaryPublic(
        CloudinaryConfig.cloudName,
        CloudinaryConfig.uploadPreset,
        cache: false, // Strategy: Disable caching for fresh uploads
      );

      final bytes = await imageFile.readAsBytes();

      // Transmission: Send to Cloudinary. For Web blobs, ensure a valid identifier.
      String fileName = imageFile.name;
      if (fileName.isEmpty || fileName == 'blob' || !fileName.contains('.')) {
        fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      final CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromByteData(
          ByteData.view(bytes.buffer),
          identifier: fileName,
          folder: 'products',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      debugPrint('❌ Cloudinary Upload Error: $e');
      _error = 'Image upload failed: $e';
      return null;
    }
  }

  /*
   * Logic: Product Creation Pipeline.
   * Rationale: Optionally uploads a product image before persisting the record,
   * then auto-refreshes the product list to reflect the addition.
   */
  Future<bool> createProduct(Map<String, dynamic> data, {XFile? imageFile}) async {
    try {
      if (imageFile != null) {
        final url = await _uploadImage(imageFile);
        if (url != null) {
          data['imageUrl'] = url;
        }
      }
      await _repository.createProduct(data);
      await fetchProducts(refresh: true); // Refresh: Mandatory full sync to prevent stale list appending
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Product Mutation Pipeline.
   * Rationale: Optionally replaces the product image before persisting updates,
   * then auto-refreshes to show the latest data.
   */
  Future<bool> updateProduct(String id, Map<String, dynamic> data, {XFile? imageFile}) async {
    try {
      if (imageFile != null) {
        final url = await _uploadImage(imageFile);
        if (url != null) {
          data['imageUrl'] = url;
        }
      }
      await _repository.updateProduct(id, data);
      await fetchProducts(refresh: true); // Refresh: Mandatory full sync to reflect modifications immediately
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Product Deletion Pipeline.
   * Rationale: Removes the product from the backend and auto-refreshes
   * the list to reflect the removal.
   */
  Future<bool> deleteProduct(String id) async {
    try {
      await _repository.deleteProduct(id);
      await fetchProducts(refresh: true); // Refresh: Mandatory full sync to remove deleted item from local cache
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

