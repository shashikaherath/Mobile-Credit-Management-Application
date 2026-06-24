// ------------------------------------------------------------------------------
// File: supplier_management_screen.dart
// Purpose: Multi-Faceted Procurement Hub and Partner Logistics.
// Rationale: Centralizes the management of business partner profiles and 
//   restock history through a unified tabbed interface. Orchestrates 
//   cross-domain state refreshes during settlement workflows and provides 
//   context-aware reporting through segmented PDF export logic.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Flutter Material widgets
import 'package:google_fonts/google_fonts.dart'; // UI: Poppins typography
import 'package:provider/provider.dart'; // State: Provider read/watch
import 'package:intl/intl.dart'; // Format: Number formatting for currency
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Brand colour tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // UX: Feedback toasts with diagnostics
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart'; // State: Supplier data
import 'package:frontend/features/suppliers/presentation/providers/purchase_provider.dart'; // State: Purchase data
import 'package:frontend/features/suppliers/presentation/screens/add_supplier_screen.dart'; // Navigation: Add/edit partner
import 'package:frontend/features/suppliers/presentation/screens/record_purchase_screen.dart'; // Navigation: Purchase detail/entry
import 'package:frontend/features/suppliers/presentation/utils/export_utils.dart'; // PDF: Export supplier/purchase reports
import 'package:frontend/shared/widgets/modern_pdf_icon.dart'; // UI: Brand-consistent PDF trigger icon
import 'package:frontend/shared/widgets/screen_header.dart'; // UI: Reusable top-level screen header
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // Auth: User context
import 'package:frontend/features/products/presentation/providers/product_provider.dart'; // Sync: Inventory reversal
class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _purchaseScrollController = ScrollController();
  final ScrollController _supplierScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    _purchaseScrollController.addListener(_onPurchaseScroll);
    _supplierScrollController.addListener(_onSupplierScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Parallel fetch from different domains (Suppliers & Purchases).
      if (mounted) {
        context.read<SupplierProvider>().fetchSuppliers();
        context.read<PurchaseProvider>().fetchPurchases();
      }
    });
  }

  void _onPurchaseScroll() {
    if (_purchaseScrollController.position.pixels >=
        _purchaseScrollController.position.maxScrollExtent - 200) {
      context.read<PurchaseProvider>().fetchPurchases(refresh: false);
    }
  }

  void _onSupplierScroll() {
    if (_supplierScrollController.position.pixels >=
        _supplierScrollController.position.maxScrollExtent - 200) {
      context.read<SupplierProvider>().fetchSuppliers(refresh: false);
    }
  }

  Future<void> _handleRefresh() async {
    // Rationale: Simultaneous sync for both partner ledger and restock history.
    await Future.wait([
      context.read<SupplierProvider>().fetchSuppliers(),
      context.read<PurchaseProvider>().fetchPurchases(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _purchaseScrollController.dispose();
    _supplierScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
                SliverToBoxAdapter(
                  child: ScreenHeader(
                    title: 'Supplier Management',
                    subtitle: 'Manage partners & purchases',
                    showBackButton: true,
                    action: const ModernPdfIcon(),
                    onActionTap: () {
                      final owner = context.read<AuthProvider>().currentOwner;
                      // Branching export based on active tab context.
                      if (_tabController.index == 0) {
                        final suppliers =
                            context.read<SupplierProvider>().suppliers;
                        if (suppliers.isNotEmpty) {
                          SupplierExportUtils.exportSuppliersPdf(suppliers, owner: owner);
                        }
                      } else {
                        final purchases =
                            context.read<PurchaseProvider>().purchases;
                        if (purchases.isNotEmpty) {
                          SupplierExportUtils.exportPurchasesPdf(purchases, owner: owner);
                        }
                      }
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Consumer<SupplierProvider>(
                    builder: (context, provider, _) => _buildSummaryCards(provider),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true, // Keep the tabs visible while scrolling
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textLight,
                      dividerColor: Colors.transparent,
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      tabs: [
                        Tab(text: 'Suppliers'), // Navigation to partner directory
                        Tab(text: 'Purchase Records'), // Navigation to historical invoices
                      ],
                    ),
                  ),
                ),
              ];
            },
          body: TabBarView(
            controller: _tabController,
            children: [
              RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.primary,
                child: _buildSuppliersTab(),
              ),
              RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.primary,
                child: _buildPurchaseRecordsTab(),
              ),
            ],
          ),
        ),
      ),
      // Dynamic FAB: Changes function based on the currently active tab
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              heroTag: 'fab_supplier_prod_id_unique_1',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
              ).then((_) {
                // Refresh list to show new/updated partner
                if (context.mounted) {
                  context.read<SupplierProvider>().fetchSuppliers();
                }
              }),
              icon: Icon(Icons.person_add_outlined),
              label: Text('Add Supplier'), // Create logic for new partner registration
              backgroundColor: AppColors.primary,
            )
          : FloatingActionButton.extended(
              heroTag: 'fab_purchase_prod_id_unique_2',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecordPurchaseScreen(),
                ),
              ).then((_) {
                // Dual refresh: Update records and the resulting payable balance
                if (context.mounted) {
                  context.read<PurchaseProvider>().fetchPurchases();
                  context.read<SupplierProvider>().fetchSuppliers();
                }
              }),
              icon: Icon(Icons.add_shopping_cart_outlined),
              label: Text('Record New Purchase'), // Logic for inventory intake
               backgroundColor: AppColors.primary,
            ),
      bottomNavigationBar: const SizedBox(height: 80),
    );
  }

  Widget _buildSummaryCards(SupplierProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Active Suppliers',
              provider.suppliers.length.toString(),
              Icons.people_outline,
              [const Color(0xFF1E293B), const Color(0xFF334155)],
              isLoading: provider.isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Total Payable',
              'Rs ${NumberFormat('#,###').format(provider.totalPayable)}',
              Icons.account_balance_wallet_outlined,
              [const Color(0xFF059669), const Color(0xFF10B981)],
              isLoading: provider.isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    List<Color> colors, {
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersTab() {
    return Consumer<SupplierProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.suppliers.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        if (provider.suppliers.isEmpty) {
          return _buildEmptyState(
            'No Suppliers',
            'Start by adding your first supplier.',
            Icons.person_add_disabled_outlined,
          );
        }
        return ListView.builder(
          controller: _supplierScrollController,
          physics: const AlwaysScrollableScrollPhysics(), // Ensure refresh works on short lists
          padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 180),
          itemCount: provider.suppliers.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.suppliers.length) {
              return provider.isFetchingMore
                  ? Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink();
            }
            final supplier = provider.suppliers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppColors.textDark.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Supplier Avatar: Visual anchor for the card
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.person_outline,
                              color: AppColors.primary),
                        ),
                        SizedBox(width: 12),
                        // Supplier Identity: Name and reachability info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                supplier.name, // The registered trade name
                                style:
                                    GoogleFonts.poppins(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                supplier.phone, // Primary contact number
                                style: GoogleFonts.poppins(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddSupplierScreen(supplier: supplier),
                              ),
                            ).then((_) {
                              if (context.mounted) {
                                context.read<SupplierProvider>().fetchSuppliers();
                              }
                            });
                          },
                          icon: Icon(Icons.edit_rounded, size: 16),
                          label: Text(
                            'Edit',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                            backgroundColor: Colors.green.shade50,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _confirmDeleteSupplier(supplier),
                          icon: Icon(Icons.delete_outline_rounded, size: 16),
                          label: Text(
                            'Delete',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            backgroundColor: Colors.red.shade50,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPurchaseRecordsTab() {
    return Consumer<PurchaseProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.purchases.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        if (provider.purchases.isEmpty) {
          return _buildEmptyState(
            'No Records',
            'Your purchase history will appear here.',
            Icons.receipt_outlined,
          );
        }
        return ListView.builder(
          controller: _purchaseScrollController,
          physics: const AlwaysScrollableScrollPhysics(), // Ensure refresh works on short lists
          padding: const EdgeInsets.only(left: 24, right: 24, top: 12, bottom: 180),
          itemCount: provider.purchases.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.purchases.length) {
              return provider.isFetchingMore
                  ? Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : const SizedBox.shrink();
            }
            final purchase = provider.purchases[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppColors.textDark.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add_shopping_cart_outlined,
                              color: Colors.blue, size: 20),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                purchase.supplierName,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy').format(
                                    (DateTime.tryParse(purchase.purchaseDate) ??
                                            DateTime.now())
                                        .toLocal()),
                                style: GoogleFonts.poppins(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rs ${NumberFormat('#,###').format(purchase.totalAmount)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 4),
                            _buildStatusBadge(purchase.status),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecordPurchaseScreen(
                                  purchase: purchase),
                            ),
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: Text(
                            'View Items',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            if (purchase.status == 'paid')
                              TextButton.icon(
                                onPressed: () {
                                  final owner = context.read<AuthProvider>().currentOwner;
                                  SupplierExportUtils.exportPaymentReceiptPdf(purchase, owner: owner);
                                },
                                icon: const Icon(Icons.receipt_long_rounded, size: 16),
                                label: Text(
                                  'Receipt',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.blue.shade700,
                                  backgroundColor: Colors.blue.shade50,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => _handleSettlePayment(purchase),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                label: Text(
                                  'Settle',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.green.shade700,
                                  backgroundColor: Colors.green.shade50,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _confirmDeletePurchase(purchase),
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              label: Text(
                                'Delete',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                backgroundColor: Colors.red.shade50,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textLight.withValues(alpha: 0.3)),
          SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textMedium,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        label = 'PAID';
        break;
      case 'partial':
        color = Colors.orange;
        label = 'PARTIAL';
        break;
      default:
        color = Colors.red;
        label = 'UNPAID';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _handleSettlePayment(dynamic purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settle Payment'),
        content: Text('Mark this purchase as fully PAID? This will generate a payment receipt.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              // Multi-step settlement: Remote status update followed by local export.
              final updated = await context.read<PurchaseProvider>().settlePurchase(purchase.id);
              if (updated != null && context.mounted) {
                SnackBarUtils.showSnackBar(context, 'Payment settled successfully');
                final owner = context.read<AuthProvider>().currentOwner;
                SupplierExportUtils.exportPaymentReceiptPdf(updated, owner: owner);
                context.read<SupplierProvider>().fetchSuppliers(); // Balance reconciliation
              }
            },
            child: Text('Settle Now'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSupplier(dynamic supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Supplier'),
        content: Text('Are you sure you want to delete ${supplier.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<SupplierProvider>()
                  .removeSupplier(supplier.id);
              if (context.mounted) {
                if (success) {
                  SnackBarUtils.showSnackBar(context, 'Supplier removed');
                } else {
                  final supplierProvider = context.read<SupplierProvider>();
                  SnackBarUtils.showSnackBar(
                    context,
                    supplierProvider.error ?? 'Failed to remove supplier',
                    isError: true,
                    technicalDetails: supplierProvider.technicalDetails,
                  );
                }
              }
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePurchase(dynamic purchase) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Record'),
        content: Text('Are you sure you want to delete this purchase record?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context
                  .read<PurchaseProvider>()
                  .deletePurchase(purchase.id);
              if (context.mounted) {
                if (success) {
                  // Strategy: Synchronization Delay.
                  // Rationale: Wait for backend stock reversal to commit before refreshing local catalogue.
                  await Future.delayed(const Duration(milliseconds: 1000));
                  
                  if (context.mounted) {
                    SnackBarUtils.showSnackBar(context, 'Record deleted and stock reverted');
                    context.read<SupplierProvider>().fetchSuppliers(); // Balance reconciliation
                    context.read<ProductProvider>().fetchProducts(refresh: true); // Sync inventory
                  }
                } else {
                  final purchaseProvider = context.read<PurchaseProvider>();
                  SnackBarUtils.showSnackBar(
                    context,
                    purchaseProvider.error ?? 'Failed to delete record',
                    isError: true,
                    // Note: PurchaseProvider doesn't have technicalDetails yet, but we'll add it if needed
                    // For now, using the message context
                  );
                }
              }
            },
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}


