// ------------------------------------------------------------------------------
// File: profile_settings_screen.dart
// Purpose: Identity and Security Governance for shop owners.
// Rationale: Manages three distinct mutation pipelines: 
//   1. Visual Identity (Avatar)
//   2. Business Metadata (Shop, Contact)
//   3. Security Credentials (Credentials/Password rotation)
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // Feedback: Status message system
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity manager
import 'package:frontend/core/utils/phone_utils.dart'; // Utility: Identifier normalization
import 'package:frontend/core/utils/validation_utils.dart'; // Utility: Form regex engines
import 'package:image_picker/image_picker.dart'; // Hardware: Camera/Gallery integration
import 'package:frontend/core/utils/image_helper.dart'; // Logic: Unified pick-and-crop utility
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger


class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  // --- Form Part A: Metadata Orchestration ---
  final _formKey = GlobalKey<FormState>(); // Key: Personal info validation block
  late TextEditingController _nameController; // Input: Human name
  late TextEditingController _shopNameController; // Input: Business label
  late TextEditingController _phoneController; // Input: SMS-capable identifier
  late TextEditingController _emailController; // Input: Digital contact
  
  // --- Form Part B: Security Orchestration ---
  final _passwordFormKey = GlobalKey<FormState>(); // Key: Credential validation block
  final _oldPasswordController = TextEditingController(); // Input: Identity proof (current)
  final _newPasswordController = TextEditingController(); // Input: Target credential
  final _confirmPasswordController = TextEditingController(); // Input: Integrity check

  @override
  void initState() {
    super.initState();
    // Step: Seed the controllers with the currently authenticated owner's cached state.
    final owner = context.read<AuthProvider>().currentOwner;
    _nameController = TextEditingController(text: owner?.name);
    _shopNameController = TextEditingController(text: owner?.shopName);
    _phoneController = TextEditingController(text: owner?.phone);
    _emailController = TextEditingController(text: owner?.email);

    // Logic: Proactive synchronization.
    // Rationale: Pulls latest data from the backend to reflect any administrative changes
    //   made by ShopBook staff while the user was away.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AuthProvider>().refreshProfile();
      
      if (mounted) {
        final freshOwner = context.read<AuthProvider>().currentOwner;
        // Refinement: Update inputs with fresh data from the cloud.
        _nameController.text = freshOwner?.name ?? _nameController.text;
        _shopNameController.text = freshOwner?.shopName ?? _shopNameController.text;
        _phoneController.text = freshOwner?.phone ?? _phoneController.text;
        _emailController.text = freshOwner?.email ?? _emailController.text;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose(); // Cleanup: Memory leaks prevention
    _shopNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /*
   * Logic: Metadata Synchronization.
   * Rationale: Updates the core identity fields in the backend database.
   * Strategy: Normalizes the phone number to E.164 format before transmission.
   */
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Action: Push local form state to the multi-tenant backend.
    final success = await context.read<AuthProvider>().updateProfile({
      'name': _nameController.text.trim(),
      'shopName': _shopNameController.text.trim(),
      'phone': normalizePhoneNumber(_phoneController.text),
      'email': _emailController.text.trim(),
    });

    if (mounted) {
      if (success) {
        SnackBarUtils.showSnackBar(context, 'Profile updated successfully');
      } else {
        // Step: Log failure with full architectural visibility from the provider.
        SnackBarUtils.showSnackBar(
          context,
          context.read<AuthProvider>().error ?? 'Failed to update profile',
          isError: true,
        );
      }
    }
  }

  /*
   * Logic: Secure Credential Rotation.
   * Rationale: Handles the sensitive password update handshake.
   * Requires proof-of-knowledge of the current password for security verification.
   */
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    // Action: Perform the auth-rotator handshake.
    final success = await context.read<AuthProvider>().changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );

    if (mounted) {
      if (success) {
        // Step: Atomic reset of sensitive fields upon success.
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        SnackBarUtils.showSnackBar(context, 'Password changed successfully');
      } else {
        SnackBarUtils.showSnackBar(
          context,
          context.read<AuthProvider>().error ?? 'Failed to change password',
          isError: true,
        );
      }
    }
  }

  /*
   * Logic: Cloud Asset Persistence.
   * Rationale: Integrated avatar management.
   * Strategy: Triggers a cloud upload to Cloudinary before updating the DB link.
   */
  /*
   * Logic: Cloud Asset Persistence with Precision Cropping.
   * Rationale: Integrated avatar management with cropping.
   */
  Future<void> _pickImage() async {
    // UI: Allow user to choose input source

    final source = await showModalBottomSheet<dynamic>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
              title: Text('Take Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.image_rounded, color: AppColors.primary),
              title: Text('Choose from Gallery', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text('Remove Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: Colors.redAccent)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;
    if (!mounted) return;

    if (source == 'remove') {
      final success = await context.read<AuthProvider>().removeProfilePicture();
      if (mounted) {
        if (success) {
          SnackBarUtils.showSnackBar(context, 'Profile picture removed');
        } else {
          SnackBarUtils.showSnackBar(
            context,
            context.read<AuthProvider>().error ?? 'Failed to remove image',
            isError: true,
          );
        }
      }
      return;
    }

    try {
      final croppedFile = await ImageHelper.pickAndCropImage(
        context: context,
        source: source as ImageSource,
        isProfile: true,
      );

      if (croppedFile != null && mounted) {
        final success = await context.read<AuthProvider>().updateProfilePicture(croppedFile);
        if (mounted) {
          if (success) {
            SnackBarUtils.showSnackBar(context, 'Profile picture updated');
          } else {
            SnackBarUtils.showSnackBar(
              context,
              context.read<AuthProvider>().error ?? 'Failed to upload image',
              isError: true,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Error processing image: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Aesthetics: Soft neutral backdrop
      appBar: AppBar(
        title: const Text('Profile Settings'),
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              // --- Module: Visual Identity ---
              _buildAvatar(),
              const SizedBox(height: 24),
              
              // --- Module: Metadata Governance ---
              _buildSection(
                title: 'PERSONAL INFORMATION',
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        icon: Icons.person_outline,
                        label: 'Name',
                        child: TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration('Enter your name'),
                          validator: (v) => ValidationUtils.validateRequired(v, 'Name'),
                        ),
                      ),
                      _buildSettingsItem(
                        icon: Icons.store_outlined,
                        label: 'Shop Name',
                        child: TextFormField(
                          controller: _shopNameController,
                          decoration: _inputDecoration('Enter shop name'),
                          validator: (v) => ValidationUtils.validateRequired(v, 'Shop name'),
                        ),
                      ),
                      _buildSettingsItem(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration('Enter phone'),
                          validator: ValidationUtils.validatePhone,
                        ),
                      ),
                      _buildSettingsItem(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration('Enter email'),
                          validator: ValidationUtils.validateEmail,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Meta CTA: Persist all textual changes.
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: context.watch<AuthProvider>().isLoading
                                ? null
                                : _updateProfile, // Block: Guard against concurrent states
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: context.watch<AuthProvider>().isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Save Profile Details',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Module: Security Governance ---
              _buildSection(
                title: 'SECURITY',
                child: Form(
                  key: _passwordFormKey,
                  child: Column(
                    children: [
                      _buildSettingsItem(
                        icon: Icons.lock_outline,
                        label: 'Current Password',
                        child: TextFormField(
                          controller: _oldPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration('Enter current password'),
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ),
                      _buildSettingsItem(
                        icon: Icons.lock_reset_outlined,
                        label: 'New Password',
                        child: TextFormField(
                          controller: _newPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration('Min. 8 characters'),
                          validator: ValidationUtils.validatePassword,
                        ),
                      ),
                      _buildSettingsItem(
                        icon: Icons.lock_reset_outlined,
                        label: 'Confirm Password',
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration('Re-enter new password'),
                          validator: (val) {
                            if (val != _newPasswordController.text) {
                              return 'No match';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Security CTA: Atomic password rotation attempt.
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: context.watch<AuthProvider>().isLoading
                                ? null
                                : _changePassword,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Update Password',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /*
   * UI Component Builder: Themed Settings Section.
   */
  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: child,
        ),
      ],
    );
  }

  /*
   * UI Component Builder: Field Label + Input Layout.
   */
  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  /*
   * UI Module: Interactive Avatar Stack.
   * Rationale: Provides direct visual manipulation of the profile picture.
   */
  Widget _buildAvatar() {
    final owner = context.watch<AuthProvider>().currentOwner;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 4),
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.cardBlueBg,
              backgroundImage: (owner?.profilePic != null && owner!.profilePic!.isNotEmpty)
                  ? NetworkImage(owner.profilePic!)
                  : null,
              child: (owner?.profilePic == null || owner!.profilePic!.isEmpty)
                  ? const Icon(Icons.person, size: 60, color: AppColors.primary)
                  : null,
            ),
          ),
          // Action Widget: Floating trigger for the camera/gallery picker.
          Positioned(
            bottom: 4,
            right: 4,
            child: Row(
              children: [
                if (owner?.profilePic != null && owner!.profilePic!.isNotEmpty)
                  GestureDetector(
                    onTap: isLoading ? null : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Remove Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                          content: Text('Are you sure you want to remove your profile photo?', style: GoogleFonts.poppins()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textMedium)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Remove', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        await context.read<AuthProvider>().removeProfilePicture();
                        if (mounted) SnackBarUtils.showSnackBar(context, 'Profile picture removed');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                if (owner?.profilePic != null && owner!.profilePic!.isNotEmpty)
                  const SizedBox(width: 8),
                GestureDetector(
                  onTap: isLoading ? null : _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /*
   * UI Utility: Clean decoration for in-section input fields.
   */
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.textLight),
      border: InputBorder.none,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}

