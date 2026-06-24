// ------------------------------------------------------------------------------
// File: home_screen.dart
// Purpose: Executive Business Intelligence Dashboard.
// Rationale: Serves as the primary operational command center, aggregating 
//   real-time KPIs from Sales, Inventory, Credit, and Procurement domains. 
//   Implements high-frequency background polling to ensure data freshneess 
//   and provides a unified entry point for rapid system-wide transactions.
// ------------------------------------------------------------------------------
import 'dart:async'; // Async: Timer for periodic silent polling
import 'package:flutter/material.dart'; // UI: Flutter Material widgets
import 'package:provider/provider.dart'; // State: Provider read/watch
import 'package:google_fonts/google_fonts.dart'; // UI: Poppins typography
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Brand colour tokens
import 'package:frontend/core/network/api_client.dart'; // Network: Direct /dashboard API call
import 'package:frontend/features/products/presentation/screens/add_product_screen.dart'; // Navigation: Quick-add product
import 'package:frontend/features/products/presentation/providers/product_provider.dart'; // State: Product catalogue
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Current owner identity
import 'package:frontend/features/suppliers/presentation/screens/add_supplier_screen.dart'; // Navigation: Quick-add supplier
import 'package:frontend/features/sales/presentation/screens/recent_transactions_screen.dart'; // Navigation: Transaction feed
import 'package:frontend/features/sales/presentation/screens/invoice_history_screen.dart'; // Navigation: Invoice archive
import 'package:frontend/shared/widgets/notification_icon.dart'; // UI: Notification bell with badge
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart'; // State: Notification data
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart'; // State: Credit broadcast sync
import 'package:frontend/features/suppliers/presentation/providers/supplier_provider.dart'; // State: Supplier broadcast sync
import 'package:frontend/features/suppliers/presentation/screens/record_purchase_screen.dart'; // Navigation: Quick-add purchase
import 'package:frontend/shared/main_shell.dart'; // Navigation: Tab switching
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    // Silent polling: Automatically updating the dashboard every 30 seconds to provide real-time shop metrics.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadDashboard(isSilent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard({bool isSilent = false}) async {
    // Logic: Only trigger the full-screen loading state if no dashboard data is cached.
    // Rationale: Prevents the UI from disappearing during pull-to-refresh or silent polling.
    if (!isSilent && _dashboardData == null) {
      setState(() => _loading = true);
    }
    try {
      final result = await ApiClient.get('/dashboard');
      
      if (mounted && !isSilent) {
        // Broadcast synchronization: Fetching related entity data to ensure consistency across feature modules.
        context.read<NotificationProvider>().fetchNotifications();
        context.read<CreditProvider>().fetchCustomers();
        context.read<SupplierProvider>().fetchSuppliers();
        context.read<ProductProvider>().fetchProducts();
      }

      if (mounted) {
        setState(() {
          _dashboardData = result['data'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void refresh() {
    _loadDashboard();
  }



  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final ownerName = authProvider.currentOwner?.name ?? 'ShopBook Partner';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadDashboard,
                child: _dashboardData == null
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.7,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.error,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Failed to load dashboard data.\nPlease check your connection.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(color: AppColors.textMedium),
                              ),
                              SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _loadDashboard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(ownerName),
                            SizedBox(height: 24),
                            _buildStatCards(),
                            SizedBox(height: 28),
                            _buildQuickActions(),
                            SizedBox(height: 28),
                            _buildRecentTransactions(),
                          ],
                        ),
                      ),
              ),
      ),
      bottomNavigationBar: const SizedBox(height: 110), // Buffer to clear the floating navbar in MainShell
    );
  }

  Widget _buildHeader(String ownerName) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final profilePic = auth.currentOwner?.profilePic;
        final hasProfilePic = profilePic != null && profilePic.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Premium Avatar with Gradient Ring
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accentGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                        ),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.cardBlueBg,
                          backgroundImage: hasProfilePic ? NetworkImage(profilePic) : null,
                          child: !hasProfilePic
                              ? const Icon(Icons.storefront_rounded, size: 24, color: AppColors.primary)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Greeting & Partner Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                color: AppColors.textDark,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Hi, ',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                TextSpan(
                                  text: ownerName,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded, size: 12, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'SHOPBOOK PARTNER',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Elevated Notification Action
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textDark.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                ),
                child: const NotificationIcon(size: 24),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCards() {
    final data = _dashboardData;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.payments_rounded,
                bgColor: const Color(0xFFD1FAE5), // Mint
                accentColor: AppColors.primary,
                label: "TODAY'S SALES",
                value: 'Rs. ${(data?["todaysSales"] ?? 0.00).toStringAsFixed(2)}',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.shopping_basket_rounded,
                bgColor: const Color(0xFFFFEBEE), // Rose
                accentColor: AppColors.error,
                label: "LOW STOCK",
                value: '${data?["lowStockCount"] ?? 0} ITEMS',
                badge: "Alert",
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.account_balance_wallet_rounded,
                bgColor: const Color(0xFFFEF3C7), // Cream
                accentColor: const Color(0xFFF59E0B),
                label: "CUSTOMER CREDIT",
                value: 'Rs. ${(data?["customerCredit"] ?? 0.00).toStringAsFixed(2)}',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                icon: Icons.local_shipping_rounded,
                bgColor: const Color(0xFFDBEAFE), // Sky
                accentColor: const Color(0xFF3B82F6),
                label: "TO SUPPLIERS",
                value: 'Rs. ${(data?["toSuppliers"] ?? 0.00).toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionButton(
              icon: Icons.shopping_basket_rounded,
              label: 'Add\nProduct',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                ).then((_) {
                  if (!mounted) return;
                  context.read<ProductProvider>().fetchProducts();
                });
              },
            ),
            _QuickActionButton(
              icon: Icons.person_add_alt_1_rounded,
              label: 'Add\nCustomer',
              onTap: () {
                context.read<CreditProvider>().setShouldOpenAddCustomer(true);
                MainShell.switchToTab(context, 3);
              },
            ),
            _QuickActionButton(
              icon: Icons.local_shipping_rounded,
              label: 'Add\nSupplier',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSupplierScreen()),
                );
              },
            ),
            _QuickActionButton(
              icon: Icons.note_add_rounded,
              label: 'Purchase\nRecord',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecordPurchaseScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    final transactions = (_dashboardData?['recentTransactions'] as List?) ?? [];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecentTransactionsScreen(),
                  ),
                );
              },
              child: Text(
                'See all',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < transactions.length; i++) ...[
                if (i > 0) Divider(height: 1, color: AppColors.divider),
                _buildTransactionItem(transactions[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> txn) {
    final isOrder = txn['type'] == 'order';
    return InkWell(
      onTap: () {
        if (isOrder || txn['type'] == 'credit') {
          // Contextual routing: Navigating directly to the invoice detail view within the history module.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceHistoryScreen(initialInvoiceId: txn['id']),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isOrder
                    ? AppColors.cardGreenBg
                    : AppColors.cardOrangeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isOrder ? Icons.shopping_bag_rounded : Icons.history_rounded,
                size: 20,
                color: isOrder ? AppColors.primary : const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn['title'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    txn['subtitle'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(txn['amount'] ?? 0) >= 0 ? '+' : '-'}Rs. ${(txn['amount']?.abs() ?? 0).toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isOrder ? AppColors.primary : AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  txn['time'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color accentColor;
  final String label;
  final String value;
  final String? badge;

  const _StatCard({
    required this.icon,
    required this.bgColor,
    required this.accentColor,
    required this.label,
    required this.value,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor, // Use the brand category color for the background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3), // Subtle white circle for depth
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white, // White icon container to pop against the colored card
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 24, color: accentColor),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.textMedium,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

