// ──────────────────────────────────────────────────────────────────────────────
// File: phone_normalization_test.dart
// Purpose: Unit tests for phone number formatting and internationalization.
// Rationale: Ensures consistent local-to-international (+94) conversion for 
//   Sri Lankan numbers, which is critical for unique customer identification, 
//   authentication, and cross-module consistency.
// ──────────────────────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart'; // Core testing library for Flutter
import 'package:frontend/core/utils/phone_utils.dart'; // The normalization tool being tested

void main() {
  group('PhoneNumber Normalization Tests', () {
    // Tests the primary conversion use case for local Sri Lankan numbers
    test('Should convert 0... format to +94...', () {
      expect(normalizePhoneNumber('0712345678'), '+94712345678'); // Standard mobile
      expect(normalizePhoneNumber('0771234567'), '+94771234567'); // Dialogue mobile
      expect(normalizePhoneNumber('0112345678'), '+94112345678'); // Fixed line (Colombo)
    });

    // Ensures that valid international numbers remain untouched
    test('Should keep +94 format as is', () {
      expect(normalizePhoneNumber('+94712345678'), '+94712345678'); // Already international
    });

    // Verifies that accidental spaces from user input are ignored
    test('Should trim whitespace', () {
      expect(normalizePhoneNumber(' 0712345678 '), '+94712345678'); // Padded local
      expect(normalizePhoneNumber(' +94712345678 '), '+94712345678'); // Padded international
    });

    // Validates edges cases where the input doesn't follow the 10-digit local pattern
    test('Should return original if not matching 0... (10 digits) pattern', () {
      expect(normalizePhoneNumber('071234567'), '071234567'); // Too short (9 digits)
      expect(normalizePhoneNumber('07123456789'), '07123456789'); // Too long (11 digits)
      expect(normalizePhoneNumber('1712345678'), '1712345678'); // Starts with 1 (not 0)
      expect(normalizePhoneNumber('abc'), 'abc'); // Text input
    });
  });
}
