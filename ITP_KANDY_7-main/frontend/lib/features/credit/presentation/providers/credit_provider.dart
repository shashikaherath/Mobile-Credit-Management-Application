// ------------------------------------------------------------------------------
// File: credit_provider.dart
// Purpose: Customer Account Lifecycle and Debt Governance.
// Rationale: Orchestrates customer identity management, credit limit 
//   monitoring, and transparent debt/payment tracking. Centralizes CRUD 
//   operations and surfaces structured AppException diagnostics for robust 
//   financial error reporting.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // State: ChangeNotifier foundation
import 'package:frontend/core/error/exceptions.dart'; // Diagnostics: Structured error propagation
import 'package:frontend/features/credit/domain/entities/customer.dart'; // Domain: Customer profile entity
import 'package:frontend/features/credit/domain/entities/credit_transaction.dart'; // Domain: Ledger entry model
import 'package:frontend/features/credit/data/repositories/credit_repository_impl.dart'; // Data: Server communication
class CreditProvider extends ChangeNotifier {
  final CreditRepositoryImpl _repository = CreditRepositoryImpl();

  List<Customer> _customers = []; // The complete list of shop customers
  List<CreditTransaction> _transactions = []; // History of debts and payments for a selected customer
  bool _isLoading = false;
  bool _isFetchingMoreTransactions = false;
  bool _hasMoreTransactions = true;
  bool _isFetchingMoreCustomers = false;
  bool _hasMoreCustomers = true;
  bool _shouldOpenAddCustomer = false;
  String? _error;
  String? _technicalDetails;
  static const int _pageSize = 20;

  List<Customer> get customers => _customers;
  List<CreditTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isFetchingMoreTransactions => _isFetchingMoreTransactions;
  bool get hasMoreTransactions => _hasMoreTransactions;
  bool get isFetchingMoreCustomers => _isFetchingMoreCustomers;
  bool get hasMoreCustomers => _hasMoreCustomers;
  String? get error => _error;
  String? get technicalDetails => _technicalDetails;
  bool get shouldOpenAddCustomer => _shouldOpenAddCustomer;

  double get totalOutstanding =>
      _customers.fold(0, (sum, c) => sum + c.totalOutstanding);
  int get activeCredits =>
      _customers.where((c) => c.totalOutstanding > 0).length;

  List<Customer> get outstandingCustomers =>
      _customers.where((c) => c.totalOutstanding > 0).toList();
  List<Customer> get settledCustomers =>
      _customers.where((c) => c.totalOutstanding <= 0).toList();

  /*
   * Logic: Customer Registry Fetch.
   * Rationale: Loads paginated customer profiles from the backend.
   */
  Future<void> fetchCustomers({bool refresh = true}) async {
    if (refresh) {
      if (_customers.isEmpty) {
        _isLoading = true;
      }
      _hasMoreCustomers = true;
      _error = null;
      notifyListeners();
    } else if (!_hasMoreCustomers || _isFetchingMoreCustomers) {
      return;
    } else {
      _isFetchingMoreCustomers = true;
      notifyListeners();
    }

    try {
      final fetchedCustomers = await _repository.getAllCustomers(
        limit: _pageSize,
        lastId: refresh || _customers.isEmpty ? null : _customers.last.id,
      );

      if (refresh) {
        _customers = fetchedCustomers;
      } else {
        _customers.addAll(fetchedCustomers);
      }

      _hasMoreCustomers = fetchedCustomers.length == _pageSize;
      _isLoading = false;
      _isFetchingMoreCustomers = false;
      notifyListeners();
    } catch (e) {
      if (e is AppException) {
        _error = e.message;
        _technicalDetails = e.details;
      } else {
        _error = e.toString();
      }
      _isLoading = false;
      _isFetchingMoreCustomers = false;
      _isFetchingMoreTransactions = false;
      notifyListeners();
      if (e is! AppException) rethrow;
    }
  }

  Future<void> fetchTransactions(String customerId, {bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
      _hasMoreTransactions = true;
      _error = null;
      notifyListeners();
    } else if (!_hasMoreTransactions || _isFetchingMoreTransactions) {
      return;
    } else {
      _isFetchingMoreTransactions = true;
      notifyListeners();
    }

    try {
      final fetchedTransactions = await _repository.getTransactionsByCustomer(
        customerId,
        limit: _pageSize,
        lastId: refresh || _transactions.isEmpty ? null : _transactions.last.id,
      );

      if (refresh) {
        _transactions = fetchedTransactions;
      } else {
        _transactions.addAll(fetchedTransactions);
      }

      _hasMoreTransactions = fetchedTransactions.length == _pageSize;
      _isLoading = false;
      _isFetchingMoreTransactions = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _isFetchingMoreTransactions = false;
      notifyListeners();
    }
  }

  /*
   * Logic: Customer Registration.
   * Rationale: Onboards a new customer profile into the system.
   */
  Future<bool> addCustomer(Map<String, dynamic> data) async {
    try {
      await _repository.createCustomer(data);
      await fetchCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setShouldOpenAddCustomer(bool value) {
    _shouldOpenAddCustomer = value;
    notifyListeners();
  }

  /*
   * Logic: Profile Update.
   * Rationale: Modifies existing customer metadata (name, phone, address).
   */
  Future<bool> updateCustomer(String id, Map<String, dynamic> data) async {
    try {
      await _repository.updateCustomer(id, data);
      await fetchCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Record Deletion.
   * Rationale: Removes a customer profile from the registry.
   */
  Future<bool> deleteCustomer(String id) async {
    try {
      final success = await _repository.deleteCustomer(id);
      if (success) {
        await fetchCustomers();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Debt Reversal / Mutation.
   * Rationale: Directly creates a credit transaction entry.
   */
  Future<bool> addTransaction(Map<String, dynamic> data) async {
    try {
      await _repository.createTransaction(data);
      // After adding a transaction, refresh the customer data too as their balance changed
      await fetchCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /*
   * Logic: Debt Settle / Payment Entry.
   * Rationale: Records a financial payment against a customer's loan balance.
   */
  Future<void> settleFullBalance(Customer customer) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Step 1: Fetch the ABSOLUTE latest customer data to ensure we have the correct balance.
      final latestCustomer = await _repository.getCustomerById(customer.id);
      if (latestCustomer == null || latestCustomer.totalOutstanding <= 0) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Step 2: Create a Sale record with paymentMethod: 'settlement'
      // This will automatically update customer balance and create a credit transaction record in the backend.
      await _repository.createSettlementSale({
        'customerId': latestCustomer.id,
        'customerName': latestCustomer.name,
        'items': [], // Settlement invoice doesn't have product items
        'subtotal': latestCustomer.totalOutstanding,
        'totalAmount': latestCustomer.totalOutstanding,
        'paymentMethod': 'settlement',
      });

      // Step 3: Refresh local data
      await fetchCustomers();
      await fetchTransactions(latestCustomer.id);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}

