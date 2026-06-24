// ------------------------------------------------------------------------------
// File: add_product_screen.dart
// Purpose: Multi-modal Merchandise Onboarding Interface.
// Rationale: Orchestrates the comprehensive product creation lifecycle, 
//   integrating multi-field validation, stock configuration, and Cloudinary-backed 
//   media persistence via the global ProductProvider.
// ------------------------------------------------------------------------------
import 'dart:io' show File; // Platform: File I/O for image preview
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:flutter/foundation.dart'; // Platform: Web/native detection (kIsWeb)
import 'package:image_picker/image_picker.dart'; // Media: Camera/gallery access
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // Feedback: Status notification component
import 'package:frontend/features/products/presentation/providers/product_provider.dart'; // State: Inventory manager
import 'package:frontend/core/utils/validation_utils.dart'; // Logic: Form field validators
import 'package:frontend/shared/main_shell.dart'; // Navigation: Dashboard refresh trigger
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger
import 'package:frontend/features/products/presentation/utils/category_constants.dart'; // Config: Product taxonomy
import 'package:frontend/core/utils/image_helper.dart'; // Logic: Unified pick-and-crop utility


class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _minStockController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Fruits';
  String _selectedUnit = 'pcs';
  int _initialStock = 0;
  bool _notifyOutOfStock = true;
  bool _saving = false;
  XFile? _imageFile;
  final _formKey = GlobalKey<FormState>();

  final List<String> _categories = ProductCategories.list;

  final Map<String, String> _unitExamples = {
    'kg': 'rice and vegetables',
    'pcs': 'apples and eggs',
    'items': 'bread, toothpaste, oil bottles',
    'packs': 'bundled goods',
    'trays': 'egg trays',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final croppedFile = await ImageHelper.pickAndCropImage(
        context: context,
        source: source,
      );
      
      if (croppedFile != null) {
        setState(() {
          _imageFile = croppedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(
          context,
          'Error processing image: $e',
          isError: true,
        );
      }
    }
  }

  // Validates the form and sends the new product data to the backend.
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
 
    // Trigger UI loading state.
    setState(() => _saving = true);
 
    // Data normalization for API transmission.
    final data = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory, // Hierarchical grouping
      // Numeric parsing with zero fallbacks.
      'sellingPrice': double.tryParse(_sellingPriceController.text) ?? 0.0,
      'purchasePrice': double.tryParse(_purchasePriceController.text) ?? 0.0,
      'stockQuantity': _initialStock, // Opening balance
      'minimumStockLevel': int.tryParse(_minStockController.text) ?? 0, // Threshold for system alerts
      'description': _descriptionController.text.trim(),
      'unit': _selectedUnit, // Base measurement (kg, pcs, etc.)
      'notifyOutOfStock': _notifyOutOfStock, // Subscription to stock events
    };
 
    // Multipart request handling for simultaneous JSON and Image upload.
    final success = await context.read<ProductProvider>().createProduct(
          data,
          imageFile: _imageFile,
        );

    // Context guard for async safety.
    if (!context.mounted) return;

    if (mounted) {
      setState(() => _saving = false);
      if (success && mounted) {
        SnackBarUtils.showSnackBar(context, 'Product added successfully');
        
        // Invalidate Home Screen stats to force a re-fetch of business metrics.
        MainShell.homeKey.currentState?.refresh();

        Navigator.pop(context); // Close creation screen
      } else if (mounted) {
        final productProvider = context.read<ProductProvider>();
        SnackBarUtils.showSnackBar(
          context,
          productProvider.error ?? 'Failed to add product',
          isError: true,
          technicalDetails: productProvider.technicalDetails,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Add New Product'),
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image upload area
                      _buildImageSection(),
                      SizedBox(height: 24),
                      // Product Name
                      _buildLabel('PRODUCT NAME (REQUIRED)', isRequired: true),
                      SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Organic Red Apples',
                        ),
                        validator: (v) => ValidationUtils.validateRequired(v, 'Product name'),
                      ),
                      SizedBox(height: 20),
                      // Category
                      _buildLabel('CATEGORY'),
                      SizedBox(height: 6),
                      _buildCategoryDropdown(),
                      SizedBox(height: 20),
                      // Prices
                      Row(
                        children: [
                          Expanded(
                            child: _buildPriceField(
                              'SELLING PRICE', // Markup valuation
                              _sellingPriceController,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildPriceField(
                              'PURCHASE (COST)', // Primary expense tracker
                              _purchasePriceController,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Stock section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('INITIAL STOCK'),
                                    Text(
                                      'Current units available',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                    ],
                                  ),
                                Row(
                                  children: [
                                    _buildUnitSelector(), // Inventory measurement logic
                                    SizedBox(width: 12),
                                    _buildStockStepper(), // Manual tally control
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('MINIMUM STOCK LEVEL'),
                                SizedBox(height: 6),
                                TextFormField(
                                  controller: _minStockController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Alert threshold...',
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  validator: ValidationUtils.validateStock, // Numeric sanity check
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Description
                      _buildLabel('DESCRIPTION'),
                      SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'Add details about product size, weight, or benefits...',
                        ),
                      ),
                      SizedBox(height: 12),
                      // Notification Toggle: Logic for async push alerts
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile(
                          value: _notifyOutOfStock,
                          onChanged: (v) => setState(() => _notifyOutOfStock = v),
                          title: Text(
                            'Notify when out of stock',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          subtitle: Text(
                            'Receive an alert when this product hits 0 units.',
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                          ),
                          activeThumbColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveProduct,
                      icon: _saving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.check_circle_outline),
                      label: Text(_saving ? 'Saving...' : 'Save Product'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context), // Discard current draft
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // File system picker for branding and catalog visuals
  Widget _buildImageSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 120,
          clipBehavior: Clip.antiAlias, // Ensures internal content (image) follows the container's shape
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 2,
              strokeAlign: BorderSide.strokeAlignCenter,
            ),
          ),
          child: Center(
            child: _imageFile != null
                ? (kIsWeb
                    ? Image.network(
                        _imageFile!.path,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(_imageFile!.path),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ))
                : Icon(
                    Icons.add_a_photo,
                    size: 36,
                    color: AppColors.textLight.withValues(alpha: 0.6),
                  ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              // Hardware interface for immediate image capture
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt, size: 18),
                  label: Text(
                    'Take Photo',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              // Browsing existing media on the device
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: Icon(Icons.image, size: 18),
                  label: Text(
                    'Gallery',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMedium,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Recommended: Square PNG or JPG up to 5MB',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Thematically consistent labels
  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isRequired ? AppColors.primary : AppColors.textMedium,
        letterSpacing: 1.0,
      ),
    );
  }

  // Pre-configured category list selection
  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: AppColors.textLight),
          items: _categories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c, style: GoogleFonts.poppins(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  // Reusable currency input component
  Widget _buildPriceField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: 'Rs.  ',
            prefixStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
            hintText: '0.00',
          ),
          validator: ValidationUtils.validatePrice, // Logic for non-negative floating numbers
        ),
      ],
    );
  }

  // Selection modal for unit classification (items vs volume)
  Widget _buildUnitSelector() {
    return GestureDetector(
      onTap: _showUnitSelectionDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedUnit,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  // Modal UI for unit selection
  void _showUnitSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Unit',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        contentPadding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _unitExamples.entries.map((entry) {
              final isSelected = _selectedUnit == entry.key;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                selected: isSelected,
                selectedTileColor: AppColors.primary.withValues(alpha: 0.05),
                title: Text(
                  entry.key,
                  style: GoogleFonts.poppins(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textDark,
                  ),
                ),
                subtitle: Text(
                  'e.g. ${entry.value}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.7) : AppColors.textLight,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedUnit = entry.key); // State update
                  Navigator.pop(context); // Close selection
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textMedium)),
          ),
        ],
      ),
    );
  }

  // A custom UI widget that lets the user tap - or + to change the stock count.
  Widget _buildStockStepper() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The 'Minus' button.
          InkWell(
            onTap: () {
              // Decrement, but stop at zero (we can't have negative initial stock).
              if (_initialStock > 0) setState(() => _initialStock--);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(Icons.remove, color: AppColors.primary, size: 18),
            ),
          ),
          // The current count display.
          SizedBox(
            width: 36,
            child: Text(
              '$_initialStock',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          // The 'Plus' button.
          InkWell(
            onTap: () => setState(() => _initialStock++),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Icon(Icons.add, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

