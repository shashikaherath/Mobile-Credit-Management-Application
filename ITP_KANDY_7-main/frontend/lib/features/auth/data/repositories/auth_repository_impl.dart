// ------------------------------------------------------------------------------
// File: auth_repository_impl.dart
// Purpose: Identity Infrastructure Implementation.
// Rationale: Concrete adapter connecting the AuthRepository contract 
//   to the remote REST gateway. Manages the bidirectional mapping between 
//   domain-level entities and raw network JSON payloads.
// ------------------------------------------------------------------------------
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: Singleton for HTTP requests
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: Target data model
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart'; // Domain: Defined interface

class AuthRepositoryImpl implements AuthRepository {
  /**
   * Logic: Security Handshake.
   * Rationale: Transmits credentials to the '/auth/login' endpoint and hydrates the Owner entity from the 'data' payload.
   */
  @override
  Future<Owner> login(String identifier, String password) async {
    final response = await ApiClient.post('/auth/login', {
      'identifier': identifier, // Param: Email or authenticated phone number
      'password': password,
    });
    // Parsing: Convert the nested JSON data field into a type-safe Entity.
    return Owner.fromJson(response['data']);
  }

  /**
   * Logic: User Provisioning.
   * Rationale: Securely registers a new shop manager, automatically creating their store metadata on the server.
   */
  @override
  Future<Owner> register(Map<String, dynamic> data) async {
    final response = await ApiClient.post('/auth/register', data);
    return Owner.fromJson(response['data']);
  }

  /**
   * Logic: Profile Data Synchronization.
   * Rationale: Updates local context with fresh server-side attributes (e.g., status changes or branding updates).
   */
  @override
  Future<Owner?> getProfile(String id) async {
    final response = await ApiClient.get('/auth/profile/$id');
    return Owner.fromJson(response['data']);
  }

  /**
   * Logic: Partial Document Update.
   * Rationale: Optimizes data transfer by sending only modified fields (e.g., name, shopName) via a PUT request.
   */
  @override
  Future<Owner> updateProfile(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put('/auth/profile/$id', data);
    return Owner.fromJson(response['data']);
  }

  /**
   * Logic: Password Rotation.
   * Rationale: Enforces "Old Password" verification at the server level to prevent unauthorized credential theft.
   */
  @override
  Future<void> changePassword(
    String id,
    String oldPassword,
    String newPassword,
  ) async {
    await ApiClient.put('/auth/change-password/$id', {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  /**
   * Logic: Remote Identity Recovery.
   * Rationale: Finalizes the password reset flow after an external OTP verification has been performed.
   */
  @override
  Future<void> resetPassword(String identifier, String newPassword) async {
    await ApiClient.post('/auth/reset-password', {
      'identifier': identifier,
      'newPassword': newPassword,
    });
  }
}

