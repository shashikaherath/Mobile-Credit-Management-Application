// ------------------------------------------------------------------------------
// File: public_support_screen.dart
// Purpose: Public Help Desk & Support Gateway.
// Rationale: Provides a unauthenticated channel for account recovery 
//   and troubleshooting. Includes biometric/OTP verification to 
//   prioritize urgent tickets for shop owners.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:flutter/foundation.dart' show kIsWeb; // Utility: Web vs Mobile branching
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // Feedback: Status message system
import 'package:frontend/core/utils/phone_utils.dart'; // Utility: Identifier normalization
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity manager
import 'package:frontend/features/account/presentation/providers/feedback_provider.dart'; // State: Support ticket manager
import 'package:frontend/features/auth/presentation/widgets/auth_background.dart'; // Shared UI: Branded background
import 'package:frontend/features/auth/presentation/screens/otp_verification_screen.dart'; // Navigation: Privacy/Security verification step
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: Base server access
import 'package:frontend/core/network/backend_discovery.dart'; // Logic: Server reachability tests
import 'package:frontend/shared/widgets/backend_settings_dialog.dart'; // Shared UI: Network setup
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger

class PublicSupportScreen extends StatefulWidget {
  const PublicSupportScreen({super.key});

  @override
  State<PublicSupportScreen> createState() => _PublicSupportScreenState();
}

class _PublicSupportScreenState extends State<PublicSupportScreen> {
  // --- Form Orchestration ---
  final _formKey = GlobalKey<FormState>(); // Key: Links form state to validation logic
  final _contactController = TextEditingController(); // Input: Target contact path
  final _shopNameController = TextEditingController(); // Input: Claimed business identity
  final _messageController = TextEditingController(); // Input: Narrative issue description
  
  // --- State Configuration ---
  String _selectedCategory = 'Account Recovery'; // Selection: High-level ticket grouping
  bool _isVerified = false; // Flag: Trusted identity indicator for admin prioritization
  final List<String> _categories = [
    'Account Recovery',
    'Password Reset Issue',
    'Login Trouble',
    'Other'
  ];

  @override
  void dispose() {
    _contactController.dispose(); // Cleanup: Memory safety
    _shopNameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /**
   * Logic: Priority-Elevation Verification.
   * Rationale: Allows users to "prove" they own the contact device via OTP.
   * Verified tickets are flagged on the Admin Panel for immediate attention.
   */
  void _verifyIdentity() async {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      SnackBarUtils.showSnackBar(context, 'Please enter your registered phone number first.', isError: true);
      return;
    }

    if (contact.contains('@')) {
      // Constraint: Email-based recovery currently lacks automated verification parity with SMS.
      SnackBarUtils.showSnackBar(context, 'Verification is currently supported via Phone Number only.', isError: true);
      return;
    }

    final normalizedPhone = normalizePhoneNumber(contact); // Sanitize: Strip spaces/hyphens
    final authProvider = context.read<AuthProvider>();

    // Step: Trigger the backend OTP verification handshake.
    await authProvider.requestBackendOtp(
      target: normalizedPhone,
      method: 'phone',
      onFailed: (error) {
        SnackBarUtils.showSnackBar(context, error, isError: true);
      },
      onCodeSent: () {
        // Step: Transition to secure OTP entry.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              target: normalizedPhone,
              onVerified: () {
                setState(() => _isVerified = true); // Strategy: Escalate ticket trust level.
                Navigator.pop(context); // Close OTP screen
                SnackBarUtils.showSnackBar(context, 'Identity Verified Successfully!');
              },
            ),
          ),
        );
      },
    );
  }

  /**
   * Logic: Support Ticket Submission.
   * Rationale: Transmits the unauthenticated request to the shared feedback ecosystem.
   */
  void _submit() async {
    // Stage A: Formal Validation.
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

    final feedbackProvider = context.read<FeedbackProvider>();
    
    // Stage C: Backend Transmission.
    final success = await feedbackProvider.submitPublicFeedback(
      category: _selectedCategory,
      message: _messageController.text.trim(),
      contactInfo: _contactController.text.trim(),
      claimedShopName: _shopNameController.text.trim(),
      isVerified: _isVerified, // Action: Communicate trust level to the admin panel.
    );

    if (!mounted) return;

    // Stage D: Result Handling.
    if (success) {
      // Step: Provide high-visual-impact success confirmation.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Request Submitted',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'An admin will review your request and contact you shortly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.textMedium),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to Login entry
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Login', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } else {
      // Step: Log failure with full architectural transparency.
      final feedbackProvider = context.read<FeedbackProvider>();
      SnackBarUtils.showSnackBar(
        context,
        feedbackProvider.error ?? 'Submission failed',
        isError: true,
        technicalDetails: feedbackProvider.technicalDetails,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showLogo: false, // Override: Uses high-density form verticality
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
          // Headline: Primary help intent.
          Text(
            'Contact Support',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          // Sub-headline: Brand reassurance.
          Text(
            'Tell us about your issue and we\'ll help you get back in.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 24),
          
          // --- Ticket Generation Module ---
          GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Issue Category'), // Input: Triage grouping
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: _buildInputDecoration(icon: Icons.category_outlined, hintText: ''),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Phone Number or Email'), // Input: Contact identifier
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _contactController,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration(
                      hintText: 'Enter registered contact',
                      icon: Icons.contact_mail_outlined,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Contact info is required' : null,
                  ),
                  
                  // Priority-Elevation CTA.
                  // Logic: Hidden once successfully verified to avoid redundant handshakes.
                  if (!_isVerified) 
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: _verifyIdentity,
                        icon: const Icon(Icons.verified_user_outlined, size: 16),
                        label: const Text('Verify Identity via OTP'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                        ),
                      ),
                    )
                  else
                    // Success Indicator: Trusted state representation.
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.green, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Identity Verified',
                            style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 20),

                  _buildLabel('Shop Name (Manual Proof)'), // Input: Account mapping
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _shopNameController,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration(
                      hintText: 'Enter your shop name',
                      icon: Icons.store_outlined,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Shop name is required' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Explain the Issue'), // Input: Contextual details
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration(
                      hintText: 'Describe what happened...',
                      icon: Icons.message_outlined,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Please describe your issue' : null,
                  ),
                  const SizedBox(height: 32),

                  // --- Submit Action ---
                  // Logic: Reactive CTA that displays a spinner during network transmission.
                  Consumer<FeedbackProvider>(
                    builder: (context, provider, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : _submit, // Block: Prevent double-submission
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: provider.isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Submit Request',
                                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
    );
  }
}

