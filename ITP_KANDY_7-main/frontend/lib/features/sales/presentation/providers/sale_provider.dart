// ------------------------------------------------------------------------------
// File: sale_provider.dart
// Purpose: Transaction Lifecycle and Real-time Cart Governance.
// Rationale: Orchestrates the end-to-end POS workflow, including cart 
//   orchestration, stock ceiling enforcement, paginated transaction history, 
//   and backend finalization for secure inventory decrementing.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter reactive system
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: HTTP engine
import 'package:frontend/core/error/exceptions.dart'; // Infrastructure: Custom exceptions
import 'package:frontend/features/products/domain/entities/product.dart'; // Domain: Product entity

class SaleProvider extends ChangeNotifier {
  // --- Reactive State ---
  List<Product> _products = []; // Cache: Products available for sale selection
  List<dynamic> _sales = []; // Cache: Completed sales history
  final List<Map<String, dynamic>> _cartItems = []; // Session: Active shopping cart line items
  bool _isLoading = false; // Status: Global busy indicator
  bool _isFetchingMore = false; // Status: Pagination load indicator
  bool _hasMore = true; // Pagination: Whether more sales pages exist
  String? _error; // Feedback: User-facing error message
  String? _technicalDetails; // Diagnostics: Raw error detail for troubleshooting
  static const int _pageSize = 20; // Config: Items per pagination page

  // --- Public Getters ---
  List<Product> get products => _products;
  List<dynamic> get sales => _sales;
  List<Map<String, dynamic>> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get technicalDetails => _technicalDetails;

  // --- Derived Cart Metrics ---

  /// Calculates the running total of all items in the cart (price × quantity).
  double get subtotal => _cartItems.fold(
    0,
    (sum, item) => sum + (item['price'] as num).toDouble() * (item['quantity'] as int),
  );

  /// Alias: Total amount equals subtotal (no tax/discount layer currently).
  double get totalAmount => subtotal;

  /// Counts the total number of individual units across all cart line items.
  int get totalItems =>
      _cartItems.fold(0, (sum, item) => sum + (item['quantity'] as int));

  /*
   * Logic: Product Catalog Fetch.
   * Rationale: Loads the full product list for the sale selection grid.
   */
  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiClient.get('/products');
      _products = (response['data'] as List)
          .map((json) => Product.fromJson(json))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  /*
   * Logic: Paginated Sales History Fetch.
   * Rationale: Supports both initial load and infinite scroll via cursor-based pagination.
   */
  Future<void> fetchSales({bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
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
      final Map<String, String> params = {'limit': _pageSize.toString()};
      if (!refresh && _sales.isNotEmpty) {
        params['lastId'] = _sales.last['id'].toString();
      }

      final response = await ApiClient.get('/sales', queryParameters: params);
      final List fetchedSales = response['data'] as List;

      if (refresh) {
        _sales = fetchedSales;
      } else {
        _sales.addAll(fetchedSales);
      }

      _hasMore = fetchedSales.length == _pageSize;
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  /*
   * Logic: Customer-Scoped Sales History.
   * Rationale: Fetches sales filtered by a specific customer ID for credit/debt views.
   */
  Future<void> fetchSalesByCustomer(String customerId, {bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
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
      final Map<String, String> params = {'limit': _pageSize.toString()};
      if (!refresh && _sales.isNotEmpty) {
        params['lastId'] = _sales.last['id'].toString();
      }

      final response = await ApiClient.get('/sales/customer/$customerId', queryParameters: params);
      final List fetchedSales = response['data'] as List;

      if (refresh) {
        _sales = fetchedSales;
      } else {
        _sales.addAll(fetchedSales);
      }

      _hasMore = fetchedSales.length == _pageSize;
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  /*
   * Logic: Cart Item Addition with Stock Enforcement.
   * Rationale: Prevents overselling by enforcing real-time stock limits
   * and throwing AppException when stock is exhausted.
   */
  void addToCart(Product product) {
    // Step 1: Check if this product is already in the cart.
    final existingIndex = _cartItems.indexWhere(
      (item) => item['productId'] == product.id,
    );

    if (existingIndex >= 0) {
      // Step 2: Increment quantity if stock allows.
      final currentQty = _cartItems[existingIndex]['quantity'] as int;
      if (currentQty < product.stockQuantity) {
        _cartItems[existingIndex]['quantity'] = currentQty + 1;
      } else {
        // Guard: Prevent overselling beyond available inventory.
        throw AppException('Stock limit reached for ${product.name}');
      }
    } else {
      // Step 3: Add as a new line item if stock is available.
      if (product.stockQuantity > 0) {
        _cartItems.add({
          'productId': product.id,
          'name': product.name,
          'price': product.sellingPrice,
          'quantity': 1,
          'unit': product.unit,
          'stockQuantity': product.stockQuantity, // Reference: For local limit checks
        });
      } else {
        throw AppException('${product.name} is out of stock');
      }
    }
    notifyListeners();
  }

  /// Removes a cart line item by its index position.
  void removeFromCart(int index) {
    _cartItems.removeAt(index);
    notifyListeners();
  }

  /*
   * Logic: Cart Quantity Mutation.
   * Rationale: Updates a line item's quantity, auto-removing if reduced to zero.
   * Enforces stock ceiling to prevent overselling.
   */
  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      _cartItems.removeAt(index);
    } else {
      final item = _cartItems[index];
      final stockPerItem = item['stockQuantity'] as int;
      if (quantity <= stockPerItem) {
        _cartItems[index]['quantity'] = quantity;
      }
    }
    notifyListeners();
  }

  /*
   * Logic: Transaction Finalization.
   * Rationale: Submits the cart payload to the backend, which records the sale,
   * decrements stock, and returns the receipt data for invoice generation.
   */
  Future<Map<String, dynamic>?> completeSale({
    String? id,
    String paymentMethod = 'cash',
    String customerId = '',
    String customerName = '',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Network: POST the cart contents to finalize the transaction.
      final response = await ApiClient.post('/sales', {
        'id': id,
        'items': _cartItems,
        'subtotal': subtotal,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'customerId': customerId,
        'customerName': customerName,
      });

      _cartItems.clear(); // Cleanup: Reset cart after successful submission.
      _isLoading = false;
      
      notifyListeners();
      return response['data'] as Map<String, dynamic>?;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /*
   * Logic: Sale Reversal.
   * Rationale: Deletes a sale record and refreshes both sales history and
   * product inventory to reflect the stock restoration.
   */
  Future<void> deleteSale(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
      await ApiClient.delete('/sales/$id');
      await fetchSales();
      await fetchProducts(); // Refresh: Restore reverted stock quantities
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Utility: Empties the shopping cart without network interaction.
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}

