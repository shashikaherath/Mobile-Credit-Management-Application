// ------------------------------------------------------------------------------
// File: get_started_screen.dart
// Purpose: Primary Onboarding and Acquisition Gateway.
// Rationale: High-impact marketing layout designed to convert new users 
//   into registered owners. Provides clear value propositions and 
//   low-friction navigation into the authentication flow.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Modern brand fonts
import 'package:animate_do/animate_do.dart'; // Animations: Declarative entry sequences
import 'package:shared_preferences/shared_preferences.dart'; // Logic: Local preference persistence
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/features/auth/presentation/screens/login_screen.dart'; // Navigation: Success target
import 'package:frontend/features/auth/presentation/widgets/auth_background.dart'; // Shared UI: Multi-layered background

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  /**
   * Logic: Onboarding Completion.
   * Rationale: Marks the user as 'onboarded' in local storage so they skip this screen on future app boots.
   */
  Future<void> _completeGetStarted(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance(); // Protocol: Access persistent memory
    await prefs.setBool('has_seen_get_started', true); // Side Effect: Mutate the first-run flag
    
    if (context.mounted) {
      // Transition: Replace current route with Login to prevent 'back' navigation to onboarding.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showLogo: true, // Config: Enable the standard ShopBook branding overlay
      child: Column(
        children: [
          const SizedBox(height: 8),
          // --- Visual Header ---
          // Rationale: Drops the central illustration into view for a dynamic feel.
          FadeInDown(
            duration: const Duration(milliseconds: 1000),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05), // Visual: Subtle brand highlight
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/get_started.png', // Asset: Custom thematic store graphic
                  height: 160,
                  width: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.storefront_outlined, // Fallback: Maintain UI integrity if image fails
                    size: 100,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // --- Promotional Content ---
          // Rationale: Rises up from the bottom to meet the header, creating a "joining" animation.
          FadeInUp(
            duration: const Duration(milliseconds: 1000),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Headline: Direct benefit statement.
                  Text(
                    'Elevate Your Store\'s Success',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Body: Elaborated value proposition.
                  Text(
                    "The ultimate dashboard for the modern shop owner. Seamlessly track inventory, accelerate sales, and unlock your business's full potential.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppColors.textMedium,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // --- Main Action ---
                  // Primary CTA designed to be wide and high-contrast for maximum accessibility.
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _completeGetStarted(context), // Logic: Start authentication flow
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20), // Affordance: Next-step indicator
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}


