// ------------------------------------------------------------------------------
// File: login_screen.dart
// Purpose: Primary entry gate for authenticated system access.
// Rationale: Implements a high-security authentication interface with proactive 
//   network discovery and role-based redirect logic. Orchestrates 
//   environmental configuration and identity challenges.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Modern brand fonts
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // Feedback: Toast/Snack message system
import 'package:frontend/shared/main_shell.dart'; // Navigation: POS dashboard route
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity manager
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart'; // State: Alert manager
import 'package:frontend/features/auth/presentation/screens/register_screen.dart'; // Navigation: Registration route
import 'package:frontend/features/auth/presentation/screens/reset_password_screen.dart'; // Navigation: Forgot password route
import 'package:frontend/features/admin/presentation/screens/admin_shell.dart'; // Navigation: Admin panel route
import 'package:frontend/core/utils/phone_utils.dart'; // Utility: String normalization for phone numbers
import 'package:frontend/core/utils/validation_utils.dart'; // Utility: Regex form validators
import 'package:frontend/features/auth/presentation/screens/public_support_screen.dart'; // Navigation: Help desk route
import 'package:frontend/features/auth/presentation/widgets/auth_background.dart'; // Shared UI: Multi-layered background
import 'package:frontend/shared/widgets/backend_settings_dialog.dart'; // Shared UI: Network configuration overlay
import 'package:frontend/core/network/backend_discovery.dart'; // Logic: UDP server reachability tests
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: Base server IP access
import 'package:flutter/foundation.dart' show kIsWeb; // Utility: Web vs Mobile branching

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Form Orchestration ---
  final _formKey = GlobalKey<FormState>(); // Key: Links form state to validation logic
  final _emailController = TextEditingController(); // Input: Primary identifier (Email or Phone)
  final _passwordController = TextEditingController(); // Input: Secure credential
  bool _obscurePassword = true; // State: Local visibility toggle for security

  @override
  void dispose() {
    _emailController.dispose(); // Cleanup: Memory safety
    _passwordController.dispose();
    super.dispose();
  }

  /*
   * Logic: Integrated Authentication Flow.
   * Rationale: Executes a proactive 'Network Check' before transmitting credentials 
   * to minimize timeout wait times. Also handles role-based navigation and 
   * diagnostic error reporting.
   */
  void _login() async {
    // Stage A: Input Validation.
    if (!_formKey.currentState!.validate()) return;

    // Stage B: Network Resilience (Mobile-only).
    if (!kIsWeb) {
      // Step: Perform a low-latency "Ping" to the configured backend IP.
      final reachable = await BackendDiscovery.testConnection(ApiClient.serverIp);
      if (!reachable) {
        if (!mounted) return;
        // Optimization: Proactively show common connectivity fix if the server is dark.
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false); // State: Access identity commander
    final identifier = normalizePhoneNumber(_emailController.text.trim()); // Sanitize: Strip spaces/hyphens
    
    // Stage C: Backend Handshake.
    final success = await authProvider.login(
      identifier,
      _passwordController.text.trim(),
    );
    if (!mounted) return;

    // Stage D: Result Handling.
    if (success) {
      if (mounted) {
        // Trace: Log successful session start for auditing.
        context.read<NotificationProvider>().createNotification(
          type: 'success',
          title: 'Login Successful',
          message: 'Welcome back to ShopBook Owner Portal!',
        );
      }

      SnackBarUtils.showSnackBar(
        context,
        'Welcome back, ${authProvider.currentOwner?.shopName ?? authProvider.currentOwner?.name ?? 'Partner'}!',
      );
      
      // Stage E: High-level Routing.
      // Strategy: Isolation of concerns between 'System Admins' and 'Shop Owners'.
      if (authProvider.currentOwner?.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminShell()), // Route: System-wide control
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()), // Route: Daily retail operations
        );
      }
    } else {
      // Stage F: Advanced Diagnostics.
      // Rationale: Pass technicalDetails (e.g. HTTP 401) to support troubleshooting without cluttering the UI.
      SnackBarUtils.showSnackBar(
        context,
        authProvider.error ?? 'Login failed. Please check your credentials.',
        isError: true,
        technicalDetails: authProvider.technicalDetails,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Configuration: Icon Visibility Control ---
    // Change this to 'true' to re-activate the server connection settings icon.
    const bool showSettingsIcon = false;

    return AuthBackground(
      // --- Secret Developer Access ---
      // Rationale: Allows developers to configure the server via long-press on the logo.
      onLogoLongPress: () => showDialog(
        context: context,
        builder: (_) => const BackendSettingsDialog(),
      ),
      // --- Auxiliary Actions ---
      trailing: Visibility(
        visible: showSettingsIcon,
        child: IconButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const BackendSettingsDialog(),
          ),
          icon: Icon(
            Icons.settings_outlined, // Icon: Direct access to network config
            color: AppColors.textMedium.withValues(alpha: 0.5),
          ),
          tooltip: 'Connection Settings',
        ),
      ),
      child: Column(
        children: [
          // Headline: Primary UI greeting.
          Text(
            'Welcome Back!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          // Sub-headline: Mission statement.
          Text(
            'Sign in to manage your grocery store.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 20),
          
          // --- Credential Module ---
          // Rationale: Encapsulated GlassCard for visual prominence and input focus.
          GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Email or Phone'), // Label: Human identifier
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const ValueKey('email_field'),
                    controller: _emailController,
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration(
                      hintText: 'Enter your email or phone',
                      icon: Icons.mail_outline,
                    ),
                    validator: ValidationUtils.validateIdentifier, // Logic: Email/Phone Regex
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Password'), // Label: Shielded identifier
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const ValueKey('password_field'),
                    controller: _passwordController,
                    obscureText: _obscurePassword, // Logic: Toggleable obscuring
                    style: const TextStyle(color: AppColors.textDark),
                    decoration: _buildInputDecoration(
                      hintText: 'Enter your password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    validator: ValidationUtils.validatePassword, // Logic: Min length/Complexity check
                  ),
                  
                  // Recovery Action: Direct link to OTP-based password reset.
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResetPasswordScreen(),
                        ),
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Submit CTA ---
                  // Logic: Reactive button that displays a spinner during network transmission.
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _login, // Block: Prevent double-submission
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Login',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 20),
                                  ],
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

          // --- Alternative Options ---
          // Registration Route.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Not an owner yet? ',
                style: GoogleFonts.poppins(
                  color: AppColors.textMedium,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                ),
                child: Text(
                  'Apply for Partnership', 
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Support Link: Direct communication with system admins.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Having trouble? ',
                style: GoogleFonts.poppins(
                  color: AppColors.textMedium,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PublicSupportScreen(),
                  ),
                ),
                child: Text(
                  'Contact Admin',
                  style: GoogleFonts.poppins(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /*
   * UI Component: Section Label.
   * Rationale: Standardizes heading styles for input groups.
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
   * UI Component: Premium Input Decorator.
   * Rationale: Centrally manages the aesthetic design of all authentication fields.
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
        borderSide: const BorderSide(color: AppColors.primary, width: 2), // Focus: Highlight in brand color
      ),
      // Action: Password visibility toggle button.
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMedium.withValues(alpha: 0.6),
              ),
              onPressed: () => setState(
                () => _obscurePassword = !_obscurePassword,
              ),
            )
          : null,
    );
  }
}


