/**
 * Error Layer: Custom Application Exceptions.
 * Defines a structural hierarchy for all error states within the ShopBook app.
 * Each exception type maps to a specific technical failure or business logic violation.
 */

/// Root Exception: The base class for all custom errors in ShopBook.
/// Inherits from standard Exception to ensure compatibility with try-catch blocks.
class AppException implements Exception {
  final String message; // UI: User-friendly description of what went wrong
  final String? code; // Technical: Unique identifier for programmatic handling (e.g., 'AUTH_ERROR')
  final String? details; // Diagnostic: Detailed raw error or stack trace for the "DETAILS" dialog

  AppException(this.message, [this.code, this.details]);

  @override
  String toString() => message; // Default: Return the readable message if printed to console
}

/// Category: Network Failures.
/// Triggered when the device is offline, a DNS lookup fails, or a socket times out.
class NetworkException extends AppException {
  NetworkException([String? message, String? details])
      : super(
          message ?? 'No internet connection. Please check your network settings.', // Fallback hint
          'NETWORK_ERROR', // Standard code
          details, // Raw socket/timeout info
        );
}

/// Category: Server-Side Faults (5xx).
/// Triggered when the backend crashes or enters an unstable state.
class ServerException extends AppException {
  ServerException([String? message, String? details])
      : super(
          message ?? 'Server error. Our team has been notified.', // Generic assurance
          'SERVER_ERROR', // Standard code
          details, // Raw backend stack trace
        );
}

/// Category: Authentication Failures (401).
/// Triggered when JWT tokens expire, credentials are invalid, or sessions are revoked.
class AuthException extends AppException {
  AuthException([String? message, String? details])
      : super(
          message ?? 'Your session has expired. Please log in again.', // Call to action
          'AUTH_ERROR', // Standard code
          details, // Auth state specifics
        );
}

/// Category: Authorization Denied (403).
/// Triggered when a non-admin attempts to access restricted dashboard features.
class ForbiddenException extends AppException {
  ForbiddenException([String? message, String? details])
      : super(
          message ?? "You don't have permission to perform this action.", // Restrictive message
          'FORBIDDEN_ERROR', // Standard code
          details, // Role mismatch details
        );
}

/// Category: Data Not Found (404).
/// Triggered when requesting a product, customer, or owner that no longer exists in MongoDB.
class NotFoundException extends AppException {
  NotFoundException([String? message, String? details])
      : super(
          message ?? 'The requested resource was not found.', // Informative message
          'NOT_FOUND_ERROR', // Standard code
          details, // Resource ID info
        );
}

/// Category: User Input Errors (400).
/// Triggered when forms fail validation (e.g., duplicate product codes, invalid phone numbers).
class ValidationException extends AppException {
  ValidationException([String? message, String? details])
      : super(
          message ?? 'Invalid input. Please check your data.', // Correction hint
          'VALIDATION_ERROR', // Standard code
          details, // Specific field failures
        );
}

/// Category: Infrastructure Limits.
/// Specific to MongoDB Atlas or Firebase quota exhaustion (common in development/free tiers).
class QuotaExceededException extends AppException {
  QuotaExceededException([String? message, String? details])
      : super(
          message ?? 'Cloud Database Quota Exhausted. Please try again tomorrow.', // Limit info
          'QUOTA_EXHAUSTED', // Standard code
          details, // Usage stats from backend
        );
}

