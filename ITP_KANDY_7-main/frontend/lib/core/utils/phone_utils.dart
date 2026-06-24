// ------------------------------------------------------------------------------
// File: phone_utils.dart
// Purpose: Regional Phone Normalization and E.164 Transformation.
// Rationale: Standardizes local Sri Lankan phone numbers for backend and 
//   SMS gateway compatibility. Ensures that local "07..." inputs are 
//   accurately converted to the international "+94..." format required 
//   for secure cloud authentication.
// ------------------------------------------------------------------------------

/**
 * Logic: Normalization Engine.
 * Replaces the local leading zero with the international country code.
 */
String normalizePhoneNumber(String phone) {
  final trimmed = phone.trim(); // Cleanup: Discard accidental whitespace
  
  // Strategy: Identify local 10-digit format starting with '0'.
  if (trimmed.startsWith('0') && trimmed.length == 10) {
    // Implementation: Strip the '0' and prepend the +94 country code.
    return '+94${trimmed.substring(1)}'; 
  }
  
  // Fallback: Return as-is if already normalized or in an unrecognized format.
  return trimmed; 
}

