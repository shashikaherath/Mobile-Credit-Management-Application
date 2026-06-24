// ------------------------------------------------------------------------------
// File: record_purchase_screen.dart
// Purpose: Complex Batch Procurement and Inventory Intake Engine.
// Rationale: Manages the end-to-end lifecycle of stock acquisition from 
//   external suppliers. Supports dynamic multi-product line items, advanced 
//   tax calculations, and automated debt/payable tracking. Orchestrates 
//   system-wide synchronization across Inventory, CRM, and Dashboard services.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Flutter Material widgets
import 'package:google_fonts/google_fonts.dart'; // UI: Poppins typography
import 'package:provider/provider.dart'; // State: Provider read/watch
import 'package:intl/intl.dart'; // Format: Date formatting
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Brand colour tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // UX: Feedback toasts with diagnostics
import 'package:frontend/features/suppliers/presentation/providers/purchase_provider.dart'; // State: Purchase records
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart'; // State: Supplier directory
import 'package:frontend/features/products/presentation/providers/product_provider.dart'; // State: Product catalogue
import 'package:frontend/features/products/domain/entities/product.dart'; // Domain: Product model
import 'package:frontend/features/suppliers/domain/entities/purchase.dart'; // Domain: Purchase entity
import 'package:frontend/features/suppliers/presentation/utils/export_utils.dart'; // Export Utilities
import 'package:frontend/shared/main_shell.dart'; // Shell: Dashboard refresh trigger
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity management

class RecordPurchaseScreen extends StatefulWidget {
  final Purchase? purchase;

  const RecordPurchaseScreen({super.key, this.purchase});

  @override
  State<RecordPurchaseScreen> createState() => _RecordPurchaseScreenState();
}

class _RecordPurchaseScreenState extends State<RecordPurchaseScreen> {
  final _invoiceController = TextEditingController();
  final _subtotalController = TextEditingController();
  final _taxController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();

  String? _selectedSupplierId;
  String _selectedSupplierName = '';
  final List<Map<String, dynamic>> _purchasedItems = [];
  bool _isSubmitting = false;
  bool _isLoadingDetails = false;
  bool _showSupplierError = false;
  bool _showProductError = false;

  String _paymentStatus = 'Paid'; // Default status
  String _paymentMethod = 'Cash'; // Default method
  DateTime _selectedDate = DateTime.now();

  bool get _isReadOnly => widget.purchase != null;

  @override
  void initState() {
    super.initState();
    if (widget.purchase != null) {
      final p = widget.purchase!;
      _selectedSupplierId = p.supplierId;
      _selectedSupplierName = p.supplierName;
      _selectedDate =
          (DateTime.tryParse(p.purchaseDate) ?? DateTime.now()).toLocal();
      _paymentStatus = p.status.isNotEmpty 
          ? p.status[0].toUpperCase() + p.status.substring(1).toLowerCase()
          : 'Paid';
      _paymentMethod = p.paymentMethod.isNotEmpty
          ? p.paymentMethod[0].toUpperCase() + p.paymentMethod.substring(1).toLowerCase()
          : 'Cash';
      _notesController.text = p.notes;
      _invoiceController.text = p.invoiceNumber;
      _amountPaidController.text = p.amountPaid.toString();
      _taxController.text = p.tax.toString();
      
      // If items are already present (unlikely from list), populate them
      _populateItems(p.items);

      // Fetch full purchase details (with items) since the list query excludes them
      if (p.items.isEmpty) {
        _isLoadingDetails = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fetchFullPurchaseDetails(p.id);
        });
      }
    }
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupplierProvider>().fetchSuppliers();
        context.read<ProductProvider>().fetchProducts();
      }
    });
  }

  void _populateItems(List<dynamic> items) {
    _purchasedItems.clear();
    for (var item in items) {
      if (item is Map) {
        _purchasedItems.add({
          'productId': item['productId'],
          'name': item['productName'] ?? item['name'] ?? '',
          'quantity': item['quantity'],
          'unit': item['unit'],
          'costPrice': item['costPrice'] ?? item['price'] ?? 0.0,
          'qtyController': TextEditingController(text: item['quantity'].toString()),
          'costController': TextEditingController(text: (item['costPrice'] ?? item['price'] ?? 0.0).toString()),
        });
      }
    }
  }

  Future<void> _fetchFullPurchaseDetails(String purchaseId) async {
    final provider = context.read<PurchaseProvider>();
    final fullPurchase = await provider.fetchPurchaseById(purchaseId);
    if (fullPurchase != null && mounted) {
      setState(() {
        _populateItems(fullPurchase.items);
        _isLoadingDetails = false;
      });
    } else if (mounted) {
      setState(() => _isLoadingDetails = false);
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _subtotalController.dispose();
    _taxController.dispose();
    _amountPaidController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    for (var item in _purchasedItems) {
      item['qtyController']?.dispose();
      item['costController']?.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  double get _subtotal {
    // Aggregation logic: Summing up the base cost of all selected products.
    return _purchasedItems.fold(0.0, (sum, item) {
      final price = item['costPrice'] ?? 0.0; // Per-unit acquisition cost
      final qty = item['quantity'] ?? 0; // Number of units received
      return sum + (price * qty); // Cumulative subtotal
    });
  }

  double get _tax => double.tryParse(_taxController.text) ?? 0; // Value-added or sales tax
  double get _totalAmount => _subtotal + _tax; // Gross liability to the supplier
  double get _amountPaid => double.tryParse(_amountPaidController.text) ?? 0; // Cash outflow today
  double get _remaining => _totalAmount - _amountPaid; // Residual debt to be recorded as 'payable'

  void _addItem(Product product) {
    setState(() {
      // Logic: If product already exists in the batch, increment quantity instead of adding duplicate line.
      final existingIndex = _purchasedItems.indexWhere((item) => item['productId'] == product.id);
      
      if (existingIndex != -1) {
        _purchasedItems[existingIndex]['quantity'] += 1;
        // UX: Update the controller so the UI reflects the new quantity immediately
        _purchasedItems[existingIndex]['qtyController'].text = _purchasedItems[existingIndex]['quantity'].toString();
      } else {
        _purchasedItems.add({
          'productId': product.id,
          'name': product.name,
          'quantity': 1,
          'unit': product.unit,
          'costPrice': product.purchasePrice,
          'qtyController': TextEditingController(text: '1'),
          'costController': TextEditingController(text: product.purchasePrice.toString()),
        });
      }
      _showProductError = false;

      // Locked-in Logic: If status is 'Paid', keep amountPaid in sync with the new total
      if (_paymentStatus == 'Paid') {
        _amountPaidController.text = _totalAmount.toStringAsFixed(2);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _purchasedItems.removeAt(index);
    });
  }

  void _updateItem(int index, {int? quantity, double? costPrice}) {
    setState(() {
      // Logic: Clamping inputs to prevent mathematical errors in inventory valuation.
      if (quantity != null) {
        _purchasedItems[index]['quantity'] = quantity < 1 ? 1 : quantity;
      }
      if (costPrice != null) {
        _purchasedItems[index]['costPrice'] = costPrice < 0 ? 0.0 : costPrice;
      }
      
      // Locked-in Logic: If status is 'Paid', keep amountPaid in sync with the new total
      if (_paymentStatus == 'Paid') {
        _amountPaidController.text = _totalAmount.toStringAsFixed(2);
      }
    });
  }

  void _submit() async {
    setState(() {
      _showSupplierError = _selectedSupplierId == null;
      _showProductError = _purchasedItems.isEmpty;
    });

    if (_showSupplierError) {
      SnackBarUtils.showSnackBar(
        context,
        'Please select a supplier',
        isError: true,
      );
      return;
    }
    if (_showProductError) {
      SnackBarUtils.showSnackBar(
        context,
        'Please add at least one product',
        isError: true,
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final String rawInvoice = _invoiceController.text.trim();
    final String invoiceNumber = rawInvoice.isEmpty
        ? 'PUR-${DateFormat('yyMMdd-HHmmss').format(DateTime.now())}'
        : rawInvoice;

    final provider = Provider.of<PurchaseProvider>(context, listen: false);
    // Serialize items: Strip TextEditingControllers which cannot be JSON-encoded.
    final serializedItems = _purchasedItems.map((item) => <String, dynamic>{
      'productId': item['productId'],
      'name': item['name'],
      'productName': item['name'],
      'quantity': item['quantity'],
      'unit': item['unit'],
      'costPrice': item['costPrice'],
      'unitPrice': item['costPrice'],
    }).toList();

    final success = await provider.addPurchase({
      'supplierId': _selectedSupplierId,
      'supplierName': _selectedSupplierName,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': _selectedDate.toIso8601String(),
      'items': serializedItems,
      'subtotal': _subtotal,
      'tax': _tax,
      'totalAmount': _totalAmount,
      'amountPaid': _amountPaid,
      'remaining': _remaining,
      'notes': _notesController.text.trim(),
      'status': _paymentStatus.toLowerCase(),
      'paymentMethod': _paymentMethod.toLowerCase(),
    });
    if (success && mounted) {
      final productProvider = context.read<ProductProvider>();
      
      // Reset state BEFORE fetching new data to prevent UI glitches during rebuilt.
      setState(() {
        _isSubmitting = false;
        _selectedSupplierId = null;
        _purchasedItems.clear();
        _invoiceController.clear();
        _taxController.clear();
        _amountPaidController.clear();
      });

      // Stock reconciliation: Ensure local product list matches server after batch purchase.
      // NOTE: Increased delay to ensure backend transaction commit is fully replicated 
      // before the fresh fetch occurs, preventing stale stock counts.
      await Future.delayed(const Duration(milliseconds: 1000));
      await productProvider.fetchProducts();

      // Refresh dashboard statistics on Home Screen to update "Total Inventory Value" etc.
      MainShell.homeKey.currentState?.refresh();
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else if (mounted) {
      setState(() => _isSubmitting = false);
      SnackBarUtils.showSnackBar(
        context,
        provider.error ?? 'Failed to record purchase',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isReadOnly ? 'Purchase Details' : 'Record Purchase',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
        actions: [
          if (_isReadOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.receipt_long, color: AppColors.primary),
                onPressed: () {
                  final owner = context.read<AuthProvider>().currentOwner;
                  SupplierExportUtils.exportPaymentReceiptPdf(widget.purchase!, owner: owner);
                },
                tooltip: 'Export Receipt',
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Section 1: Supplier & Logistics ---
              _buildSectionHeader(Icons.local_shipping_outlined, 'Partner & Logistics'),
              const SizedBox(height: 16),
              _buildFormCard([
                _buildLabel('Select Supplier *'),
                const SizedBox(height: 8),
                Consumer<SupplierProvider>(
                  builder: (context, supplierProvider, _) {
                    if (supplierProvider.isLoading && supplierProvider.suppliers.isEmpty) {
                      return _buildLoadingDropdown('Syncing suppliers...');
                    }
                    return Container(
                      decoration: _inputBoxDecoration(
                        borderColor: _showSupplierError ? AppColors.error : Colors.transparent,
                        bgColor: _isReadOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedSupplierId,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Choose a business partner'),
                          ),
                          items: supplierProvider.suppliers.map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(s.name, style: GoogleFonts.poppins(fontSize: 14)),
                            ),
                          )).toList(),
                          onChanged: _isReadOnly ? null : (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedSupplierId = value;
                              final supplier = supplierProvider.suppliers.firstWhere((s) => s.id == value);
                              _selectedSupplierName = supplier.name;
                              _showSupplierError = false;
                            });
                          },
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Invoice #'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _invoiceController,
                            enabled: !_isReadOnly,
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: _inputDecoration(
                              hint: 'Auto-generated',
                              icon: Icons.description_outlined,
                              isReadOnly: _isReadOnly,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Purchase Date'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _isReadOnly ? null : () => _selectDate(context),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _dateController,
                                enabled: !_isReadOnly,
                                style: GoogleFonts.poppins(fontSize: 14),
                                decoration: _inputDecoration(
                                  hint: 'Select Date',
                                  icon: Icons.calendar_today_outlined,
                                  isReadOnly: _isReadOnly,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 24),
              // --- Section 2: Inventory Intake ---
              _buildSectionHeader(Icons.inventory_2_outlined, 'Stock Intake'),
              const SizedBox(height: 16),
              if (!_isReadOnly) ...[
                _buildProductSelector(),
                const SizedBox(height: 16),
              ],

              if (_isLoadingDetails) ...[
                _buildLoadingState('Fetching inventory details...'),
              ] else if (_purchasedItems.isEmpty) ...[
                _buildEmptyState(),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _purchasedItems.length,
                  itemBuilder: (context, index) => _buildPurchasedItemCard(index, _purchasedItems[index]),
                ),
              ],

              const SizedBox(height: 24),
              // --- Section 3: Financial Settlement ---
              _buildSectionHeader(Icons.account_balance_wallet_outlined, 'Financial Settlement'),
              const SizedBox(height: 16),
              _buildFormCard([
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Payment Status'),
                          const SizedBox(height: 8),
                          Container(
                            decoration: _inputBoxDecoration(
                              bgColor: _isReadOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _paymentStatus,
                                items: ['Paid', 'Partial', 'Pending'].map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(status, style: GoogleFonts.poppins(fontSize: 14)),
                                  ),
                                )).toList(),
                                onChanged: _isReadOnly ? null : (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _paymentStatus = value;
                                    if (value == 'Paid') {
                                      _amountPaidController.text = _totalAmount.toStringAsFixed(2);
                                    } else if (value == 'Pending') {
                                      _amountPaidController.text = '0';
                                    }
                                  });
                                },
                                icon: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Method'),
                          const SizedBox(height: 8),
                          Container(
                            decoration: _inputBoxDecoration(
                              bgColor: _isReadOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _paymentMethod,
                                items: ['Cash', 'Credit', 'Bank Transfer', 'App Transfer'].map((method) => DropdownMenuItem(
                                  value: method,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(method, style: GoogleFonts.poppins(fontSize: 14)),
                                  ),
                                )).toList(),
                                onChanged: _isReadOnly ? null : (value) {
                                  if (value != null) setState(() => _paymentMethod = value);
                                },
                                icon: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Amount Paid'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountPaidController,
                            enabled: !_isReadOnly && _paymentStatus == 'Partial',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                            decoration: _inputDecoration(
                              hint: '0.00',
                              icon: Icons.payments_outlined,
                              isReadOnly: _isReadOnly || _paymentStatus != 'Partial',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Tax/Other'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _taxController,
                            enabled: !_isReadOnly,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.poppins(fontSize: 14),
                            decoration: _inputDecoration(
                              hint: '0.00',
                              icon: Icons.receipt_outlined,
                              isReadOnly: _isReadOnly,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),

              const SizedBox(height: 24),
              // --- Section 4: Remarks ---
              _buildSectionHeader(Icons.notes_outlined, 'Additional Remarks'),
              const SizedBox(height: 16),
              _buildFormCard([
                TextField(
                  controller: _notesController,
                  enabled: !_isReadOnly,
                  maxLines: 2,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: _inputDecoration(
                    hint: 'Add internal notes or specific purchase terms...',
                    icon: Icons.edit_note_outlined,
                    isReadOnly: _isReadOnly,
                  ),
                ),
              ]),

              const SizedBox(height: 32),
              // --- Final Summary Section ---
              _buildPremiumSummary(),

              const SizedBox(height: 40),

              if (_isReadOnly)
                _buildLockedState()
              else
                _buildSubmitButton(),
              
              const SizedBox(height: 24),
            ],
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
            color: AppColors.primary.withValues(alpha: 0.1),
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

  InputDecoration _inputDecoration({required String hint, required IconData icon, bool isReadOnly = false}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textLight.withValues(alpha: 0.5), size: 20),
      filled: true,
      fillColor: isReadOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF1F5F9).withValues(alpha: 0.5),
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
    );
  }

  BoxDecoration _inputBoxDecoration({Color? borderColor, Color? bgColor}) {
    return BoxDecoration(
      color: bgColor ?? const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? Colors.transparent, width: 1.5),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.textDark.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildPremiumSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', 'Rs ${_subtotal.toStringAsFixed(2)}', opacity: 0.8),
          const SizedBox(height: 12),
          _buildSummaryRow('Tax & Fees', 'Rs ${_tax.toStringAsFixed(2)}', opacity: 0.8),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Liability',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                'Rs ${_totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Amount Settled', 'Rs ${_amountPaid.toStringAsFixed(2)}', opacity: 0.9),
          const SizedBox(height: 8),
          _buildSummaryRow('Pending Balance', 'Rs ${_remaining.toStringAsFixed(2)}', 
            isBold: true, 
            valueColor: _remaining > 0 ? const Color(0xFFFECACA) : Colors.white70
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {double opacity = 1.0, bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: opacity), fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: valueColor ?? Colors.white.withValues(alpha: opacity), 
            fontSize: isBold ? 15 : 13, 
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600
          ),
        ),
      ],
    );
  }

  Widget _buildProductSelector() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        return Container(
          decoration: _inputBoxDecoration(
            borderColor: _showProductError ? AppColors.error : Colors.transparent,
            bgColor: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: null,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  productProvider.isLoading ? 'Syncing catalogue...' : 'Select product to restock',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
              icon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  productProvider.isLoading ? Icons.sync : Icons.add_circle_outline_rounded, 
                  color: AppColors.primary
                ),
              ),
              items: productProvider.products.map((p) => DropdownMenuItem(
                value: p.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(p.name, style: GoogleFonts.poppins(fontSize: 14)),
                ),
              )).toList(),
              onChanged: (productId) {
                if (productId != null) {
                  final product = productProvider.products.firstWhere((p) => p.id == productId);
                  _addItem(product);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPurchasedItemCard(int index, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['name'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark),
                ),
              ),
              if (!_isReadOnly)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: () => _removeItem(index),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildItemInput(
                  label: 'Qty (${item['unit']})',
                  controller: item['qtyController'],
                  onChanged: (v) => _updateItem(index, quantity: int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildItemInput(
                  label: 'Cost Price',
                  controller: item['costController'],
                  prefix: 'Rs ',
                  onChanged: (v) => _updateItem(index, costPrice: double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
                    const SizedBox(height: 6),
                    Text(
                      'Rs ${((item['quantity'] ?? 0) * (item['costPrice'] ?? 0.0)).toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemInput({required String label, required TextEditingController controller, String? prefix, required Function(String) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: !_isReadOnly,
          keyboardType: TextInputType.number,
          onChanged: (v) => onChanged(v),
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _isReadOnly ? AppColors.textMedium : AppColors.textDark),
          decoration: InputDecoration(
            isDense: true,
            prefixText: prefix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 58,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: _isSubmitting
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text('Record Transaction', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildLockedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: AppColors.textLight, size: 18),
          const SizedBox(width: 12),
          Text(
            'This record is locked for auditing',
            style: GoogleFonts.poppins(color: AppColors.textLight, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(message, style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.add_shopping_cart_rounded, size: 48, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text('No items added yet', style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDropdown(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _inputBoxDecoration(),
      child: Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          const SizedBox(width: 12),
          Text(hint, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight)),
        ],
      ),
    );
  }
}

