// ------------------------------------------------------------------------------
// File: payment_confirmation_dialog.dart
// Purpose: Pre-transaction Audit and Intent Verification.
// Rationale: Implements a high-friction validation gate before database 
//   persistence, allowing for a comprehensive final review of items, pricing, 
//   totals, and payment methods to eliminate accidental revenue capture.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:intl/intl.dart'; // Formatting: Date localization

class PaymentConfirmationDialog extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final String paymentMethod;
  final String customerName;
  final String invoiceId;
  final VoidCallback onConfirm;

  const PaymentConfirmationDialog({
    super.key,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.customerName,
    required this.invoiceId,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Confirm Transaction', // Modal header
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please review the details below', // Instructional subtext
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMedium),
            ),
            SizedBox(height: 24),

            // Transaction Details Box: Grouped logical metadata for the sale
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                   // Unique record tracker
                  _buildInfoRow(
                    'Invoice ID',
                    invoiceId,
                    isBold: true,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 8),
                  _buildInfoRow('Date', DateFormat('MMM dd, yyyy').format(now)), // Auto-generated entry date
                  SizedBox(height: 8),
                  _buildInfoRow('Time', DateFormat('hh:mm a').format(now)), // Auto-generated timestamp
                  SizedBox(height: 8),
                  _buildInfoRow('Method', paymentMethod.toUpperCase()), // Settlement type (Cash/Credit)
                  SizedBox(height: 8),
                  _buildInfoRow('Customer', customerName), // Associated buyer profile
                ],
              ),
            ),
            SizedBox(height: 20),

            Text(
              'ORDER SUMMARY',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 12),

            // Items list: Scrollable container for multi-item checkouts
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item['name']} x${item['quantity']} ${item['unit'] ?? ''}', // Product qty/unit pair
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          'Rs. ${(item['price'] * item['quantity']).toStringAsFixed(0)}', // Itemized subtotal
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const Divider(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PAYABLE TOTAL', // High-level settlement label
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Rs. ${totalAmount.toStringAsFixed(0)}', // Final aggregated amount
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context), // Dismiss without changes
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: AppColors.textMedium,
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close modal
                      onConfirm(); // Execute database write and inventory update callback
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Payment',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for consistent key-value display styling
  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

