// ------------------------------------------------------------------------------
// File: validation_utils.dart
// Purpose: Deterministic Data Integrity and Business Rule Enforcement.
// Rationale: Centrally orchestrates the logic for verifying user inputs across
//   all system modules. Ensures that only sanitized and valid data is
//   persisted to local state or transmitted to the backend, preventing
//   runtime inconsistencies and financial data corruption.
// ------------------------------------------------------------------------------
class ValidationUtils {
  /*
   * Logic: Domain-Specific Email Validator.
   * Rationale: Limits account registration to @gmail.com domains to simplify 
   *   administrative support and ensure standardized identity providers.
   */
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Logic: Email is often optional in profile/owner contexts
    }
    final trimmed = value.trim(); // Cleanup: Remove leading/trailing whitespace
    if (!trimmed.toLowerCase().endsWith('@gmail.com')) {
      return 'Email must end with @gmail.com'; // Constraint: Specific domain enforcement
    }
    return null; // Success: Input meets requirements
  }

  /*
   * Logic: Polymorphic Login Identifier Validator.
   * Rationale: Dynamically determines authentication strategy by parsing 
   *   the input signature (Email vs Phone).
   */
  static String? validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or Phone is required'; // Constraint: Mandatory login field
    }
    final trimmed = value.trim();
    if (trimmed.contains('@')) {
      return validateEmail(trimmed); // Strategy: Delegate to email logic
    } else {
      return validatePhone(trimmed); // Strategy: Delegate to phone logic
    }
  }

  /*
   * Logic: Regional Phone Validator (Sri Lanka).
   * Rationale: Enforces strict adherence to local (07...) and 
   *   international (+94...) formats to ensure SMS deliverability.
   */
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required'; // Constraint: Mandatory for SMS-auth
    }
    final trimmed = value.trim();

    // RegEx: Starts with 0 and followed by 9 decimals.
    final zeroPattern = RegExp(r'^0[0-9]{9}$');
    // RegEx: Starts with +94 and followed by 9 decimals.
    final intlPattern = RegExp(r'^\+94[0-9]{9}$');

    if (trimmed.startsWith('0')) {
      if (!zeroPattern.hasMatch(trimmed)) {
        return 'Phone number must have 9 digits after 0 (e.g. 0771234567)';
      }
    } else if (trimmed.startsWith('+94')) {
      if (!intlPattern.hasMatch(trimmed)) {
        return 'Phone number must have 9 digits after +94 (e.g. +94771234567)';
      }
    } else {
      // Constraint: Reject numbers from unsupported regions or invalid formats.
      return 'Phone number must start with 0 or +94';
    }

    return null;
  }

  /*
   * Logic: Data Security Guard (Entropy Check).
   * Rationale: Enforces a minimum length of 8 characters to mitigate 
   *   brute-force vulnerabilities.
   */
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required'; // Constraint: Mandatory security field
    }
    if (value.trim().length < 8) {
      return 'Password must be at least 8 characters'; // Constraint: Minimum length rule
    }
    return null;
  }

  /*
   * Logic: Global Null/Empty Triage.
   * Rationale: Generic validator for mandatory fields that do not 
   *   require complex pattern matching.
   */
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required'; // Dynamic: Custom error based on field role
    }
    return null;
  }

  /*
   * Logic: Identity Validation.
   * Rationale: Enforces a minimum length of 3 characters for names (Customers/Suppliers)
   *   to prevent data ambiguity and accidental single-character entries.
   */
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 3) {
      return '$fieldName must be at least 3 characters';
    }
    return null;
  }

  /*
   * Logic: Financial Data Consistency (Price).
   * Rationale: Prevents zero-value or negative item definitions to ensure 
   *   accurate accounting across Sales and Purchase modules.
   */
  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required'; // Constraint: Mandatory for products/orders
    }
    final price = double.tryParse(value); // Attempt: Convert to decimal
    if (price == null || price <= 0) {
      return 'Enter a valid price greater than 0'; // Constraint: Prevent zero/negative pricing
    }
    return null;
  }

  /*
   * Logic: Inventory Data Consistency (Stock).
   * Rationale: Enforces non-negative integer counts for warehouse auditing.
   */
  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock level is required'; // Constraint: Mandatory inventory field
    }
    final stock = int.tryParse(value); // Attempt: Convert to whole number
    if (stock == null || stock < 0) {
      return 'Enter a valid non-negative number'; // Rationale: 0 stock is valid (out of stock)
    }
    return null;
  }
}
