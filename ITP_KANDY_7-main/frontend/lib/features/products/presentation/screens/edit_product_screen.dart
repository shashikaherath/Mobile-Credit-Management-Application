// ------------------------------------------------------------------------------
// File: edit_product_screen.dart
// Purpose: Product Modification and Deletion Interface.
// Rationale: Facilitates secure inventory record updates including partial data 
//   patches, image replacement, and destructive deletion flows with multi-layer 
//   confirmation mechanisms.
// ------------------------------------------------------------------------------
import 'dart:io' show File; // Platform: File I/O for image preview
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:flutter/foundation.dart'; // Platform: Web/native detection (kIsWeb)
import 'package:image_picker/image_picker.dart'; // Media: Camera/gallery access
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // Feedback: Status notification component
import 'package:frontend/features/products/domain/entities/product.dart'; // Domain: Product entity
import 'package:frontend/features/products/presentation/providers/product_provider.dart'; // State: Inventory manager
import 'package:frontend/core/utils/validation_utils.dart'; // Logic: Form field validators
import 'package:frontend/features/products/presentation/utils/category_constants.dart'; // Config: Product taxonomy
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger
import 'package:frontend/core/utils/image_helper.dart'; // Logic: Unified pick-and-crop utility


class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController _nameController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _minStockController;
  late TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _selectedUnit;
  late int _stockQuantity;
  late bool _notifyOutOfStock;
  bool _saving = false;
  XFile? _imageFile;
  bool _imageRemoved = false;
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
  void initState() {
    super.initState();
    // Pre-fill local controllers with existing entity data
    _nameController = TextEditingController(text: widget.product.name);
    _sellingPriceController = TextEditingController(
      text: widget.product.sellingPrice.toStringAsFixed(2),
    );
    _purchasePriceController = TextEditingController(
      text: widget.product.purchasePrice.toStringAsFixed(2),
    );
    _minStockController = TextEditingController(
      text: widget.product.minimumStockLevel.toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.product.description,
    );
    // Category validation against current runtime constants
    _selectedCategory = _categories.contains(widget.product.category)
        ? widget.product.category
        : _categories.first;
    _selectedUnit = widget.product.unit.isNotEmpty ? widget.product.unit : 'pcs';
    _stockQuantity = widget.product.stockQuantity;
    _notifyOutOfStock = widget.product.notifyOutOfStock;
  }

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
          _imageRemoved = false; // Override previous removal intent
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSnackBar(context, 'Error processing image: $e', isError: true);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageRemoved = true; // Mark for deletion on the server side
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    // Patch object construction for partial/full update
    final data = {
      'name': _nameController.text.trim(),
      'category': _selectedCategory,
      'sellingPrice': double.tryParse(_sellingPriceController.text) ?? 0.0,
      'purchasePrice': double.tryParse(_purchasePriceController.text) ?? 0.0,
      'stockQuantity': _stockQuantity,
      'minimumStockLevel': int.tryParse(_minStockController.text) ?? 0,
      'description': _descriptionController.text.trim(),
      'imageUrl': _imageRemoved ? '' : widget.product.imageUrl, // Handle remote image deletion
      'unit': _selectedUnit,
      'notifyOutOfStock': _notifyOutOfStock,
    };

    // Execution via Provider to maintain centralized cache consistency
    final success = await context.read<ProductProvider>().updateProduct(
      widget.product.id,
      data,
      imageFile: _imageFile,
    );

    if (mounted) {
      setState(() => _saving = false);
      if (success && mounted) {
        SnackBarUtils.showSnackBar(context, 'Product updated successfully');
        Navigator.pop(context); // Return to inventory hub
      } else if (mounted) {
        final productProvider = context.read<ProductProvider>();
        SnackBarUtils.showSnackBar(
          context,
          productProvider.error ?? 'Failed to update product',
          isError: true,
          technicalDetails: productProvider.technicalDetails,
        );
      }
    }
  }

  Future<void> _deleteProduct() async {
    // Destructive action safeguard
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${widget.product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<ProductProvider>().deleteProduct(
        widget.product.id,
      );
      if (mounted) {
        if (success) {
          SnackBarUtils.showSnackBar(
            context,
            'Product "${widget.product.name}" has been deleted.',
          );
          Navigator.pop(context); // Final exit after deletion
        } else {
          final productProvider = context.read<ProductProvider>();
          SnackBarUtils.showSnackBar(
            context,
            productProvider.error ?? 'Failed to delete product',
            isError: true,
            technicalDetails: productProvider.technicalDetails,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Edit Product'),
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Product Image
              _buildImageSection(),
              SizedBox(height: 24),
              // Product Name
              _buildLabel('PRODUCT NAME (REQUIRED)'),
              SizedBox(height: 8),
              _buildFormField(
                _nameController,
                validator: (v) => ValidationUtils.validateRequired(v, 'Product name'),
              ),
              SizedBox(height: 20),
              // Category
              _buildLabel('CATEGORY'),
              SizedBox(height: 8),
              _buildCategoryDropdown(),
              SizedBox(height: 20),
              // Prices
              Row(
                children: [
                  Expanded(
                    child: _buildPriceField(
                      'SELLING PRICE',
                      _sellingPriceController,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildPriceField(
                      'PURCHASE (COST)',
                      _purchasePriceController,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Stock quantity
              _buildLabel('CURRENT STOCK QUANTITY'),
              SizedBox(height: 8),
              _buildStockControl(),
              SizedBox(height: 20),
              // Min stock
              _buildLabel('MINIMUM STOCK LEVEL'),
              SizedBox(height: 8),
              _buildFormField(
                _minStockController,
                keyboardType: TextInputType.number,
                validator: ValidationUtils.validateStock,
              ),
              SizedBox(height: 20),
              // Description
              _buildLabel('DESCRIPTION'),
              SizedBox(height: 8),
              _buildFormField(
                _descriptionController,
                hint: 'Enter product description...',
              ),
              SizedBox(height: 20),
              // Notification Toggle
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
                ),
              ),
              SizedBox(height: 28),
              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: _saving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Update Product',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _deleteProduct,
                  icon: Icon(Icons.delete_forever, color: AppColors.error),
                  label: Text(
                    'Delete Product',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildImageSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _imageFile != null
                        ? (kIsWeb
                            ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                            : Image.file(File(_imageFile!.path), fit: BoxFit.cover))
                        : (!_imageRemoved && widget.product.imageUrl.isNotEmpty)
                            ? Image.network(
                                widget.product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 40,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: AppColors.textLight,
                                ),
                              ),
                  ),
                ),
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(Icons.camera_alt),
                              title: Text('Take Photo'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.camera);
                              },
                            ),
                            ListTile(
                              leading: Icon(Icons.image),
                              title: Text('Gallery'),
                              onTap: () {
                                Navigator.pop(context);
                                _pickImage(ImageSource.gallery);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.photo_camera,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_imageFile != null || (!_imageRemoved && widget.product.imageUrl.isNotEmpty))
              TextButton.icon(
                onPressed: _removeImage,
                icon: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                label: Text(
                  'Remove Image',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildFormField(
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.primary.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: AppColors.textLight),
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark),
          items: _categories
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
      ),
    );
  }

  Widget _buildPriceField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SizedBox(height: 8),
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
            filled: true,
            fillColor: AppColors.primary.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: ValidationUtils.validatePrice,
        ),
      ],
    );
  }

  Widget _buildStockControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _buildUnitSelector(),
          SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_stockQuantity > 0) setState(() => _stockQuantity--);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textDark.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.remove, color: AppColors.primary),
            ),
          ),
          Expanded(
            child: Text(
              '$_stockQuantity',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _stockQuantity++),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector() {
    return GestureDetector(
      onTap: _showUnitSelectionDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedUnit,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

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
                  setState(() => _selectedUnit = entry.key);
                  Navigator.pop(context);
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
}

