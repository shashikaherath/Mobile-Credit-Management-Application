// ──────────────────────────────────────────────────────────────────────────────
// File: purchase_test.dart
// Purpose: Unit tests for the Purchase domain entity serialization.
// Rationale: Validates the JSON mapping logic for complex purchase objects, 
//   ensuring optional fields (notes) and data integrity are preserved between 
//   the REST API and local state models.
// ──────────────────────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart'; // Core testing library for standard Flutter unit tests
import 'package:frontend/features/suppliers/domain/entities/purchase.dart'; // The entity model being tested

void main() {
  group('Purchase Entity', () {
    // Tests that optional 'notes' are correctly converted from a JSON map to an object
    test('should parse notes from JSON', () {
      final json = {
        'id': '1',
        'supplierId': 's1',
        'supplierName': 'Supplier 1',
        'invoiceNumber': 'INV-001',
        'purchaseDate': '2023-10-01',
        'items': [],
        'subtotal': 100.0,
        'tax': 10.0,
        'totalAmount': 110.0,
        'amountPaid': 110.0,
        'remaining': 0.0,
        'status': 'paid',
        'notes': 'Test notes', // Field under test
        'createdAt': '2023-10-01T00:00:00Z',
      };

      final purchase = Purchase.fromJson(json); // Convert JSON map to object

      expect(purchase.notes, 'Test notes'); // Verify the notes exist on the object
    });

    // Tests the reverse process: converting an object back to a JSON map
    test('should convert notes to JSON', () {
      final purchase = Purchase(
        id: '1',
        supplierId: 's1',
        supplierName: 'Supplier 1',
        notes: 'Test notes',
      );

      final json = purchase.toJson(); // Convert object to map

      expect(json['notes'], 'Test notes'); // Verify the map contains the correct data
    });

    // Ensures the app provides a safe default if the server doesn't send 'notes'
    test('should default notes to empty string if not provided in JSON', () {
      final json = {
        'id': '1',
        'supplierId': 's1', // Missing 'notes' field entirely
      };

      final purchase = Purchase.fromJson(json);

      expect(purchase.notes, ''); // Expect an empty string instead of null to prevent UI crashes
    });
  });
}
