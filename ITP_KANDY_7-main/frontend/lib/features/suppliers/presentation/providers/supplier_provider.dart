// ------------------------------------------------------------------------------
// File: supplier_provider.dart
// Purpose: Supplier Lifecycle and Procurement Financial Governance.
// Rationale: Orchestrates the supplier ecosystem, tracking directory data, 
//   active procurement relationships, and aggregate "Total Payable" balances. 
//   Provides a centralized reactive state for supplier-side accounting.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // State: ChangeNotifier foundation
import 'package:frontend/core/error/exceptions.dart'; // Diagnostics: Structured error propagation
import 'package:frontend/features/suppliers/domain/entities/supplier.dart'; // Domain: Supplier model
import 'package:frontend/features/suppliers/data/repositories/supplier_repository_impl.dart'; // Data: Server communication
class SupplierProvider extends ChangeNotifier {
  final SupplierRepositoryImpl _repository = SupplierRepositoryImpl();

  List<Supplier> _suppliers = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _error;
  String? _technicalDetails;
  final int _pageSize = 20;

  double _totalPayable = 0;
  int _activeCount = 0;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get technicalDetails => _technicalDetails;

  double get totalPayable => _totalPayable;
  int get activeCount => _activeCount;

  // int get activeCount => _suppliers.where((s) => s.status == 'active').length;
  // double get totalPayable =>
  //     _suppliers.fold(0, (sum, s) => sum + s.totalPayable);

  /*
   * Logic: Supplier Directory Fetch.
   * Rationale: Synchronizes the local supplier list with the backend.
   */
  Future<void> fetchSuppliers({bool refresh = true}) async {
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
      // Logic: Parallel fetch from distinct domains (Directory & Summary).
      // Rationale: Reduces "Time to First Interactive" for the summary cards.
      final results = await Future.wait([
        _repository.getAllSuppliers(
          limit: _pageSize,
          lastId: refresh || _suppliers.isEmpty ? null : _suppliers.last.id,
        ),
        _repository.getSupplierSummary(),
      ]);

      final fetchedSuppliers = results[0] as List<Supplier>;
      final summary = results[1] as Map<String, dynamic>;

      _totalPayable = (summary['totalPayable'] as num?)?.toDouble() ?? 0.0;
      _activeCount = (summary['activeCount'] as num?)?.toInt() ?? 0;

      if (refresh) {
        _suppliers = fetchedSuppliers;
      } else {
        _suppliers.addAll(fetchedSuppliers);
      }

      _hasMore = fetchedSuppliers.length == _pageSize;
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
   * Logic: Partnership Onboarding.
   * Rationale: Registers a new supplier relationship in the system.
   */
  Future<bool> addSupplier(Map<String, dynamic> data) async {
    try {
      await _repository.createSupplier(data);
      await fetchSuppliers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Profile Update.
   * Rationale: Modifies existing supplier metadata and contact info.
   */
  Future<bool> updateSupplier(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateSupplier(id, data);
      await fetchSuppliers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Record Deletion.
   * Rationale: Removes a supplier profile from the active directory.
   */
  /*
   * Logic: Financial Summary Refresh.
   * Rationale: Lightweight update for "Total Payable" without reloading the directory.
   */
  Future<void> fetchSummary() async {
    try {
      final summary = await _repository.getSupplierSummary();
      _totalPayable = (summary['totalPayable'] as num?)?.toDouble() ?? 0.0;
      _activeCount = (summary['activeCount'] as num?)?.toInt() ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching supplier summary: $e');
    }
  }

  Future<bool> removeSupplier(String id) async {
    try {
      await _repository.deleteSupplier(id);
      await fetchSuppliers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

