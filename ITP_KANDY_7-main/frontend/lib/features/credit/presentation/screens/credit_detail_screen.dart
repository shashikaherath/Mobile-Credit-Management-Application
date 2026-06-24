// ------------------------------------------------------------------------------
// File: credit_detail_screen.dart
// Purpose: Unified Financial Ledger and Debt Lifecycle Monitor.
// Rationale: Merges diverse transaction types (Credit, Payments, Sales) into 
//   a single chronological timeline for deep-dive customer audits. Supports 
//   payment reconciliation, automated statement generation, and proactive 
//   balance monitoring with administrative guards.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Flutter Material widgets
import 'package:google_fonts/google_fonts.dart'; // UI: Poppins typography
import 'package:provider/provider.dart'; // State: Provider read/watch
import 'package:intl/intl.dart'; // Format: Date and currency formatting
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Brand colour tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // UX: Feedback toasts with diagnostics
import 'package:frontend/features/credit/domain/entities/customer.dart'; // Domain: Customer model
import 'package:frontend/features/credit/domain/entities/credit_transaction.dart'; // Domain: Ledger entry model
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart'; // State: Customer data manager
import 'package:frontend/features/sales/presentation/providers/sale_provider.dart'; // State: Sales history for ledger merge
import 'package:frontend/features/sales/presentation/screens/invoice_dialog.dart'; // Navigation: Sale invoice detail
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart'; // State: In-app alert logging
import 'package:frontend/features/credit/presentation/utils/credit_pdf_utils.dart'; // PDF: Customer statement generator
import 'package:frontend/shared/widgets/modern_pdf_icon.dart'; // UI: Brand-consistent PDF trigger icon
import 'package:frontend/shared/main_shell.dart'; // Shell: Global app state anchor for dashboard refresh
import 'package:frontend/shared/widgets/app_back_button.dart'; // UI: Standardized navigation trigger
import 'package:frontend/shared/widgets/tactile_scale.dart'; // UI: Interaction physics
import 'package:animate_do/animate_do.dart'; // UI: Motion design framework
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // Auth: User context
import 'package:url_launcher/url_launcher.dart'; // External: Native communication triggers

/// CreditDetailScreen: An in-depth financial ledger for a specific customer.
/// Displays a unified chronological view of sales, payments, and credit adjustments.
class CreditDetailScreen extends StatefulWidget {
  final Customer customer;
  const CreditDetailScreen({super.key, required this.customer});

  @override
  State<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends State<CreditDetailScreen> {
  late Customer _currentCustomer;
  final ScrollController _scrollController = ScrollController();

  void _handleCall() async {
    final Uri url = Uri.parse('tel:${_currentCustomer.phone}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) SnackBarUtils.showSnackBar(context, 'Could not launch dialer', isError: true);
    }
  }

  void _handleWhatsApp() async {
    // Basic international format check
    String phone = _currentCustomer.phone.replaceAll(RegExp(r'\D'), '');
    if (!phone.startsWith('94') && phone.length == 9) {
      phone = '94$phone';
    } else if (phone.startsWith('0')) {
      phone = '94${phone.substring(1)}';
    }
    
    final Uri url = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) SnackBarUtils.showSnackBar(context, 'Could not launch WhatsApp', isError: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final creditProvider = Provider.of<CreditProvider>(context, listen: false);
        final saleProvider = Provider.of<SaleProvider>(context, listen: false);
        
        creditProvider.fetchCustomers();
        creditProvider.fetchTransactions(_currentCustomer.id);
        saleProvider.fetchSalesByCustomer(_currentCustomer.id);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final creditProvider = context.read<CreditProvider>();
      final saleProvider = context.read<SaleProvider>();

      if (creditProvider.hasMoreTransactions && !creditProvider.isFetchingMoreTransactions) {
        creditProvider.fetchTransactions(_currentCustomer.id, refresh: false);
      }
      if (saleProvider.hasMore && !saleProvider.isFetchingMore) {
        saleProvider.fetchSalesByCustomer(_currentCustomer.id, refresh: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentCustomer.name),
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
        actions: [
          IconButton(
            icon: const ModernPdfIcon(),
            onPressed: () {
              final creditProvider = context.read<CreditProvider>();
              final saleProvider = context.read<SaleProvider>();
              
              // Filter logic to unify disparate data streams for the PDF statement.
              final customerSales = saleProvider.sales.where((sale) {
                if (sale is Map) {
                  return sale['customerId'] == _currentCustomer.id;
                }
                return false;
              }).toList();

              // Exclude automated system transactions that pollute the human-readable statement.
              final filteredTransactions = creditProvider.transactions.where(
                (txn) => !(txn.type == 'credit' && txn.title.startsWith('Purchase Loan')) &&
                         !(txn.type == 'payment' && (txn.title == 'Full Balance Settlement' || txn.title == 'Partial Credit Payment')),
              ).toList();

              final List<dynamic> combined = [
                ...filteredTransactions,
                ...customerSales,
              ];

              // Chronological sorting for financial auditing.
              combined.sort((a, b) {
                final dateA = DateTime.parse(a is Map ? a['createdAt'] : a.createdAt).toLocal();
                final dateB = DateTime.parse(b is Map ? b['createdAt'] : b.createdAt).toLocal();
                return dateB.compareTo(dateA);
              });


              final owner = context.read<AuthProvider>().currentOwner;
              CreditPdfUtils.generateAndDownloadStatement(
                customer: _currentCustomer,
                history: combined,
                owner: owner,
              );
            },
            tooltip: 'Download Statement',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Consumer2<CreditProvider, SaleProvider>(
          builder: (context, provider, saleProvider, _) {
            // Chronological Merger: Sorting disparate data sources for the ledger view
            final customerSales = saleProvider.sales.where((sale) {
              if (sale is Map) {
                return sale['customerId'] == _currentCustomer.id;
              }
              return false;
            }).toList();

            // Real-time synchronization: Update the local entity if the provider data changes.
            final updatedCustomer = provider.customers.isEmpty
                ? null
                : provider.customers.cast<Customer?>().firstWhere(
                    (c) => c?.id == _currentCustomer.id,
                    orElse: () => null,
                  );

            if (updatedCustomer != null) {
              _currentCustomer = updatedCustomer;
            }

            // Noise Reduction: Filter out system-generated metadata transactions for cleaner UI.
            final filteredTransactions = provider.transactions.where(
              (txn) => !(txn.type == 'credit' && txn.title.startsWith('Purchase Loan')) &&
                       !(txn.type == 'payment' && (txn.title == 'Full Balance Settlement' || txn.title == 'Partial Credit Payment')),
            ).toList();

            return SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer header card: Premium Financial Identity Card
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0F172A), // Slate 900
                            Color(0xFF1E293B), // Slate 800
                            Color(0xFF334155), // Slate 700
                          ],
                        ),
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Stack(
                          children: [
                            // Abstract Premium Patterns
                            Positioned(
                              top: -40,
                              right: -40,
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  // Premium Identity Block
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 32,
                                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                                          child: Text(
                                            _currentCustomer.name.isNotEmpty
                                                ? _currentCustomer.name[0].toUpperCase()
                                                : '?',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _currentCustomer.name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _currentCustomer.phone,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white.withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildHeaderBadge(
                                        _currentCustomer.totalOutstanding <= 0 ? 'CLEAN' : 'DEBTOR',
                                        _currentCustomer.totalOutstanding <= 0 ? Colors.greenAccent.shade700 : Colors.orange,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  // Modern Stats Grid
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildPremiumStatNode(
                                          'TOTAL DEBT',
                                          'Rs.${_currentCustomer.totalOutstanding.toStringAsFixed(0)}',
                                          Icons.account_balance_wallet_rounded,
                                          _currentCustomer.totalOutstanding > 0 ? Colors.orange : Colors.greenAccent.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildPremiumStatNode(
                                          'CREDIT LIMIT',
                                          'Rs.${_currentCustomer.creditLimit.toStringAsFixed(0)}',
                                          Icons.speed_rounded,
                                          Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 28),
                                  // Quick Action Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildCircularAction(
                                        onTap: _handleCall,
                                        icon: Icons.phone_rounded,
                                        label: 'Call',
                                      ),
                                      _buildCircularAction(
                                        onTap: _handleWhatsApp,
                                        icon: Icons.chat_bubble_rounded,
                                        label: 'WhatsApp',
                                      ),
                                      _buildCircularAction(
                                        onTap: () => _showEditCustomerDialog(context),
                                        icon: Icons.edit_rounded,
                                        label: 'Edit',
                                      ),
                                      _buildCircularAction(
                                        onTap: () => _showDeleteConfirmation(context),
                                        icon: Icons.delete_outline_rounded,
                                        label: 'Delete',
                                      ),
                                      _buildCircularAction(
                                        onTap: () => _showSettleConfirmation(context),
                                        icon: Icons.check_circle_rounded,
                                        label: 'Settle',
                                        isPrimary: true,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // History section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'History & Invoices',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      if (provider.isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),

                  if (!provider.isLoading &&
                      !saleProvider.isLoading &&
                      filteredTransactions.isEmpty &&
                      customerSales.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey.shade200,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No history found',
                              style: GoogleFonts.poppins(color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildCombinedHistory(context, filteredTransactions, customerSales, provider.isFetchingMoreTransactions || saleProvider.isFetchingMore),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'credit_add_transaction_btn',
        onPressed: () => _showAddTransactionDialog(context),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPremiumStatNode(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularAction({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        TactileScale(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              boxShadow: isPrimary ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ] : null,
            ),
            child: Icon(
              icon,
              color: isPrimary ? const Color(0xFF0F172A) : Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildCombinedHistory(BuildContext context, List<CreditTransaction> transactions, List<dynamic> customerSales, bool isFetchingMore) {
    // Combine sales and transactions into a single list sorted by date
    final List<dynamic> combined = [
      ...transactions,
      ...customerSales,
    ];

    combined.sort((a, b) {
      final dateA = DateTime.parse(a is Map ? a['createdAt'] : a.createdAt).toLocal();
      final dateB = DateTime.parse(b is Map ? b['createdAt'] : b.createdAt).toLocal();
      return dateB.compareTo(dateA);
    });

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: combined.length,
          itemBuilder: (context, index) {
            final item = combined[index];
            if (item is Map) {
              return _buildSaleCard(Map<String, dynamic>.from(item));
            } else {
              return _buildTransactionCard(item);
            }
          },
        ),
        if (isFetchingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
  }

  Widget _buildSaleCard(Map<String, dynamic> sale) {
    final date = DateTime.parse(sale['createdAt'] ?? DateTime.now().toString()).toLocal();
    final formattedTime = DateFormat('hh:mm a').format(date);
    final amount = (sale['totalAmount'] ?? 0.0).toDouble();
    final customerName = sale['customerName'] ?? 'Walk-in Customer';
    final invoiceId = sale['id']?.toString().toUpperCase() ?? 'N/A';
    final paymentMethod = sale['paymentMethod'] ?? 'credit';
    final isCredit = paymentMethod.toLowerCase() == 'credit';

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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isCredit ? Colors.orange : AppColors.primary).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: isCredit ? Colors.orange : AppColors.primary,
                    size: 22,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '#${invoiceId.length > 5 ? invoiceId.substring(0, 5) : invoiceId} • $formattedTime',
                        style: GoogleFonts.poppins(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 4),
                      _buildPaymentBadge(paymentMethod),
                    ],
                  ),
                ),
                Text(
                  '${isCredit ? '-' : ''} Rs ${amount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isCredit ? AppColors.error : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildTransactionCard(dynamic txn) {
    final date = DateTime.parse(txn.createdAt).toLocal();
    final isPayment = txn.type == 'payment';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPayment
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPayment
                  ? Icons.account_balance_wallet_outlined
                  : Icons.info_outline,
              color: isPayment ? AppColors.primary : AppColors.error,
              size: 20,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  DateFormat('dd MMM, hh:mm a').format(date),
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
          Text(
            '${isPayment ? '+' : '-'} Rs ${txn.amount.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isPayment ? AppColors.primary : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettleConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Settle Balance'),
        content: Text(
          'Confirm payment of Rs ${_currentCustomer.totalOutstanding.toStringAsFixed(0)} for ${_currentCustomer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Multi-provider settlement: Clearing debt across logic layers.
              await context.read<CreditProvider>().settleFullBalance(
                _currentCustomer,
              );
              if (context.mounted) {
                // Background cache invalidation to keep the app shell consistent.
                context.read<NotificationProvider>().fetchNotifications();
                context.read<SaleProvider>().fetchSales();
                
                // Refresh dashboard statistics on Home Screen
                MainShell.homeKey.currentState?.refresh();

                SnackBarUtils.showSnackBar(
                  context,
                  'Credit settled successfully',
                );
              }
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showEditCustomerDialog(BuildContext context) {
    final nameController = TextEditingController(text: _currentCustomer.name);
    final phoneController = TextEditingController(text: _currentCustomer.phone);
    final limitController = TextEditingController(
      text: _currentCustomer.creditLimit.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Customer name'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(hintText: 'Phone number'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Credit Limit (Rs)',
                prefixText: 'Rs ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final double? limit = double.tryParse(limitController.text);
                // Synchronous update triggering local state rebuild via Provider.
                final success =
                    await Provider.of<CreditProvider>(
                      context,
                      listen: false,
                    ).updateCustomer(_currentCustomer.id, {
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'creditLimit': limit ?? _currentCustomer.creditLimit,
                    });

                if (context.mounted) {
                  if (success) {
                    SnackBarUtils.showSnackBar(
                      context,
                      'Customer updated successfully',
                    );
                    Navigator.pop(ctx);
                  } else {
                    SnackBarUtils.showSnackBar(
                      context,
                      context.read<CreditProvider>().error ??
                          'Failed to update customer',
                      isError: true,
                    );
                  }
                }
              }
            },
            child: Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Customer', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          _currentCustomer.totalOutstanding > 0
              ? 'Warning: This customer has Rs ${_currentCustomer.totalOutstanding.toStringAsFixed(0)} outstanding credit. Are you sure you want to delete them?'
              : 'Are you sure you want to delete ${_currentCustomer.name}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final id = _currentCustomer.id;
              final success = await Provider.of<CreditProvider>(
                context,
                listen: false,
              ).deleteCustomer(id);
              if (context.mounted) {
                if (success) {
                  SnackBarUtils.showSnackBar(
                    context,
                    'Customer deleted successfully',
                  );
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Go back from detail screen
                } else {
                  SnackBarUtils.showSnackBar(
                    context,
                    context.read<CreditProvider>().error ??
                        'Failed to delete customer',
                    isError: true,
                  );
                }
              }
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'credit';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'credit', label: Text('Credit')),
                  ButtonSegment(value: 'payment', label: Text('Payment')),
                ],
                selected: {type},
                onSelectionChanged: (v) => setDialogState(() => type = v.first),
              ),
              SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Description'),
              ),
              SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Amount'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  await Provider.of<CreditProvider>(
                    context,
                    listen: false,
                  ).addTransaction({
                    'customerId': widget.customer.id,
                    'type': type,
                    'title': titleController.text.trim(),
                    'amount': amount,
                  });
                  if (!context.mounted) return;
                  if (ctx.mounted) Navigator.pop(ctx);
                  context.read<CreditProvider>().fetchTransactions(
                    widget.customer.id,
                  );

                  // Refresh dashboard statistics on Home Screen
                  MainShell.homeKey.currentState?.refresh();
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

