// ------------------------------------------------------------------------------
// File: credit_pdf_utils.dart
// Purpose: Branded Customer Statement Generation Engine.
// Rationale: Automates the creation of comprehensive, print-ready financial 
//   ledgers for individual customers. Merges disparate transaction data 
//   (Direct Credit, Sale Invoices, Payments) into a unified fiscal view with 
//   real-time balance auditing and professional business branding.
// ------------------------------------------------------------------------------

import 'package:pdf/pdf.dart'; // PDF: Page format and color definitions
import 'package:pdf/widgets.dart' as pw; // PDF: Widget tree for document layout
import 'package:printing/printing.dart'; // PDF: Native print/share dialog
import 'package:intl/intl.dart'; // Format: Date and currency formatting
import 'package:frontend/features/credit/domain/entities/customer.dart'; // Domain: Customer profile data
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: Business ID

class CreditPdfUtils {
  static Future<void> generateAndDownloadStatement({
    required Customer customer,
    required List<dynamic> history,
    Owner? owner,
  }) async {
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
          italic: italicFont,
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Business-First Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      (owner?.shopName ?? 'STORE STATEMENT').toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF2563EB), // Official ShopBook Blue
                      ),
                    ),
                    if (owner != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(owner.phone, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text(owner.email, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('CREDIT LEDGER', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400)),
                    pw.Text(DateFormat('MMM dd, yyyy').format(now), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 2, color: PdfColor.fromInt(0xFF2563EB)),
            pw.SizedBox(height: 24),

            // 2. Client & Summary Overview
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILL TO:', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(customer.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text(customer.phone, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFF8FAFC),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColors.grey200),
                    ),
                    child: pw.Column(
                      children: [
                        _buildSummaryRow('Credit Limit', 'Rs ${customer.creditLimit.toStringAsFixed(0)}'),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey200),
                        _buildSummaryRow('Current Balance', 'Rs ${customer.totalOutstanding.toStringAsFixed(2)}', isCritical: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 32),

            // 3. Transaction Table
            pw.Text('TRANSACTION AUDIT LOG', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.white, width: 0),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.2),
                3: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('DATE', isHeader: true),
                    _buildTableCell('DESCRIPTION', isHeader: true),
                    _buildTableCell('TYPE', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell('AMOUNT', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                // Body
                ...history.map((item) {
                  final String dateStr = item is Map ? item['createdAt'] : item.createdAt;
                  final DateTime date = DateTime.parse(dateStr).toLocal();
                  final String title = item is Map ? (item['customerName'] ?? 'Sale') : item.title;
                  final String type = item is Map ? 'SALE' : (item.type as String).toUpperCase();
                  final double amount = (item is Map ? item['totalAmount'] : item.amount).toDouble();
                  final bool isCredit = type == 'SALE' || type == 'CREDIT';

                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5))),
                    children: [
                      _buildTableCell(DateFormat('dd-MM-yy').format(date)),
                      _buildTableCell(type == 'SALE' ? 'Purchase Invoice' : title),
                      _buildTableCell(type, align: pw.TextAlign.center, isBold: true, textColor: isCredit ? PdfColors.red700 : PdfColors.green700),
                      _buildTableCell(
                        'Rs ${amount.toStringAsFixed(0)}',
                        align: pw.TextAlign.right,
                        isBold: true,
                        textColor: isCredit ? PdfColors.red700 : PdfColors.green700,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
        footer: (pw.Context context) => _buildFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Statement_${customer.name}_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {bool isCritical = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: isCritical ? PdfColors.red700 : PdfColors.black)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by ShopBook — Premium POS Intelligence',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Padding _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor textColor = PdfColors.black,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 9 : 9,
          color: isHeader ? PdfColors.grey800 : textColor,
        ),
        textAlign: align,
      ),
    );
  }
}


