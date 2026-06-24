// ------------------------------------------------------------------------------
// File: credit_list_screen.dart
// Purpose: Dual-purpose CRM and Credit Selection Interface.
// Rationale: Serves as the central repository for customer relationship
//   management, supporting standalone profile administration (Add/Edit/Delete)
//   and real-time debtor identification. Operates in 'Selection Mode' for
//   POS checkout flows and provides deep-link navigation to customer ledgers.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Flutter Material widgets
import 'package:google_fonts/google_fonts.dart'; // UI: Poppins typography
import 'package:provider/provider.dart'; // State: Provider read/watch
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Brand colour tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // UX: Feedback toasts with diagnostics
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart'; // State: Customer data manager
import 'package:frontend/features/credit/domain/entities/customer.dart'; // Domain: Customer model
import 'package:frontend/features/credit/presentation/screens/credit_detail_screen.dart'; // Navigation: Customer ledger
import 'package:frontend/features/credit/presentation/utils/export_utils.dart'; // PDF: Batch credit export
import 'package:frontend/core/utils/validation_utils.dart'; // Util: Form field validators
import 'package:frontend/shared/widgets/modern_pdf_icon.dart'; // UI: Brand-consistent PDF trigger icon
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity management
import 'package:frontend/shared/widgets/screen_header.dart'; // UI: Reusable page header

/// CreditListScreen: A dual-purpose screen for managing customer credit.
/// Works as both a standalone CRM view and a selection picker for the checkout flow.
class CreditListScreen extends StatefulWidget {
  final bool isSelectionMode;

  const CreditListScreen({super.key, this.isSelectionMode = false});

  @override
  State<CreditListScreen> createState() => _CreditListScreenState();
}

class _CreditListScreenState extends State<CreditListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initial data load on mount.
      if (mounted) context.read<CreditProvider>().fetchCustomers();
    });
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Pagination trigger when reaching the 200px threshold from bottom.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CreditProvider>().fetchCustomers(refresh: false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handlePdfExport(BuildContext context) {
    final provider = context.read<CreditProvider>();
    final owner = context.read<AuthProvider>().currentOwner;
    // Branching export logic based on active tab view.
    if (_tabController.index == 0) {
      final outstanding = provider.outstandingCustomers;
      if (outstanding.isNotEmpty) {
        CreditExportUtils.exportActiveCreditsPdf(outstanding, owner: owner);
      } else {
        SnackBarUtils.showSnackBar(context, 'No active credit users to export');
      }
    } else {
      final settled = provider.settledCustomers;
      if (settled.isNotEmpty) {
        CreditExportUtils.exportSettledCreditsPdf(settled, owner: owner);
      } else {
        SnackBarUtils.showSnackBar(context, 'No settled customers to export');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ScreenHeader(
                  title: 'Customer Credit',
                  showBackButton:
                      widget.isSelectionMode || Navigator.canPop(context),
                  onBack: () => Navigator.pop(context),
                  action: const ModernPdfIcon(),
                  onActionTap: () => _handlePdfExport(context),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textDark.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMedium,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(
                      text: 'Credit Users',
                    ), // Displaying customers with active liabilities
                    Tab(
                      text: 'Settled / Paid',
                    ), // Displaying customers with zero balances
                  ],
                ),
              ),
              Expanded(
                child: Consumer<CreditProvider>(
                  builder: (context, provider, _) {
                    // Auto-trigger: Opens the "Add New Customer" dialog if signaled from the Home screen.
                    if (provider.shouldOpenAddCustomer) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _showAddCustomerDialog(context);
                          provider.setShouldOpenAddCustomer(false);
                        }
                      });
                    }
                    // Guard: Initial data retrieval state
                    if (provider.isLoading && provider.customers.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Filtering Logic: Dynamic search across name and phone fields
                    final outstanding = provider.outstandingCustomers.where((
                      c,
                    ) {
                      return c.name.toLowerCase().contains(_searchQuery) ||
                          c.phone.toLowerCase().contains(_searchQuery);
                    }).toList();

                    final settled = provider.settledCustomers.where((c) {
                      return c.name.toLowerCase().contains(_searchQuery) ||
                          c.phone.toLowerCase().contains(_searchQuery);
                    }).toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCustomerList(
                          context,
                          provider,
                          outstanding,
                          'No active credit users',
                        ),
                        _buildCustomerList(
                          context,
                          provider,
                          settled,
                          'No settled customers yet',
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'credit_add_customer_btn',
          onPressed: () =>
              _showAddCustomerDialog(context), // Registration entry point
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person_add, color: Colors.white),
        ),
        bottomNavigationBar: const SizedBox(
          height: 110,
        ), // Buffer to clear the floating navbar in MainShell
      ),
    );
  }

  Widget _buildCustomerList(
    BuildContext context,
    CreditProvider provider,
    List<Customer> customers,
    String emptyMessage,
  ) {
    return Column(
      children: [
        if (emptyMessage == 'No active credit users')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildSummaryCard(context),
          ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: Icon(Icons.search, color: AppColors.textLight),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.fetchCustomers,
            color: AppColors.primary,
            child: customers.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.5,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            emptyMessage,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppColors.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
                    itemCount:
                        customers.length + (provider.hasMoreCustomers ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == customers.length) {
                        return provider.isFetchingMoreCustomers
                            ? Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                      final customer = customers[index];
                      return GestureDetector(
                        onTap: () {
                          // Routing logic based on app context (Sales selection vs CRM view)
                          if (widget.isSelectionMode) {
                            Navigator.pop(context, customer);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CreditDetailScreen(customer: customer),
                              ),
                            ).then((_) {
                              // Conditional refresh on return to ensure data consistency
                              if (context.mounted) {
                                context.read<CreditProvider>().fetchCustomers();
                              }
                            });
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Premium Avatar Design
                                  Container(
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: customer.totalOutstanding > 0
                                            ? AppColors.error.withValues(alpha: 0.2)
                                            : AppColors.primary.withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: customer.totalOutstanding > 0
                                          ? AppColors.error.withValues(alpha: 0.05)
                                          : AppColors.primary.withValues(alpha: 0.05),
                                      child: Text(
                                        customer.name.isNotEmpty
                                            ? customer.name[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.poppins(
                                          color: customer.totalOutstanding > 0
                                              ? AppColors.error
                                              : AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          children: [
                                            Text(
                                              customer.name,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                color: AppColors.textDark,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.phone_rounded,
                                                  size: 12,
                                                  color: AppColors.textLight,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  customer.phone,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: AppColors.textLight,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildStatusBadge(
                                    customer.totalOutstanding,
                                    customer.creditLimit,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'OUTSTANDING',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textLight,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Rs ${customer.totalOutstanding.toStringAsFixed(0)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: customer.totalOutstanding > 0 
                                                ? AppColors.error 
                                                : AppColors.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        _buildCompactActionButton(
                                          onTap: () => _showEditCustomerDialog(context, customer),
                                          icon: Icons.edit_rounded,
                                          label: 'Edit',
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildCompactActionButton(
                                          onTap: () => _showDeleteConfirmation(context, customer),
                                          icon: Icons.delete_outline_rounded,
                                          label: 'Delete',
                                          color: Colors.red,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final limitController = TextEditingController(
      text: customer.creditLimit.toStringAsFixed(0),
    );
    final editFormKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Edit Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: editFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(
                controller: nameController,
                label: 'Customer Name',
                icon: Icons.person_outline,
                validator: (v) => ValidationUtils.validateName(v, fieldName: 'Name'),
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                controller: phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                controller: limitController,
                label: 'Credit Limit',
                icon: Icons.account_balance_wallet_outlined,
                prefixText: 'Rs ',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (editFormKey.currentState!.validate()) {
                final double? limit = double.tryParse(limitController.text);
                final success = await Provider.of<CreditProvider>(
                  context,
                  listen: false,
                ).updateCustomer(customer.id, {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'creditLimit': limit ?? customer.creditLimit,
                });
                if (context.mounted) {
                  if (success) {
                    SnackBarUtils.showSnackBar(
                      context,
                      'Customer updated successfully',
                    );
                    Navigator.pop(ctx);
                  } else {
                    final creditProvider = context.read<CreditProvider>();
                    SnackBarUtils.showSnackBar(
                      context,
                      creditProvider.error ?? 'Failed to update customer',
                      isError: true,
                      technicalDetails: creditProvider.technicalDetails,
                    );
                  }
                }
              }
            },
            child: Text(
              'Update',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        prefixText: prefixText,
        labelStyle: GoogleFonts.poppins(color: AppColors.textMedium),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Customer'),
        content: Text(
          // Conditional warning for active liabilities
          customer.totalOutstanding > 0
              ? 'Warning: This customer has Rs ${customer.totalOutstanding.toStringAsFixed(0)} active credit. Are you sure you want to delete them?'
              : 'Are you sure you want to delete ${customer.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              final success = await Provider.of<CreditProvider>(
                context,
                listen: false,
              ).deleteCustomer(customer.id);
              if (context.mounted) {
                if (success) {
                  SnackBarUtils.showSnackBar(
                    context,
                    'Customer deleted successfully',
                  );
                  Navigator.pop(ctx);
                } else {
                  final creditProvider = context.read<CreditProvider>();
                  SnackBarUtils.showSnackBar(
                    context,
                    creditProvider.error ?? 'Failed to delete customer',
                    isError: true,
                    technicalDetails: creditProvider.technicalDetails,
                  );
                }
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final provider = context.watch<CreditProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Active Credit', // Aggregate system liability
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Rs ${provider.totalOutstanding.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  provider.activeCredits.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Active',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(double outstanding, double limit) {
    String text;
    Color color;
    if (outstanding <= 0) {
      text = 'Paid';
      color = AppColors.primary;
    } else if (outstanding >= limit) {
      text = 'At Limit';
      color = AppColors.error;
    } else {
      text = 'Active';
      color = AppColors.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCompactActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final limitController = TextEditingController(text: '5000');
    final addFormKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add New Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: addFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(
                controller: nameController,
                label: 'Customer Name',
                icon: Icons.person_outline,
                validator: (v) => ValidationUtils.validateName(v, fieldName: 'Name'),
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                controller: phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildDialogField(
                controller: limitController,
                label: 'Credit Limit',
                icon: Icons.account_balance_wallet_outlined,
                prefixText: 'Rs ',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (addFormKey.currentState!.validate()) {
                final double? limit = double.tryParse(limitController.text);
                final newCustomerRef = {
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'creditLimit': limit ?? 5000.0,
                };
                final success = await Provider.of<CreditProvider>(
                  context,
                  listen: false,
                ).addCustomer(newCustomerRef);
                if (context.mounted) {
                  if (success) {
                    SnackBarUtils.showSnackBar(
                      context,
                      'Customer added successfully',
                    );
                    Navigator.pop(ctx);
                  } else if (ctx.mounted) {
                    final creditProvider = context.read<CreditProvider>();
                    SnackBarUtils.showSnackBar(
                      context,
                      creditProvider.error ?? 'Failed to add customer',
                      isError: true,
                      technicalDetails: creditProvider.technicalDetails,
                    );
                  }
                }
              }
            },
            child: Text(
              'Add Customer',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
