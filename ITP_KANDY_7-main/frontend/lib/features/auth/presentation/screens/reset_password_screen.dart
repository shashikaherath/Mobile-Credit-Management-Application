// ------------------------------------------------------------------------------
// File: reset_password_screen.dart
// Purpose: Secure Credential Recovery and Identity Verification.
// Rationale: Implements a high-security recovery flow that utilizes 
//   verified SMS handshakes before allowing password mutation to 
//   preemptively prevent account hijacking.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:flutter/foundation.dart' show kIsWeb; // Utility: Web vs Mobile branching
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // Feedback: Status message system
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity manager
import 'package:frontend/features/auth/presentation/screens/otp_verification_screen.dart'; // Navigation: Security verification step
import 'package:frontend/core/utils/phone_utils.dart'; // Utility: Identifier normalization
import 'package:frontend/core/utils/validation_utils.dart'; // Utility: Form regex engines
import 'package:frontend/features/auth/presentation/widgets/auth_background.dart'; // Shared UI: Branded background
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: Base server access
import 'package:frontend/core/network/backend_discovery.dart'; // Logic: Server reachability tests
import 'package:frontend/shared/widgets/backend_settings_dialog.dart'; // Shared UI: Network setup
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // --- Form Orchestration ---
  final _formKey = GlobalKey<FormState>(); // Key: Links form state to validation logic
  final _identifierController = TextEditingController(); // Input: Target account identifier
  final _passwordController = TextEditingController(); // Input: New secure credential
  final _confirmPasswordController = TextEditingController(); // Input: Credential verification
  bool _obscurePassword = true; // State: Visibility toggle for security

  @override
  void dispose() {
    _identifierController.dispose(); // Cleanup: Memory safety
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /**
   * Logic: Secure Reset Handshake.
   * Rationale: Executes a multi-factor verification flow. 
   * The actual password update only occurs in the onVerified callback of the OTP screen.
   */
  void _resetPassword() async {
    // Stage A: Form Validation.
    if (!_formKey.currentState!.validate()) return;

    // Stage B: Network Resilience (Mobile-only).
    if (!kIsWeb) {
      final reachable = await BackendDiscovery.testConnection(ApiClient.serverIp);
      if (!reachable) {
        if (!mounted) return;
        SnackBarUtils.showSnackBar(
          context,
          'Cannot reach the server. Please check your connection settings.',
          isError: true,
        );
        // Disabled: Dialog should only open via 10-second logo long-press.
        // showDialog(
        //   context: context,
        //   builder: (_) => const BackendSettingsDialog(),
        // );
        return;
      }
    }
    if (!mounted) return;

    // Stage C: Cross-field Integrity.
    if (_passwordController.text != _confirmPasswordController.text) {
      SnackBarUtils.showSnackBar(
        context,
        'Passwords do not match',
        isError: true,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final identifier = _identifierController.text.trim();
    
    // Stage D: Identifier Parsing.
    String phone;
    if (identifier.contains('@')) {
      // Constraint: Email-based reset is currently restricted to ensure SMS parity for all owners.
      SnackBarUtils.showSnackBar(
        context,
        'Please enter your registered phone number for verification.',
        isError: true,
      );
      return;
    } else {
      phone = normalizePhoneNumber(identifier); // Sanitize: Strip spaces/hyphens
    }

    // Stage E: Identity Verification (OTP).
    // Rationale: Migrated to backend-driven OTP for consistency and cost optimization.
    await authProvider.requestBackendOtp(
      target: phone,
      method: 'phone', // Defaulting to phone for now in this screen
      onFailed: (error) {
        SnackBarUtils.showSnackBar(context, error, isError: true);
      },
      onCodeSent: () {
        // Step: Transition to secure OTP entry.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              target: phone, // Updated: Uses 'target' instead of 'phoneNumber'
              onVerified: () async {
                // Stage F: Atomic Password Update.
                final success = await authProvider.resetPassword(
                  phone,
                  _passwordController.text.trim(),
                );

                if (!context.mounted) return;

                if (success) {
                  SnackBarUtils.showSnackBar(
                    context,
                    'Password reset successfully! Please login with your new password.',
                  );
                  // Sequence: Clear the recovery stack and return the user to the Login screen.
                  Navigator.pop(context); // Close OTP screen
                  Navigator.pop(context); // Close Reset screen
                }
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showLogo: true, // Branding: Establish trust during security operations
      leading: AppBackButton(
        onTap: () => Navigator.pop(context),
        margin: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      ),
      // --- Configuration: Icon Visibility Control ---
      // Toggle 'visible' to true to re-activate the server connection settings.
      trailing: Visibility(
        visible: false,
        child: IconButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const BackendSettingsDialog(),
          ),
          icon: Icon(
            Icons.settings_outlined,
            color: AppColors.textMedium.withValues(alpha: 0.5),
          ),
          tooltip: 'Connection Settings',
        ),
      ),
      child: Column(
        children: [
          // Headline: Primary recovery intent.
          Text(
            'Reset Password',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          // Sub-headline: Process expectation.
          Text(
            'Follow the steps to secure your account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 32),
          
          // --- Recovery Form Module ---
          GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Phone Number'), // Input: Human identifier
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration(
                      hintText: 'Enter registered phone',
                      icon: Icons.phone_outlined,
                    ),
                    validator: ValidationUtils.validateIdentifier,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('New Password'), // Input: Secure credential setup
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration(
                      hintText: 'Min 8 characters',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    validator: ValidationUtils.validatePassword,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Confirm Password'), // Input: Consistency check
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration(
                      hintText: 'Re-enter new password',
                      icon: Icons.lock_reset,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please confirm your password';
                      if (value != _passwordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // --- Submit CTA ---
                  // Logic: Reactive button that displays a spinner during network transmission.
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _resetPassword, // Block: Prevent double-submission
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Confirm Reset',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /**
   * UI Component: Section Label.
   */
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textDark.withValues(alpha: 0.9),
      ),
    );
  }

  /**
   * UI Component: Unified Input Decoration.
   */
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textLight),
      prefixIcon: Icon(icon, color: AppColors.textMedium.withValues(alpha: 0.6)),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2), // Focus: Brand highlight
      ),
      // Action: Password visibility toggle.
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMedium.withValues(alpha: 0.6),
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
    );
  }
}


