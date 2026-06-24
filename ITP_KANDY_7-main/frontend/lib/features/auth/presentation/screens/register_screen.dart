// ------------------------------------------------------------------------------
// File: register_screen.dart
// Purpose: Multi-step Partner Onboarding Orchestration.
// Rationale: Manages the complex registration pipeline, ensuring data 
//   integrity via proximity availability checks, OTP security verification, 
//   and formal legal documentation consent before persistence.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:flutter/gestures.dart'; // Interaction: RichText tap detection
import 'package:flutter/foundation.dart' show kIsWeb; // Utility: Web vs Mobile branching
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // Feedback: Status message system
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity manager
import 'package:frontend/core/utils/phone_utils.dart'; // Utility: Identifier normalization
import 'package:frontend/core/utils/validation_utils.dart'; // Utility: Form regex engines
import 'package:frontend/features/auth/presentation/screens/otp_verification_screen.dart'; // Navigation: Security verification step
import 'package:frontend/features/account/presentation/screens/terms_conditions_screen.dart'; // Navigation: Legal documentation
import 'package:frontend/features/account/presentation/screens/privacy_policy_screen.dart'; // Navigation: Privacy compliance
import 'package:frontend/features/auth/presentation/widgets/auth_background.dart'; // Shared UI: Branded background
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: Base server access
import 'package:frontend/core/network/backend_discovery.dart'; // Logic: Server reachability tests
import 'package:frontend/shared/widgets/backend_settings_dialog.dart'; // Shared UI: Network setup
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- Form Orchestration ---
  final _formKey = GlobalKey<FormState>(); // Key: Links form state to validation logic
  final _nameController = TextEditingController(); // Input: Legal name
  final _shopNameController = TextEditingController(); // Input: Business identity
  final _phoneController = TextEditingController(); // Input: Primary secure identifier
  final _emailController = TextEditingController(); // Input: Communication identifier
  final _passwordController = TextEditingController(); // Input: Access credential
  bool _obscurePassword = true; // State: Visibility toggle for security
  bool _agreedToTerms = false; // State: Legal consent flag
  String _verificationMethod = 'phone'; // State: OTP delivery channel (phone or email)

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+94'; // Preset: Optimization for local region (Sri Lanka)
  }

  @override
  void dispose() {
    _nameController.dispose(); // Cleanup: Memory safety
    _shopNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /*
   * Logic: Integrated Registration Pipeline.
   * Rationale: Executes a proactive 'Availability Check' before initiating 
   * expensive SMS costs. Only proceeds to OTP if the identifier is unique 
   * and the server is reachable.
   */
  void _register() async {
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

    // Stage C: Legal Compliance.
    if (!_agreedToTerms) {
      SnackBarUtils.showSnackBar(
        context,
        'Please agree to the Terms of Service',
        isError: true,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phone = normalizePhoneNumber(_phoneController.text.trim()); // Sanitize: Strip spaces/hyphens
    final email = _emailController.text.trim();

    // Stage D: Proactive Collision Detection.
    // Optimization: Block duplicate accounts before the user enters the verification phase.
    final isAvailable = await authProvider.checkAvailability(
      phone: phone,
      email: email.isNotEmpty ? email : null,
    );

    if (!isAvailable) {
      if (!mounted) return;
      SnackBarUtils.showSnackBar(
        context,
        authProvider.error ?? 'Account already exists with these details',
        isError: true,
        technicalDetails: authProvider.technicalDetails,
      );
      return;
    }

    // Stage E: Identity Verification (OTP).
    // Rationale: Uses the backend to generate a code for the selected channel.
    final target = _verificationMethod == 'phone' ? phone : email;
    
    if (_verificationMethod == 'email' && email.isEmpty) {
      if (!mounted) return;
      SnackBarUtils.showSnackBar(context, 'Please enter an email for verification', isError: true);
      return;
    }

    await authProvider.requestBackendOtp(
      target: target,
      method: _verificationMethod,
      onFailed: (error) {
        if (!context.mounted) return;
        SnackBarUtils.showSnackBar(
          context,
          error,
          isError: true,
          technicalDetails: context.read<AuthProvider>().technicalDetails,
        );
      },
      onCodeSent: () {
        // Step: Transition to secure OTP entry.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              target: target, // Updated: Uses 'target' instead of 'phoneNumber'
              onVerified: () async {
                final navigator = Navigator.of(context);
                
                // Stage F: Final Backend Persistence.
                final success = await authProvider.register({
                  'name': _nameController.text.trim(),
                  'shopName': _shopNameController.text.trim(),
                  'phone': phone,
                  'email': email,
                  'password': _passwordController.text.trim(),
                });

                if (!mounted) return;

                if (success) {
                  if (!context.mounted) return;
                  SnackBarUtils.showSnackBar(
                    context,
                    'Account created successfully! Please log in to continue.',
                  );
                  // Action: Redirect back to Login screen (Root) as requested.
                  navigator.popUntil((route) => route.isFirst);
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
          // Headline: Primary onboarding intent.
          Text(
            'Create Account',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          // Sub-headline: Value proposition.
          Text(
            'Join the ShopBook owner community today.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 20),
          
          // --- Multi-Step Form Module ---
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Owner Name'), // Input: Human identity
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration('Enter your full name', Icons.person_outline),
                    validator: (v) => ValidationUtils.validateRequired(v, 'Owner name'),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Shop Name'), // Input: Business identity
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _shopNameController,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration('Enter your shop name', Icons.store_outlined),
                    validator: (v) => ValidationUtils.validateRequired(v, 'Shop name'),
                  ),
                  const SizedBox(height: 20),

                  // --- Verification Method Selection ---
                  _buildLabel('Verification Method'),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'phone',
                          label: Text('Phone'),
                          icon: Icon(Icons.phone_android),
                        ),
                        ButtonSegment(
                          value: 'email',
                          label: Text('Email'),
                          icon: Icon(Icons.email_outlined),
                        ),
                      ],
                      selected: {_verificationMethod},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _verificationMethod = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        side: WidgetStateProperty.all(BorderSide(color: AppColors.primary.withValues(alpha: 0.2))),
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary.withValues(alpha: 0.1);
                          }
                          return Colors.transparent;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return AppColors.textMedium;
                        }),
                      ),
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Phone Number'), // Input: Identity anchor
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration('Enter phone number', Icons.phone_outlined),
                    validator: ValidationUtils.validatePhone, // Logic: International format regex
                  ),
                  const SizedBox(height: 20),

                  // Optional Field labeling.
                  Row(
                    children: [
                      _buildLabel('Email'),
                      const SizedBox(width: 8),
                      Text(
                        'OPTIONAL',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textLight.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration('Enter email (optional)', Icons.mail_outline),
                    validator: ValidationUtils.validateEmail,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Password'), // Input: Credential setup
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration(
                      'Create a strong password',
                      Icons.lock_outline,
                      isPassword: true,
                    ),
                    validator: ValidationUtils.validatePassword,
                  ),
                  const SizedBox(height: 16),

                  // --- Legal Acknowledgement ---
                  // Strategy: Physically block the CTA until the user interacts with the terms checkbox.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                          activeColor: AppColors.primary,
                          side: BorderSide(color: AppColors.textMedium.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textMedium,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              // Interactive link to Terms document.
                              TextSpan(
                                text: 'Terms',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsConditionsScreen())),
                              ),
                              const TextSpan(text: ' and '),
                              // Interactive link to Privacy document.
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Submit Action ---
                  // Logic: Reactive CTA that triggers the multi-step verification sequence.
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _register,
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
                                  'Register Account',
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
          
          const SizedBox(height: 20),

          // Utility: Back-to-login routing.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: GoogleFonts.poppins(color: AppColors.textMedium),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Log In',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /*
   * UI Component: Input Label.
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

  /*
   * UI Component: Unified Input Decoration.
   */
  InputDecoration _buildInputDecoration(String hintText, IconData icon, {bool isPassword = false}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.textMedium.withValues(alpha: 0.6), size: 20),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      // Action: Secure toggle for password fields.
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textMedium.withValues(alpha: 0.6),
                size: 20,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
    );
  }
}


