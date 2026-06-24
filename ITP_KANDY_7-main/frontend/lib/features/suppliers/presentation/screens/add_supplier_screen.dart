// ------------------------------------------------------------------------------
// File: add_supplier_screen.dart
// Purpose: Dual-Purpose Business Partner Registration Interface.
// Rationale: Facilitates both the onboarding of new suppliers and the 
//   modification of existing partner profiles. Integrates with the 
//   notification system for administrative audit logging and utilizes 
//   standardized validation for consistent data integrity across the CRM layer.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Flutter Material widgets
import 'package:google_fonts/google_fonts.dart'; // UI: Poppins typography
import 'package:provider/provider.dart'; // State: Provider read/watch
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Brand colour tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // UX: Feedback toasts with diagnostics
import 'package:frontend/features/suppliers/domain/entities/supplier.dart'; // Domain: Supplier model
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart'; // State: Supplier data manager
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart'; // State: Audit trail logger
import 'package:frontend/core/utils/validation_utils.dart'; // Util: Form field validators
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger

class AddSupplierScreen extends StatefulWidget {
  final Supplier? supplier;
  const AddSupplierScreen({super.key, this.supplier});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pre-filling form for update mode based on passed entity.
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!.name;
      _phoneController.text = widget.supplier!.phone;
      _emailController.text = widget.supplier!.email;
      _addressController.text = widget.supplier!.address;
      _notesController.text = widget.supplier!.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final provider = Provider.of<SupplierProvider>(context, listen: false);

    final supplierData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    bool success;
    // Branching logic: Patch vs Post based on widget intent.
    if (widget.supplier != null) {
      success = await provider.updateSupplier(
        widget.supplier!.id,
        supplierData,
      );
    } else {
      success = await provider.addSupplier(supplierData);
    }

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      if (widget.supplier == null) {
        // Log entry in the internal notification system for administrative tracking.
        context.read<NotificationProvider>().createNotification(
          type: 'delivery',
          title: 'New Supplier Added',
          message:
              'Supplier "${_nameController.text}" has been successfully added to your contact list.',
        );
      }
      SnackBarUtils.showSnackBar(
        context,
        widget.supplier != null
            ? 'Supplier updated successfully'
            : 'Supplier added successfully',
      );
      Navigator.pop(context);
    } else if (mounted) {
      SnackBarUtils.showSnackBar(
        context,
        provider.error ?? 'Failed to save supplier',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.supplier != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Premium light background
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Supplier' : 'Add New Supplier',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Section 1: Business Identity ---
                _buildSectionHeader(Icons.business_center_outlined, 'Business Identity'),
                const SizedBox(height: 16),
                _buildFormCard([
                  _buildLabel('Supplier Name *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textDark),
                    decoration: _inputDecoration(
                      hint: 'e.g. Acme Corporation',
                      icon: Icons.business_outlined,
                    ),
                    validator: (v) => ValidationUtils.validateName(v, fieldName: 'Supplier name'),
                  ),
                ]),

                const SizedBox(height: 24),
                // --- Section 2: Contact Information ---
                _buildSectionHeader(Icons.contact_phone_outlined, 'Contact Details'),
                const SizedBox(height: 16),
                _buildFormCard([
                  _buildLabel('Phone Number *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textDark),
                    decoration: _inputDecoration(
                      hint: '+94 XX XXX XXXX',
                      icon: Icons.phone_outlined,
                    ),
                    validator: ValidationUtils.validatePhone,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Email Address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textDark),
                    decoration: _inputDecoration(
                      hint: 'supplier@example.com',
                      icon: Icons.mail_outline,
                    ),
                    validator: ValidationUtils.validateEmail,
                  ),
                ]),

                const SizedBox(height: 24),
                // --- Section 3: Logistics & Notes ---
                _buildSectionHeader(Icons.map_outlined, 'Logistics & Notes'),
                const SizedBox(height: 16),
                _buildFormCard([
                  _buildLabel('Physical Address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
                    decoration: _inputDecoration(
                      hint: 'Street, City, Postal Code',
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Additional Remarks'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
                    decoration: _inputDecoration(
                      hint: 'Important notes about this partner...',
                      icon: Icons.note_outlined,
                    ),
                  ),
                ]),

                const SizedBox(height: 40),

                // --- Action Button ---
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isSubmitting
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
                                Icon(
                                  isEdit ? Icons.check_circle_outline : Icons.add_business_outlined,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isEdit ? 'Save Changes' : 'Register Supplier',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.textLight.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textLight.withValues(alpha: 0.5), size: 20),
      filled: true,
      fillColor: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.textDark.withValues(alpha: 0.9),
      ),
    );
  }
}


