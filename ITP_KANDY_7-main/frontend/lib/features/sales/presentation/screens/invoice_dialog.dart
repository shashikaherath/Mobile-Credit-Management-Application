// ------------------------------------------------------------------------------
// File: invoice_dialog.dart
// Purpose: Interactive Receipt Visualization and Post-sale Orchestration.
// Rationale: Provides a non-modal overlay for comprehensive transaction review, 
//   facilitating line-item audits, branded document generation, and native 
//   document sharing without interrupting the primary navigation stack.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:intl/intl.dart'; // Formatting: Date localization
import 'package:frontend/features/sales/presentation/utils/invoice_pdf_utils.dart'; // Export: PDF generator
import 'package:provider/provider.dart'; // State: Accessing providers
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // Auth: User context

class InvoiceDialog extends StatelessWidget {
  final Map<String, dynamic> saleDetails;

  const InvoiceDialog({super.key, required this.saleDetails});

  @override
  Widget build(BuildContext context) {
    final items = saleDetails['items'] as List<dynamic>? ?? [];
    final totalAmount = saleDetails['totalAmount'] ?? 0.0;
    final paymentMethod = saleDetails['paymentMethod'] ?? 'cash';
    final customerName = saleDetails['customerName'] ?? 'Walk-in Customer';
    final date =
        (DateTime.tryParse(saleDetails['createdAt'] ?? '') ?? DateTime.now()).toLocal();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Visual branding and transaction identification
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INVOICE',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '#${(saleDetails['id'] ?? saleDetails['_id'])?.toString().toUpperCase() ?? 'UNKNOWN'}', // Unique trace ID
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    paymentMethod.toUpperCase(), // Settlement classification
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Details: Metadata for the specific transaction instance
            _buildDetailRow(
              'Date',
              DateFormat('MMM dd, yyyy - hh:mm a').format(date),
            ),
            SizedBox(height: 8),
            _buildDetailRow('Customer', customerName), // Associated account name
            const Divider(height: 32),

            // Items List: Break-down of products or service charges
            Text(
              'ORDER SUMMARY',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Balance Settlement', // Fallback for direct credit payments
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Rs ${totalAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final price = item['price'] ?? 0;
                        final qty = item['quantity'] ?? 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item['name']} x$qty ${item['unit'] ?? ''}', // Product qty/unit pair
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                'Rs. ${(price * qty).toStringAsFixed(0)}', // Itemized subtotal
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 32),

            // Total: Final net value of the entire invoice
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL', // High-level settlement label
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Rs. ${double.parse(totalAmount.toString()).toStringAsFixed(0)}', // Final aggregated amount
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),

            // Actions: Post-view operations for record keeping
            Row(
              children: [
                // Digital document generation
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final owner = context.read<AuthProvider>().currentOwner;
                      InvoicePdfUtils.generateAndDownloadInvoice(
                        saleDetails: saleDetails,
                        owner: owner,
                      );
                    },
                    icon: Icon(Icons.download_outlined, size: 18),
                    label: Text('PDF', style: GoogleFonts.poppins(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // External system sharing
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      final owner = context.read<AuthProvider>().currentOwner;
                      InvoicePdfUtils.shareInvoice(
                        saleDetails: saleDetails,
                        owner: owner,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Icon(Icons.share_rounded, size: 20),
                  ),
                ),
                SizedBox(width: 8),
                // Exit flow
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
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

  // Row builder for key-value styling
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(color: AppColors.textMedium, fontSize: 13),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }
}

