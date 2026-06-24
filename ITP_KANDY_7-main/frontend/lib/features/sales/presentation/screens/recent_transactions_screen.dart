// ------------------------------------------------------------------------------
// File: recent_transactions_screen.dart
// Purpose: Unified Financial Activity Feed.
// Rationale: Provides a consolidated, real-time timeline of all fiscal events — 
//   including B2C sales, credit transactions, and B2B procurement — with 
//   categorical color-coding for rapid owner oversight and navigational 
//   drill-through.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:frontend/core/network/api_client.dart'; // Infrastructure: HTTP engine
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/features/sales/presentation/screens/invoice_history_screen.dart'; // Navigation: Invoice detail
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger

class RecentTransactionsScreen extends StatefulWidget {
  const RecentTransactionsScreen({super.key});

  @override
  State<RecentTransactionsScreen> createState() =>
      _RecentTransactionsScreenState();
}

class _RecentTransactionsScreenState extends State<RecentTransactionsScreen> {
  List<dynamic>? _transactions;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      setState(() {
        // Logic: Only trigger the full-screen loading state if no data is currently cached.
        // Rationale: Ensures a professional pull-to-refresh experience by keeping existing data visible.
        if (_transactions == null) {
          _isLoading = true;
        }
        _error = null;
      });
      // Direct API fetch for broad transaction activity
      final result = await ApiClient.get('/transactions');
      if (mounted) {
        setState(() {
          _transactions = result['data']; // Population of the unified history list
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString(); // Error capture for UI feedback
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recent Transactions'), // Page header
        elevation: 0,
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppColors.primary), // Loading spinner
              )
            : _error != null
            ? _buildErrorView() // Failure state handler
            : _transactions == null || _transactions!.isEmpty
            ? _buildEmptyView() // Zero-state handler
            : _buildTransactionList(), // Primary data view
      ),
    );
  }

  // Visual feedback for failed networking or data parsing
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            SizedBox(height: 16),
            Text(
              'Failed to load transactions\n$_error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.textMedium),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchTransactions, // Manual reload trigger
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
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

  // Placeholder for when no transaction records exist in the database
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.textLight),
          SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textMedium,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your sales and purchases will appear here.',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  // High-performance scrollable list of unified activities
  Widget _buildTransactionList() {
    return RefreshIndicator(
      onRefresh: _fetchTransactions, // Standard pull-to-refresh
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: _transactions!.length,
        itemBuilder: (context, index) {
          final txn = _transactions![index];
          final isOrder = txn['type'] == 'order'; // Direct consumer sale
          final isCredit = txn['type'] == 'credit'; // Unsettled consumer debt

          Color iconColor;
          Color bgColor;
          IconData iconData;

          // Categorical Visual Styling: Helps users scan for specific activity types
          if (isOrder) {
            iconColor = AppColors.primary; // Green-tint for revenue
            bgColor = const Color(0xFFD1FAE5);
            iconData = Icons.shopping_cart_outlined;
          } else if (isCredit) {
            iconColor = const Color(0xFFF59E0B); // Amber for pending debt
            bgColor = const Color(0xFFFEF3C7);
            iconData = Icons.history;
          } else {
            // Purchase (Supplier outgoings)
            iconColor = AppColors.error; // Red-tint for expense
            bgColor = const Color(0xFFFEE2E2);
            iconData = Icons.local_shipping_outlined;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              onTap: () {
                // Detail navigation flow: Orders and Credits link to the digital invoice vault
                if (isOrder || isCredit) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InvoiceHistoryScreen(initialInvoiceId: txn['id']),
                    ),
                  );
                }
              },
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              title: Text(
                txn['title'] ?? '', // Transaction source/target
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    txn['subtitle'] ?? '', // Supplementary context
                    style: GoogleFonts.poppins(
                      color: AppColors.textMedium,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      // Temporal metadata (Creation time)
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textLight,
                      ),
                      SizedBox(width: 4),
                      Text(
                        txn['time'] ?? '',
                        style: GoogleFonts.poppins(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(width: 12),
                      // Calendar metadata (Creation date)
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppColors.textLight,
                      ),
                      SizedBox(width: 4),
                      Text(
                        txn['date'] ?? '',
                        style: GoogleFonts.poppins(
                          color: AppColors.textLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Text(
                // Value indicators: Revenue (+) vs Expense (-)
                '${txn['amount'] >= 0 ? '+' : '-'}Rs. ${txn['amount'].abs().toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: txn['amount'] >= 0
                      ? AppColors.primary
                      : AppColors.error,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

