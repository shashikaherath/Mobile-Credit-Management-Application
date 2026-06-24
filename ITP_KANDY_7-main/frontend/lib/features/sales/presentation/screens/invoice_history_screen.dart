// ------------------------------------------------------------------------------
// File: invoice_history_screen.dart
// Purpose: Historical Transaction Archive and Audit Interface.
// Rationale: Provides a chronologically organized, searchable repository of all 
//   completed sales. Features infinite scroll pagination, local filtering, 
//   and drill-down capabilities for administrative transaction review.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:intl/intl.dart'; // Formatting: Date localization
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/features/sales/presentation/providers/sale_provider.dart'; // State: Sales data manager
import 'package:frontend/features/products/presentation/providers/product_provider.dart'; // Sync: Inventory restoration
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart'; // Sync: Debt reconciliation
import 'package:frontend/features/sales/presentation/screens/invoice_dialog.dart'; // UI: Receipt detail modal
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger

class InvoiceHistoryScreen extends StatefulWidget {
  final String? initialInvoiceId;
  const InvoiceHistoryScreen({super.key, this.initialInvoiceId});

  @override
  State<InvoiceHistoryScreen> createState() => InvoiceHistoryScreenState();
}

class InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SaleProvider>().fetchSales();
      }
    });
  }

  void _onScroll() {
    // Lazy Loading: Trigger more data fetch when user nears the bottom of the list
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _searchQuery.isEmpty) {
      context.read<SaleProvider>().fetchSales(refresh: false); // Append to existing list
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // Prevent memory leaks from active listeners
    super.dispose();
  }

  void refresh() {
    if (mounted) {
      context.read<SaleProvider>().fetchSales(); // Full reset and reload from backend
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Invoice History', // Feature identifier
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(), // Filter controls
            Expanded(
              child: Consumer<SaleProvider>(
                builder: (context, provider, child) {
                  // Initial load shimmer or progress indicator
                  if (provider.isLoading && provider.sales.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  // Terminal error state during initial fetch
                  if (provider.error != null && provider.sales.isEmpty) {
                    return _buildErrorView(provider.error!);
                  }

                  // Real-time local filtering for fast UX
                  final filteredSales = provider.sales.where((sale) {
                    final query = _searchQuery.toLowerCase();
                    final customerName = (sale['customerName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final invoiceId = (sale['id'] ?? '').toString().toLowerCase();
                    return customerName.contains(query) ||
                        invoiceId.contains(query);
                  }).toList();

                  if (filteredSales.isEmpty) {
                    return _buildEmptyView(); // Handling "no results" state
                  }

                  // Chronological Grouping: Organizes invoices into logical sub-lists by date
                  final groupedSales = <String, List<Map<String, dynamic>>>{};
                  for (var sale in filteredSales) {
                    final date = DateTime.parse(
                      sale['createdAt'] ?? DateTime.now().toString(),
                    ).toLocal();
                    final dateStr = DateFormat('yyyy-MM-dd').format(date);
                    if (!groupedSales.containsKey(dateStr)) {
                      groupedSales[dateStr] = [];
                    }
                    groupedSales[dateStr]!.add(sale);
                  }

                  // Sort dates descending (Newest first)
                  final sortedDates = groupedSales.keys.toList()
                    ..sort((a, b) => b.compareTo(a));

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchSales(), // Manual pull-to-refresh
                    color: AppColors.primary,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      itemCount: sortedDates.length + (provider.isFetchingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == sortedDates.length) {
                          // Infinite scroll loading indicator
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final dateStr = sortedDates[index];
                        final sales = groupedSales[dateStr]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateHeader(dateStr), // Section title (e.g. "Today")
                            SizedBox(height: 12),
                            ...sales
                                .map((sale) => _buildInvoiceCard(sale)), // Single transaction summary
                            SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Semantic date header for UI sections
  Widget _buildDateHeader(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String displayDate;
    if (date == today) {
      displayDate = 'Today';
    } else if (date == yesterday) {
      displayDate = 'Yesterday';
    } else {
      displayDate = DateFormat('EEEE, dd MMM yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        displayDate,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Search input area with integrated filtering trigger
  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      color: AppColors.surface,
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value), // Real-time state local update
        decoration: InputDecoration(
          hintText: 'Search by Customer or Invoice ID...',
          prefixIcon: Icon(Icons.search, color: AppColors.textLight),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  // Transaction summary item: Includes tap-to-expand details
  Widget _buildInvoiceCard(Map<String, dynamic> sale) {
    final date = DateTime.parse(sale['createdAt'] ?? DateTime.now().toString()).toLocal();
    final formattedTime = DateFormat('hh:mm a').format(date);
    final amount = (sale['totalAmount'] ?? 0.0).toDouble();
    final customerName = sale['customerName'] ?? 'Walk-in Customer';
    final invoiceId = sale['id']?.toString().toUpperCase() ?? 'N/A';
    final paymentMethod = sale['paymentMethod'] ?? 'cash';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Launches the full pixel-perfect PDF / Detail view dialog
            showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel: '',
              pageBuilder: (context, anim1, anim2) =>
                  InvoiceDialog(saleDetails: sale),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Activity Icon: Visual type identifier
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName, // Target account
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '#$invoiceId • $formattedTime', // Transaction metadata
                        style: GoogleFonts.poppins(
                          color: AppColors.textMedium,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 4),
                      _buildPaymentBadge(paymentMethod), // Visual method tag
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Rs. ${amount.toStringAsFixed(2)}', // Total value
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Quick-action for record correction
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showDeleteConfirmation(sale['id']),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Confirmation flow to prevent accidental record removal
  void _showDeleteConfirmation(String saleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Invoice'),
        content: Text(
          'Are you sure you want to delete this invoice? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                // Logic: Destructive record reversal.
                // Rationale: We capture the sale type BEFORE deletion to know which domains to refresh.
                final saleToDelete = context.read<SaleProvider>().sales.firstWhere((s) => s['id'] == saleId, orElse: () => null);
                final isCreditSale = saleToDelete != null && saleToDelete['paymentMethod'] == 'credit';

                await context.read<SaleProvider>().deleteSale(saleId);
                
                if (context.mounted) {
                  // Strategy: Synchronization Delay.
                  // Rationale: Wait for backend write-lock release and stock indices to update before fetching.
                  await Future.delayed(const Duration(milliseconds: 1000));
                  
                  if (context.mounted) {
                    // Sync: Restore inventory levels in the main product catalog.
                    context.read<ProductProvider>().fetchProducts(refresh: true);
                    
                    // Sync: Reconcile customer debt if the reversed sale was a credit transaction.
                    if (isCreditSale) {
                      context.read<CreditProvider>().fetchCustomers();
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice deleted and stock restored')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // Visual tag builder for payment method classification
  Widget _buildPaymentBadge(String method) {
    final isCredit = method.toLowerCase() == 'credit';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isCredit ? Colors.orange : AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        method.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: isCredit ? Colors.orange.shade800 : AppColors.primary,
        ),
      ),
    );
  }

  // Fallback screen for network or server-side issues
  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            SizedBox(height: 16),
            Text(
              'Failed to load history\n$error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.textMedium),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: refresh, // Manual retry trigger
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textLight.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No invoices found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

