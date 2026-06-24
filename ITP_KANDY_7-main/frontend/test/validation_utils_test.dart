// ──────────────────────────────────────────────────────────────────────────────
// File: validation_utils_test.dart
// Purpose: Unit tests for form input validation logic.
// Rationale: Rigorously verifies regex patterns and business rules for emails, 
//   passwords, and phone numbers, ensuring that invalid data is caught at the 
//   UI level before reaching the networking layer.
// ──────────────────────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart'; // Core Flutter library for unit testing
import 'package:frontend/core/utils/validation_utils.dart'; // The utility class being verified

void main() {
  group('ValidationUtils Tests', () {
    // Confirms that valid Gmail addresses (case-insensitive) are accepted
    test('validateEmail - valid gmail', () {
      expect(ValidationUtils.validateEmail('test@gmail.com'), null); // Success case
      expect(ValidationUtils.validateEmail('TEST@GMAIL.COM'), null); // Case-insensitive check
    });

    // Ensures that non-Gmail domains are correctly rejected per business rules
    test('validateEmail - invalid email', () {
      expect(ValidationUtils.validateEmail('test@yahoo.com'), 'Email must end with @gmail.com');
      expect(ValidationUtils.validateEmail('test@hotmail.com'), 'Email must end with @gmail.com');
    });

    // Validates that email is an optional field (empty is okay)
    test('validateEmail - optional', () {
      expect(ValidationUtils.validateEmail(''), null); // Empty string is valid (optional field)
      expect(ValidationUtils.validateEmail(null), null); // Null is valid (optional field)
    });

    // Tests standard local phone number format
    test('validatePhone - valid starts with 0', () {
      expect(ValidationUtils.validatePhone('0771234567'), null); // Standard 10-digit local
    });

    // Tests international phone number format
    test('validatePhone - valid starts with +94', () {
      expect(ValidationUtils.validatePhone('+94771234567'), null); // Standard 12-character intl
    });

    // Ensures phone numbers are exactly 10 (local) or 12 (intl) characters long
    test('validatePhone - invalid length', () {
      expect(ValidationUtils.validatePhone('077123456'), 'Phone number must have 9 digits after 0 (e.g. 0771234567)');
      expect(ValidationUtils.validatePhone('07712345678'), 'Phone number must have 9 digits after 0 (e.g. 0771234567)');
      expect(ValidationUtils.validatePhone('+9477123456'), 'Phone number must have 9 digits after +94 (e.g. +94771234567)');
    });

    // Verifies that phone number is a mandatory field
    test('validatePhone - required', () {
      expect(ValidationUtils.validatePhone(''), 'Phone number is required');
      expect(ValidationUtils.validatePhone(null), 'Phone number is required');
    });

    // Checks that a minimum of 8 characters exists for password security
    test('validatePassword - valid', () {
      expect(ValidationUtils.validatePassword('password123'), null); // Meets length req
    });

    // Ensures short passwords are caught by the validator
    test('validatePassword - invalid length', () {
      expect(ValidationUtils.validatePassword('pass'), 'Password must be at least 8 characters');
    });

    // Tests generic required field logic with a custom name
    test('validateRequired - valid', () {
      expect(ValidationUtils.validateRequired('Store Name', 'Shop Name'), null);
    });

    // Ensures generic required validation triggers for empty input
    test('validateRequired - invalid', () {
      expect(ValidationUtils.validateRequired('', 'Shop Name'), 'Shop Name is required');
    });
  });
}
