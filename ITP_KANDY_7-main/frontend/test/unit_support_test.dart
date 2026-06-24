// ──────────────────────────────────────────────────────────────────────────────
// File: unit_support_test.dart
// Purpose: Unit tests for product measurement unit assignment and fallbacks.
// Rationale: Ensures that every product has a valid measurement unit (kg, ea, etc.), 
//   including correct default assignment ('ea') when data is missing, to prevent 
//   UI inconsistencies in sales and inventory reporting.
// ──────────────────────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart'; // Core testing library for Flutter unit tests
import 'package:frontend/features/products/domain/entities/product.dart'; // The product entity being tested

void main() {
  group('Product Unit Support Tests', () {
    // Verifies that the 'unit' field (e.g., kg, liters) is correctly assigned via the constructor
    test('Product should correctly store and retrieve unit', () {
      final product = Product(
        id: '1',
        name: 'Rice',
        description: 'Basmati Rice',
        category: 'Grains & Staples',
        sellingPrice: 120.0,
        stockQuantity: 50,
        minimumStockLevel: 5,
        unit: 'kg', // Testing with 'kilogram'
      );

      expect(product.unit, 'kg'); // Verify the stored value matches
    });

    // Ensures that the 'unit' field survives the round-trip from JSON to object and back
    test('Product JSON serialization should include unit', () {
      final json = {
        'id': '2',
        'name': 'Bread',
        'description': 'White Bread',
        'category': 'Bakery',
        'sellingPrice': 60.0,
        'stockQuantity': 10,
        'minimumStockLevel': 2,
        'unit': 'items', // Testing with a custom unit name
      };

      final product = Product.fromJson(json); // Map -> Object
      expect(product.unit, 'items');

      final backToJson = product.toJson(); // Object -> Map
      expect(backToJson['unit'], 'items'); // Verify serialization consistency
    });

    // Validates that if the unit is missing from the database, it defaults to 'each' (ea)
    test('Product default unit should be ea if not specified', () {
      final json = {
        'id': '3',
        'name': 'Apple',
        'description': 'Red Apple',
        'category': 'Fruits',
        'sellingPrice': 30.0,
        'stockQuantity': 100,
        'minimumStockLevel': 10,
        // The 'unit' key is omitted here on purpose
      };

      final product = Product.fromJson(json); // Conversion should inject default
      expect(product.unit, 'ea'); // 'ea' is the internal fallback for missing units
    });
  });
}
