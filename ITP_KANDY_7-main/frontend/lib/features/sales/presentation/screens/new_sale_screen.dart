// ------------------------------------------------------------------------------
// File: new_sale_screen.dart
// Purpose: Primary Revenue Capture and Transaction Orchestration.
// Rationale: Serves as the high-throughput POS interface, managing the real-time 
//   cart lifecycle, stock enforcement, and payment finalization workflows (Cash 
//   vs Credit) with deep cross-provider synchronization.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // Feedback: Status notification component
import 'package:frontend/features/sales/presentation/providers/sale_provider.dart'; // State: Cart & sales manager
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart'; // State: Alert refresh
import 'package:frontend/features/products/presentation/providers/product_provider.dart'; // State: Inventory sync
import 'package:frontend/features/credit/presentation/screens/credit_list_screen.dart'; // Navigation: Customer selection
import 'package:frontend/features/credit/domain/entities/customer.dart'; // Domain: Credit customer entity
import 'package:frontend/features/sales/presentation/screens/payment_confirmation_dialog.dart'; // UI: Pre-payment audit
import 'package:frontend/features/sales/presentation/screens/payment_success_screen.dart'; // UI: Post-payment celebration
import 'package:frontend/features/credit/presentation/providers/credit_provider.dart'; // State: Debt sync
import 'package:frontend/shared/main_shell.dart'; // Navigation: Dashboard return point
import 'package:frontend/shared/widgets/screen_header.dart'; // UI: Reusable page header
import 'package:frontend/shared/widgets/counter_text.dart'; // UI: Animated number display
import 'package:frontend/shared/widgets/tactile_scale.dart'; // UI: Haptic tap wrapper
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Animation: Staggered list entry
import 'package:animate_do/animate_do.dart'; // Animation: Declarative transitions

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<SaleProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: ScreenHeader(
                    title: 'Checkout',
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    action: provider.cartItems.isEmpty
                        ? null
                        : TextButton.icon(
                            onPressed: () => provider.clearCart(),
                            icon: Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            label: Text(
                              'Clear',
                              style: GoogleFonts.poppins(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              backgroundColor: AppColors.error.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ),
                ),
                Expanded(
                  child: provider.isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        )
                      : provider.cartItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.textDark.withValues(alpha: 0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.shopping_cart_outlined,
                                      size: 60,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Your cart is empty',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add products from the Inventory to begin a sale.',
                                    style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMedium),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : AnimationLimiter(
                              child: Column(
                                children: [
                                  // Cart items list: Displays current selections from inventory
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: provider.cartItems.length,
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final item = provider.cartItems[index];
                                        return AnimationConfiguration.staggeredList(
                                          position: index,
                                          duration: const Duration(milliseconds: 375),
                                          child: SlideAnimation(
                                            horizontalOffset: 50.0,
                                            child: FadeInAnimation(
                                              child: Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(16),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.03),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade50,
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Icon(
                                                        Icons.shopping_bag_outlined,
                                                        color: AppColors.primary,
                                                        size: 24,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            item['name'], // Product identifier
                                                            style: GoogleFonts.poppins(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 16,
                                                              color: AppColors.textDark,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            'Rs. ${(item['price'] as num).toDouble().toStringAsFixed(2)}', // Unit price
                                                            style: GoogleFonts.poppins(
                                                              fontWeight: FontWeight.w700,
                                                              color: AppColors.primary,
                                                              fontSize: 15,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Quantity Management: Tactile controls for cart adjustments
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        TactileScale(
                                                          onTap: () => provider.updateQuantity(
                                                            index,
                                                            (item['quantity'] as int) - 1,
                                                          ),
                                                          child: _buildQuantityButtonWidget(
                                                            icon: Icons.remove,
                                                            color: AppColors.textMedium,
                                                          ),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                                          constraints: const BoxConstraints(minWidth: 40),
                                                          alignment: Alignment.center,
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(
                                                                '${item['quantity']}', // Target checkout amount
                                                                style: GoogleFonts.poppins(
                                                                  fontWeight: FontWeight.w700,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                              Text(
                                                                '${item['unit']}', // Measurement unit (e.g. Kg, Pcs)
                                                                style: GoogleFonts.poppins(
                                                                  fontSize: 10,
                                                                  color: AppColors.textMedium,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        TactileScale(
                                                          onTap: () {
                                                            if ((item['quantity'] as int) <
                                                                (item['stockQuantity'] as int)) {
                                                              // Increment within available inventory bounds
                                                              provider.updateQuantity(
                                                                index,
                                                                (item['quantity'] as int) + 1,
                                                              );
                                                            } else {
                                                              // Guard against over-selling
                                                              SnackBarUtils.showSnackBar(
                                                                context,
                                                                'Stock limit reached for ${item['name']}',
                                                                isError: true,
                                                              );
                                                            }
                                                          },
                                                          child: _buildQuantityButtonWidget(
                                                            icon: Icons.add,
                                                            color: (item['quantity'] as int) < (item['stockQuantity'] as int)
                                                                ? AppColors.primary
                                                                : Colors.grey, // Visual disabled state
                                                            isEnabled: (item['quantity'] as int) < (item['stockQuantity'] as int),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Sticky Checkout Footer: Provides totalization and payment calls-to-action
                                  FadeInUp(
                                    duration: const Duration(milliseconds: 600),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(32),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF0F4C3F).withValues(alpha: 0.08),
                                            blurRadius: 24,
                                            offset: const Offset(0, -8),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(32),
                                        ),
                                        child: Stack(
                                          children: [
                                            // Glassmorphic background accent
                                            Positioned(
                                              top: -50,
                                              right: -50,
                                              child: Container(
                                                width: 150,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withValues(alpha: 0.03),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Glassmorphic Summary Bar
                                                  Container(
                                                    padding: const EdgeInsets.all(20),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF8FAFC),
                                                      borderRadius: BorderRadius.circular(24),
                                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              'TOTAL ITEMS',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w800,
                                                                color: const Color(0xFF94A3B8),
                                                                letterSpacing: 1.2,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 4),
                                                            Text(
                                                              '${provider.totalItems} Units',
                                                              style: GoogleFonts.poppins(
                                                                fontWeight: FontWeight.w700,
                                                                fontSize: 16,
                                                                color: const Color(0xFF1E293B),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          children: [
                                                            Text(
                                                              'TOTAL AMOUNT',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w800,
                                                                color: const Color(0xFF94A3B8),
                                                                letterSpacing: 1.2,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            CounterText(
                                                              value: provider.totalAmount,
                                                              prefix: 'Rs. ',
                                                              style: GoogleFonts.poppins(
                                                                fontWeight: FontWeight.w800,
                                                                fontSize: 24,
                                                                color: AppColors.primary,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TactileScale(
                                                          onTap: () => _showConfirmation(context, provider, 'credit'),
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(vertical: 18),
                                                            alignment: Alignment.center,
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFF1F5F9),
                                                              borderRadius: BorderRadius.circular(20),
                                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                                            ),
                                                            child: Text(
                                                              'Credit Loan',
                                                              style: GoogleFonts.poppins(
                                                                fontWeight: FontWeight.w700,
                                                                fontSize: 15,
                                                                color: const Color(0xFF475569),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        flex: 2,
                                                        child: TactileScale(
                                                          onTap: () => _showConfirmation(context, provider, 'cash'),
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(vertical: 18),
                                                            alignment: Alignment.center,
                                                            decoration: BoxDecoration(
                                                              gradient: const LinearGradient(
                                                                colors: [Color(0xFF0F4C3F), Color(0xFF22C55E)],
                                                                begin: Alignment.topLeft,
                                                                end: Alignment.bottomRight,
                                                              ),
                                                              borderRadius: BorderRadius.circular(20),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                                                                  blurRadius: 15,
                                                                  offset: const Offset(0, 6),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                                                                const SizedBox(width: 8),
                                                                Text(
                                                                  'Pay Cash',
                                                                  style: GoogleFonts.poppins(
                                                                    fontWeight: FontWeight.w700,
                                                                    fontSize: 16,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
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
                                ],
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const SizedBox(height: 110), // Buffer to clear the floating navbar in MainShell
    );
  }

  // Visual builder for the quantity modifier buttons (circular, subtle background)
  Widget _buildQuantityButtonWidget({
    required IconData icon,
    required Color color,
    bool isEnabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), // Subtle tint
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }

  void _showConfirmation(
    BuildContext context,
    SaleProvider provider,
    String method,
  ) async {
    Customer? selectedCustomer;

    if (method == 'credit') {
      // Redirect to selection mode to attach a lender to the invoice
      selectedCustomer = await Navigator.push<Customer>(
        context,
        MaterialPageRoute(
          builder: (context) => const CreditListScreen(isSelectionMode: true),
        ),
      );
      if (selectedCustomer == null) return; // User cancelled customer selection
    }

    // Generate a unique transaction identifier based on timestamp
    final String generatedInvoiceId =
        'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    if (!context.mounted) return;

    // Trigger visual audit before final database write
    showDialog(
      context: context,
      builder: (dialogContext) => PaymentConfirmationDialog(
        items: List<Map<String, dynamic>>.from(provider.cartItems),
        totalAmount: provider.totalAmount,
        paymentMethod: method,
        customerName: selectedCustomer?.name ?? 'Walk-in Customer',
        invoiceId: generatedInvoiceId,
        onConfirm: () => _completeSale(
          context,
          provider,
          method,
          generatedInvoiceId,
          selectedCustomer,
        ),
      ),
    );
  }

  void _completeSale(
    BuildContext context,
    SaleProvider provider,
    String method,
    String invoiceId,
    Customer? selectedCustomer,
  ) async {
    try {
      // Execute the backend transaction (Atomically creates sale and updates stock)
      final saleDetails = await provider.completeSale(
        id: invoiceId,
        paymentMethod: method,
        customerId: selectedCustomer?.id ?? '',
        customerName: selectedCustomer?.name ?? '',
      );

      if (!context.mounted) return;

      if (saleDetails != null) {
        // Post-sale cleanup: ensure all providers reflect the new system state
        
        // Refresh product list to show reduced inventory counts (with sync delay)
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!context.mounted) return;
        context.read<ProductProvider>().fetchProducts();
        
        // Update local sales history cache
        context.read<SaleProvider>().fetchSales();

        // Update customer balances if the sale was credited
        if (selectedCustomer != null) {
          context.read<CreditProvider>().fetchCustomers();
        }

        // Pull new alerts (e.g. "Low stock" triggered by this sale)
        context.read<NotificationProvider>().fetchNotifications();

        // Signal dashboard to recalculate daily earnings/stats
        MainShell.homeKey.currentState?.refresh();

        // Transit to success state UI
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(saleDetails: saleDetails),
          ),
        );
      } else {
        // Handle rejection from business logic (e.g. price mismatch or invalid customer)
        final saleProvider = context.read<SaleProvider>();
        SnackBarUtils.showSnackBar(
          context,
          saleProvider.error ?? 'Failed to complete sale.',
          isError: true,
          technicalDetails: saleProvider.technicalDetails,
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Catch unexpected network or serialization errors
        final saleProvider = context.read<SaleProvider>();
        SnackBarUtils.showSnackBar(
          context,
          saleProvider.error ?? 'Error completing sale: $e',
          isError: true,
          technicalDetails: saleProvider.technicalDetails,
        );
      }
    }
  }
}

