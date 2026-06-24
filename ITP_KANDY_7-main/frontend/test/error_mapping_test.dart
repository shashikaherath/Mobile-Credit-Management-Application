// ──────────────────────────────────────────────────────────────────────────────
// File: error_mapping_test.dart
// Purpose: Unit tests for ApiClient's HTTP status code to internal exception mapping.
// Rationale: Ensures that the networking layer correctly translates backend errors
//   (401, 403, 404, 429, 500) into domain-specific exceptions for unified 
//   transparent error reporting in the UI.
// ──────────────────────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart'; // Core Flutter testing framework
import 'package:http/http.dart' as http; // Library for mocking HTTP responses
import 'package:frontend/core/network/api_client.dart'; // The class under test (handles errors)
import 'package:frontend/core/error/exceptions.dart'; // Custom exceptions we expect to find

void main() {
  group('ApiClient Error Mapping Tests', () {
    // Ensures that a 401 Unauthorized status is correctly converted to our login exception
    test('should map 401 to AuthException', () {
      final response = http.Response('{"error": "Unauthorized access"}', 401); // Mock server response
      final exception = ApiClient.handleError(response); // Run the mapping logic
      
      expect(exception, isA<AuthException>()); // Verify the exception type
      expect(exception.toString(), contains('Unauthorized access')); // Verify message content
    });

    // Ensures that a 403 Forbidden status is correctly mapped
    test('should map 403 to ForbiddenException', () {
      final response = http.Response('{"error": "Forbidden"}', 403);
      final exception = ApiClient.handleError(response);
      
      expect(exception, isA<ForbiddenException>());
    });

    // Ensures that a 404 Not Found status is correctly mapped
    test('should map 404 to NotFoundException', () {
      final response = http.Response('{"error": "Not Found"}', 404);
      final exception = ApiClient.handleError(response);
      
      expect(exception, isA<NotFoundException>());
    });

    // Ensures that a 500 Internal Server Error is handled correctly
    test('should map 500 to ServerException', () {
      final response = http.Response('{"error": "Internal Error"}', 500);
      final exception = ApiClient.handleError(response);
      
      expect(exception, isA<ServerException>());
    });

    // Specifically checks for resource exhaustion (rate limit/quota) in the error string
    test('should detect Quota Exceeded and map to QuotaExceededException', () {
      // String matches typical MongoDB Atlas / Google Cloud quota errors
      final response = http.Response('{"error": "RESOURCE_EXHAUSTED: Quota exceeded"}', 429);
      final exception = ApiClient.handleError(response);
      
      expect(exception, isA<QuotaExceededException>());
    });

    // Verifies that the app doesn't crash if the server returns non-JSON data
    test('should use default message if JSON is malformed', () {
      final response = http.Response('Invalid JSON', 400); // Badly formatted response
      final exception = ApiClient.handleError(response);
      
      expect(exception, isA<ValidationException>());
      expect(exception.toString(), 'Invalid input. Please check your data.'); // Uses fallback message
    });
  });
}
