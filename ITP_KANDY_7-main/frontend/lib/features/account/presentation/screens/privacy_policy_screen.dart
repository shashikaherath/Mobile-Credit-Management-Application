// ------------------------------------------------------------------------------
// File: privacy_policy_screen.dart
// Purpose: Privacy compliance disclosures for the platform.
// Rationale: Provides legally mandated transparency on data collection, 
//   storage, and user rights. Managed as a static, scrollable legal asset.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          // Content hierarchy: Organizing privacy clauses into a scorable, readable list for legal transparency.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How ShopBook Protects Your Business Data',
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
              '1. Information We Collect',
              'We collect information necessary to manage your store, including your name, email, phone number, shop name, and business address. We also store data about your inventory, sales transactions, and customer credit records to provide analytics.',
            ),
            _buildSection(
              '2. How We Use Your Data',
              'Your data is used to provide the core functionality of the ShopBook app: tracking stock, processing sales, and managing customer debts. We may also use anonymized, aggregated data to improve our services and system performance.',
            ),
            _buildSection(
              '3. Data Storage & Security',
              'ShopBook uses industry-standard encryption and secure cloud-based servers (MongoDB Atlas) to store your store data. Your account is protected by your password, and we recommend using a strong, unique password for your partnership account.',
            ),
            _buildSection(
              '4. Customer Data Management',
              'As a shop owner, you are the controller of your customers\' data recorded in this app. ShopBook acts as a processor. You agree to obtain any necessary consent from your customers for recording their credit transactions.',
            ),
            _buildSection(
              '5. Data Sharing',
              'We do not sell your personal or business data to third parties. Data is only shared with essential service providers (like database hosting) or when required by law to comply with legal obligations.',
            ),
            _buildSection(
              '6. Data Retention',
              'We retain your data as long as your account is active. If you choose to delete your account, all associated store data, including transactions and customer records, will be permanently removed from our active databases.',
            ),
            _buildSection(
              '7. Your Rights',
              'You have the right to access, correct, or delete your personal information at any time via the Profile Settings. You can also export your inventory data to PDF for your own records.',
            ),
            _buildSection(
              '8. Policy Updates',
              'We may update this Privacy Policy from time to time. You will be notified of significant changes through the app\'s notification system.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Your trust is our priority.',
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
    // UI Abstraction: Standardizing the presentation of legal sections with uniform font scaling and spacing.
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

