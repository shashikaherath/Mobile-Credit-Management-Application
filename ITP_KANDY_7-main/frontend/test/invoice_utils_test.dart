// ──────────────────────────────────────────────────────────────────────────────
// File: invoice_utils_test.dart
// Purpose: Unit tests for invoice ID sanitisation and formatting.
// Rationale: Validates the logic for converting raw server IDs into filesystem-safe
//   filenames for PDF exports, ensuring cross-platform stability (slash handling)
//   and reliability for offline invoice management.
// ──────────────────────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart'; // Standard Flutter unit testing library
import 'package:frontend/features/sales/presentation/utils/invoice_pdf_utils.dart'; // The utility class being tested

void main() {
  group('InvoicePdfUtils.getSanitizedInvoiceId', () {
    // Verifies that slashes are replaced with underscores for filesystem safety
    test('should return sanitized ID when "id" is present', () {
      final saleDetails = {'id': 'inv/123/abc'}; // Raw ID from server
      final result = InvoicePdfUtils.getSanitizedInvoiceId(saleDetails); // Run cleaner
      expect(result, 'INV_123_ABC'); // Expected safe filename part
    });

    // Ensures the function checks alternative MongoDB-style ID fields
    test('should fallback to "_id" when "id" is missing', () {
      final saleDetails = {'_id': 'mongo_567'}; // Database ID format
      final result = InvoicePdfUtils.getSanitizedInvoiceId(saleDetails);
      expect(result, 'MONGO_567');
    });

    // Prevents crashes if a sale object is malformed or empty
    test('should return "UNKNOWN" when no ID is present', () {
      final saleDetails = <String, dynamic>{}; // No ID fields at all
      final result = InvoicePdfUtils.getSanitizedInvoiceId(saleDetails);
      expect(result, 'UNKNOWN'); // Default fallback value
    });

    // Checks both forward and backward slashes for cross-platform compatibility
    test('should handle both types of slashes', () {
      final saleDetails = {'id': r'a/b\c'}; // Mixed path separators
      final result = InvoicePdfUtils.getSanitizedInvoiceId(saleDetails);
      expect(result, 'A_B_C'); // Both should be converted to underscores
    });

    // Ensures generated filenames are consistent in capitalization
    test('should convert to uppercase', () {
      final saleDetails = {'id': 'lower_case_id'}; 
      final result = InvoicePdfUtils.getSanitizedInvoiceId(saleDetails);
      expect(result, 'LOWER_CASE_ID'); // Verify uppercase conversion
    });
  });
}
