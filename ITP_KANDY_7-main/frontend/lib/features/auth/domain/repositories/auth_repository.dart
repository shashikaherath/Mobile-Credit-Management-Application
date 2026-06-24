// ------------------------------------------------------------------------------
// File: auth_repository.dart
// Purpose: Identity and Session Management Contract.
// Rationale: Defines the architectural blueprint for all shop owner 
//   authentication operations. Decouples core business logic from 
//   specific data sources, promoting high testability and flexibility.
// ------------------------------------------------------------------------------
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: The target entity

abstract class AuthRepository {
  /**
   * Logic: Credential Verification.
   * Rationale: Securely pends email/password to the backend and retrieves the session Owner.
   */
  Future<Owner> login(String email, String password);

  /**
   * Logic: Identity Creation.
   * Rationale: Handles the multi-step registration process, converting raw form data into an Owner entity.
   */
  Future<Owner> register(Map<String, dynamic> data);

  /**
   * Logic: Identity Synchronization.
   * Rationale: Fetches the latest authorized profile details to refresh local state.
   */
  Future<Owner?> getProfile(String id);

  /**
   * Logic: Profile Evolution.
   * Rationale: Persists modifications to the user's profile (e.g., shop name, email) back to the server.
   */
  Future<Owner> updateProfile(String id, Map<String, dynamic> data);

  /**
   * Logic: Secure Credential Rotation.
   * Rationale: Verifies the legacy password before allowing the generation of a new hash.
   */
  Future<void> changePassword(
    String id,
    String oldPassword,
    String newPassword,
  );

  /**
   * Logic: Remote Credential Reset.
   * Rationale: Allows account recovery via identifier-based override (used after OTP verification).
   */
  Future<void> resetPassword(String identifier, String newPassword);
}

