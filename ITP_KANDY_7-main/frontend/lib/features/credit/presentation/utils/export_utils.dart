// ------------------------------------------------------------------------------
// File: export_utils.dart
// Purpose: Multi-Customer Credit Directory Export Engine.
// Rationale: Facilitates batch financial reporting by generating structured 
//   PDF directories of active creditors and settled accounts. Supports 
//   end-of-day reconciliation and high-level system liability audits.
// ------------------------------------------------------------------------------
import 'package:pdf/pdf.dart'; // PDF: Page format and color definitions
import 'package:pdf/widgets.dart' as pw; // PDF: Widget tree for document layout
import 'package:printing/printing.dart'; // PDF: Native print/share dialog
import 'package:intl/intl.dart'; // Format: Date and currency formatting
import 'package:frontend/features/credit/domain/entities/customer.dart'; // Domain: Customer profile data
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: Business ID

class CreditExportUtils {
  static Future<void> exportActiveCreditsPdf(List<Customer> customers, {Owner? owner}) async {
    // Load Unicode-capable fonts
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();

    final totalOutstanding = customers.fold(0.0, (sum, item) => sum + item.totalOutstanding);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Business-First Header
            _buildBusinessHeader(owner, 'ACTIVE CREDITORS REPORT'),
            pw.SizedBox(height: 20),

            // 2. Summary Card
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                _buildSummaryBox('TOTAL OUTSTANDING', 'Rs ${totalOutstanding.toStringAsFixed(0)}', PdfColors.red700),
              ],
            ),
            pw.SizedBox(height: 24),

            // 3. Data Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.white, width: 0),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildCell('CUSTOMER NAME', isHeader: true),
                    _buildCell('PHONE', isHeader: true),
                    _buildCell('LIMIT (Rs)', isHeader: true, align: pw.TextAlign.right),
                    _buildCell('DUE (Rs)', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...customers.map((c) => pw.TableRow(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5))),
                      children: [
                        _buildCell(c.name),
                        _buildCell(c.phone),
                        _buildCell(c.creditLimit.toStringAsFixed(0), align: pw.TextAlign.right),
                        _buildCell(c.totalOutstanding.toStringAsFixed(0),
                            align: pw.TextAlign.right, isBold: true, color: PdfColors.red700),
                      ],
                    )),
              ],
            ),
          ];
        },
        footer: (pw.Context context) => _buildFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'active_creditors_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> exportSettledCreditsPdf(List<Customer> customers, {Owner? owner}) async {
    // Load Unicode-capable fonts
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Business-First Header
            _buildBusinessHeader(owner, 'SETTLED CUSTOMERS REPORT'),
            pw.SizedBox(height: 20),

            // 2. Status Card
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                _buildSummaryBox('STATUS', 'ACCOUNT SETTLED', PdfColors.green700),
              ],
            ),
            pw.SizedBox(height: 24),

            // 3. Data Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.white, width: 0),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildCell('CUSTOMER NAME', isHeader: true),
                    _buildCell('PHONE', isHeader: true),
                    _buildCell('LIMIT (Rs)', isHeader: true, align: pw.TextAlign.right),
                    _buildCell('STATUS', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                ...customers.map((c) => pw.TableRow(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5))),
                      children: [
                        _buildCell(c.name),
                        _buildCell(c.phone),
                        _buildCell(c.creditLimit.toStringAsFixed(0), align: pw.TextAlign.right),
                        _buildCell('Settled', align: pw.TextAlign.center, isBold: true, color: PdfColors.green700),
                      ],
                    )),
              ],
            ),
          ];
        },
        footer: (pw.Context context) => _buildFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'settled_customers_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  // --- Helper Build Methods ---

  static pw.Widget _buildBusinessHeader(Owner? owner, String reportTitle) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  (owner?.shopName ?? 'SMALL STORE').toUpperCase(),
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2563EB)),
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
                pw.Text(reportTitle, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400)),
                pw.Text('Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(thickness: 2, color: PdfColor.fromInt(0xFF2563EB)),
      ],
    );
  }

  static pw.Widget _buildSummaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: color)),
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

  static pw.Padding _buildCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left, PdfColor? color, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 10 : 9,
          color: color,
        ),
        textAlign: align,
      ),
    );
  }
}

