// ------------------------------------------------------------------------------
// File: purchase_provider.dart
// Purpose: Procurement Lifecycle and Inventory Inflow Governance.
// Rationale: Centralizes the management of supplier purchase records, 
//   facilitating restock history audits, supplier-scoped transaction queries, 
//   and debt settlement finalization. Supports optimistic UI updates.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // State: ChangeNotifier foundation
import 'package:frontend/features/suppliers/domain/entities/purchase.dart'; // Domain: Purchase model
import 'package:frontend/features/suppliers/data/repositories/purchase_repository_impl.dart'; // Data: Server communication
class PurchaseProvider extends ChangeNotifier {
  final PurchaseRepositoryImpl _repository = PurchaseRepositoryImpl();

  List<Purchase> _purchases = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _error;
  final int _pageSize = 20;

  List<Purchase> get purchases => _purchases;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  /*
   * Logic: Global Purchase Feed.
   * Rationale: Loads a paginated list of all procurement entries in the system.
   */
  Future<void> fetchPurchases({bool refresh = true}) async {
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
      final lastId = !refresh && _purchases.isNotEmpty ? _purchases.last.id : null;
      final fetchedPurchases = await _repository.getAllPurchases(
        limit: _pageSize,
        lastId: lastId,
      );

      if (refresh) {
        _purchases = fetchedPurchases;
      } else {
        _purchases.addAll(fetchedPurchases);
      }

      _hasMore = fetchedPurchases.length == _pageSize;
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
   * Logic: Supplier-Scoped Ledger.
   * Rationale: Loads procurement history specific to a single supplier profile.
   */
  Future<void> fetchPurchasesBySupplier(String supplierId, {bool refresh = true}) async {
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
      final lastId = !refresh && _purchases.isNotEmpty ? _purchases.last.id : null;
      final fetchedPurchases = await _repository.getPurchasesBySupplier(
        supplierId,
        limit: _pageSize,
        lastId: lastId,
      );

      if (refresh) {
        _purchases = fetchedPurchases;
      } else {
        _purchases.addAll(fetchedPurchases);
      }

      _hasMore = fetchedPurchases.length == _pageSize;
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
   * Logic: Single Purchase Detail Fetch.
   * Rationale: The list query excludes items for performance. This fetches the
   *   full purchase record (including line items) for the detail view.
   */
  Future<Purchase?> fetchPurchaseById(String id) async {
    try {
      return await _repository.getPurchaseById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /*
   * Logic: Purchase finalization.
   * Rationale: Records a new procurement event and triggers stock inflow logic.
   */
  Future<bool> addPurchase(Map<String, dynamic> data) async {
    try {
      await _repository.createPurchase(data);
      await fetchPurchases();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePurchase(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updatePurchase(id, data);
      await fetchPurchases();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePurchase(String id) async {
    try {
      await _repository.deletePurchase(id);
      await fetchPurchases();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Debt Reconciliation.
   * Rationale: Finalizes financial settlement for an outstanding purchase record.
   */
  Future<Purchase?> settlePurchase(String id) async {
    try {
      final updatedPurchase = await _repository.settlePurchase(id);
      if (updatedPurchase != null) {
        // Update local state without fetching all
        final index = _purchases.indexWhere((p) => p.id == id);
        if (index != -1) {
          _purchases[index] = updatedPurchase;
          notifyListeners();
        }
      }
      return updatedPurchase;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}

