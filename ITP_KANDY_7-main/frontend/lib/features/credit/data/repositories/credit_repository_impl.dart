// ------------------------------------------------------------------------------
// File: credit_repository_impl.dart
// Purpose: Concrete implementation of credit data operations via REST API.
// Rationale: Translates domain-level CRUD operations for customers and credit
//   transactions into HTTP calls via ApiClient, with JSON deserialization
//   back into domain entities.
// ------------------------------------------------------------------------------
import 'package:frontend/core/network/api_client.dart'; // Network: HTTP request dispatch
import 'package:frontend/features/credit/domain/entities/customer.dart'; // Domain: Customer model
import 'package:frontend/features/credit/domain/entities/credit_transaction.dart'; // Domain: Ledger entry model
class CreditRepositoryImpl {
  // Customer methods
  // Lists all customers in the system by fetching them from the backend.
  Future<List<Customer>> getAllCustomers({int? limit, String? lastId}) async {
    final Map<String, String> queryParams = {};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (lastId != null) queryParams['lastId'] = lastId;

    final response = await ApiClient.get(
      '/customers',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return (response['data'] as List)
        .map((json) => Customer.fromJson(json))
        .toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final response = await ApiClient.get('/customers/$id');
    return Customer.fromJson(response['data']);
  }

  // Adds a new customer profile to the database.
  Future<Customer> createCustomer(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/customers', data);
    return Customer.fromJson(response['data']);
  }

  Future<Customer> updateCustomer(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/customers/$id', data);
    return Customer.fromJson(response['data']);
  }

  Future<bool> deleteCustomer(String id) async {
    final response = await ApiClient.delete('/customers/$id');
    return response['success'] == true;
  }

  // Credit Transaction methods
  // Fetches a list of all credit-related transactions (debt/payments) for a customer (supports pagination).
  Future<List<CreditTransaction>> getTransactionsByCustomer(
    String customerId, {
    int? limit,
    String? lastId,
  }) async {
    final Map<String, String> queryParams = {};
    if (limit != null) queryParams['limit'] = limit.toString();
    if (lastId != null) queryParams['lastId'] = lastId;

    final response = await ApiClient.get(
      '/credit-transactions/customer/$customerId',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return (response['data'] as List)
        .map((json) => CreditTransaction.fromJson(json))
        .toList();
  }

  // Records a new credit or payment transaction for a customer.
  Future<CreditTransaction> createTransaction(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/credit-transactions', data);
    return CreditTransaction.fromJson(response['data']);
  }

  // Sales methods (for credit history)
  // Removed getSalesByCustomer as we now use SaleProvider directly.
  
  // Creates a settlement sale record in the system.
  Future<Map<String, dynamic>> createSettlementSale(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/sales', data);
    return response['data'] as Map<String, dynamic>;
  }
}

