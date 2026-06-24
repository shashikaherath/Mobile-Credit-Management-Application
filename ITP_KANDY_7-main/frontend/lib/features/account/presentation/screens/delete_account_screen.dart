// ------------------------------------------------------------------------------
// File: delete_account_screen.dart
// Purpose: Irreversible Account Destruction Pipeline.
// Rationale: Manages the multi-step confirmation workflow for data erasure. 
//   Implements intentional UX friction (double-dialog) to prevent accidental 
//   business loss before session invalidation.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity manager
import 'package:frontend/features/auth/presentation/screens/login_screen.dart'; // Navigation: Post-deletion route
import 'package:frontend/core/utils/snackbar_utils.dart'; // Feedback: Status notification component
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isConfirmed = false;
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    // Safety check: Triggering a double-confirmation dialog to prevent accidental data loss.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Final Warning',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.error),
        ),
        content: Text(
          'Are you absolutely sure? This will permanently wipe all your data from our servers. This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textMedium)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('OK, Delete Everything', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      
      // Artificial delay to show the "destructive" processing state
      await Future.delayed(const Duration(seconds: 3));
      
      if (!mounted) return;
      
      // Core destruction: Invoking the AuthProvider to scrub all user-associated records from the server.
      final success = await context.read<AuthProvider>().deleteAccount();
      
      if (mounted) {
        if (success) {
          // Global reset: Clearing the navigation stack and redirecting to the login portal.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        } else {
          setState(() => _isDeleting = false);
          SnackBarUtils.showSnackBar(
            context,
            context.read<AuthProvider>().error ?? 'Failed to delete account',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeleting) {
      return _buildDeletingState();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delete Account',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.warning_rounded, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Permanent Account Deletion',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You are about to permanently delete your ShopBook account. All your data will be wiped from our systems.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textMedium,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'WHAT WILL BE DELETED?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(Icons.inventory_2_outlined, 'All your products & stock history'),
            _buildInfoItem(Icons.receipt_long_outlined, 'Full sales records & invoice history'),
            _buildInfoItem(Icons.people_outline, 'Customer database & credit history'),
            _buildInfoItem(Icons.local_shipping_outlined, 'Supplier info & purchase records'),
            _buildInfoItem(Icons.notifications_active_outlined, 'Preferences & notification logs'),
            const SizedBox(height: 32),
            Row(
              children: [
                Checkbox(
                  value: _isConfirmed,
                  activeColor: AppColors.error,
                  onChanged: (val) => setState(() => _isConfirmed = val ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isConfirmed = !_isConfirmed),
                    child: Text(
                      'I understand that this action is irreversible and all my data will be lost.',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textMedium),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConfirmed ? _handleDelete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  disabledBackgroundColor: AppColors.error.withValues(alpha: 0.3),
                  elevation: 0,
                ),
                child: Text(
                  'PERMANENTLY DELETE ACCOUNT',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Keep My Account',
                  style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMedium),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletingState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 8,
                    color: AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                'Destroying Data...',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We are securely wiping your business profile and all associated records from the cloud. This will take a moment.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textMedium,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              const Icon(Icons.security_rounded, color: AppColors.textLight, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

