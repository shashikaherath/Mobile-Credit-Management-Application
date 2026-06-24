// ------------------------------------------------------------------------------
// File: phone_auth_service.dart
// Purpose: Identity Verification and SMS Authentication Provider.
// Rationale: Wraps the Firebase Auth identity system to provide a robust 
//   phone-based login flow. Orchestrates number normalization, automated 
//   OTP retrieval, and secure session handshakes.
// ------------------------------------------------------------------------------
import 'package:firebase_auth/firebase_auth.dart'; // Core: Firebase identity management
import 'dart:async'; // Enables asynchronous workflow control

class PhoneAuthService {
  // Instance: The centralized gateway to Firebase Authentication services.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /**
   * Logic: SMS Dispatcher.
   * Initiates the multi-step handshake with Firebase to send a verification code.
   * Rationale: Securely identifies the user without requiring a password.
   */
  Future<void> verifyPhoneNumber({
    required String phoneNumber, // Target: The E.164 formatted number (e.g., +94...)
    required Function(String verificationId, int? resendToken) onCodeSent, // Event: Save the ID for later entry
    required Function(FirebaseAuthException e) onVerificationFailed, // Fault: Handles invalid numbers or quota blocks
    required Function(PhoneAuthCredential credential) onVerificationCompleted, // Event: SMS auto-read success
    required Function(String verificationId) onCodeAutoRetrievalTimeout, // Event: 60s timeout fallback
    int? forceResendingToken, // Strategy: Bypasses wait times for a fresh SMS request
  }) async {
    // Action: Request Firebase to send the verification SMS.
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber, // Target recipient
      verificationCompleted: onVerificationCompleted, // Logic: Auto-verification (common on Android)
      verificationFailed: onVerificationFailed, // Logic: Error reporting (e.g. invalid formatting)
      codeSent: onCodeSent, // Strategy: Provides the ID needed for manual code entry
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout, // Guard: Triggered when the app stops listening for SMS
      forceResendingToken: forceResendingToken, // Optimization: Overrides the built-in delay if user requests retry
      timeout: const Duration(seconds: 60), // Constraint: The window for automatic SMS interception
    );
  }

  /**
   * Logic: Credential Generator.
   * Transforms raw user input (6-digit code) and verification ID into a secure login token.
   */
  Future<PhoneAuthCredential> getCredential({
    required String verificationId, // Context: The unique ID from the dispatch phase
    required String smsCode, // Input: The code the user typed from their SMS message
  }) async {
    // Mapping: Pair the server-side session ID with the client-side user code.
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  /**
   * Logic: Session Finalizer.
   * Submits the generated credential to Firebase to create a logged-in user session.
   */
  Future<UserCredential> signInWithCredential(PhoneAuthCredential credential) async {
    // Authority: Finalizes the authentication and returns the User object.
    return await _auth.signInWithCredential(credential);
  }
}

