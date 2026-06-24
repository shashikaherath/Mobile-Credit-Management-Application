// ------------------------------------------------------------------------------
// File: terms_conditions_screen.dart
// Purpose: Legal service agreement for ShopBook shop-owner partnerships.
// Rationale: Mandated by the registration flow to ensure informed legal consent
//   before account creation. Presented as a static, scrollable clause list.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          // Documentation focus: Summarizing the legal partnership requirements between ShopBook and shop owners.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms specifically for Shop Owners',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Updated: April 2026',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introduction',
              'Welcome to ShopBook. By registering as a Shop Owner, you agree to comply with and be bound by the following terms and conditions. Please review them carefully.',
            ),
            _buildSection(
              '2. Account Responsibilities',
              'As a shop owner, you are responsible for maintaining the confidentiality of your account credentials. You agree to provide accurate, current, and complete information about your grocery store and business operations.',
            ),
            _buildSection(
              '3. Store Management',
              'You represent and warrant that you have the legal right to manage the store and sell the products listed. You are responsible for all sales, inventory records, and customer interactions recorded through the app.',
            ),
            _buildSection(
              '4. Data Privacy & Security',
              'We value your privacy. The app collects data regarding your transactions, customers, and inventory to provide analytics and management features. Customer data must be handled in compliance with local privacy laws.',
            ),
            _buildSection(
              '5. Prohibited Activities',
              'You may not use the platform for any illegal transactions, fraudulent activities, or to distribute harmful content. Any abuse of the credit management system is strictly prohibited.',
            ),
            _buildSection(
              '6. System Availability',
              'While we strive for 100% uptime, ShopBook does not guarantee uninterrupted access to the service. We reserve the right to perform maintenance or updates that may temporarily affect availability.',
            ),
            _buildSection(
              '7. Account Termination',
              'We reserve the right to terminate or suspend your account if any of these terms are violated. You may delete your account at any time through the Profile Settings, which will permanently remove your store data.',
            ),
            _buildSection(
              '8. Changes to Terms',
              'ShopBook reserves the right to modify these terms at any time. Significant changes will be notified to you via the app or email.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Thank you for partnering with ShopBook!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    // Layout consistency: Maintaining a uniform typographic scale for legal clauses for professional readability.
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

