// ------------------------------------------------------------------------------
// File: invoice_pdf_utils.dart
// Purpose: Branded Document Generation and Sharing Engine.
// Rationale: Facilitates the creation of professional PDF invoices from 
//   transaction records, supporting thermal-ready layouts, native sharing 
//   capabilities, and localized fiscal formatting for customer receipts.
// ------------------------------------------------------------------------------
import 'dart:io'; // Platform: File I/O for temp file creation
import 'package:pdf/pdf.dart'; // PDF: Core PDF styling constants
import 'package:pdf/widgets.dart' as pw; // PDF: Widget-based document builder
import 'package:printing/printing.dart'; // PDF: Print/download system integration
import 'package:intl/intl.dart'; // Formatting: Date localization
import 'package:path_provider/path_provider.dart'; // Platform: Temp directory access
import 'package:share_plus/share_plus.dart'; // Platform: Native share sheet
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: Business ID

class InvoicePdfUtils {
  static String getSanitizedInvoiceId(Map<String, dynamic> saleDetails) {
    final rawId = (saleDetails['id'] ?? saleDetails['_id'])?.toString() ?? 'UNKNOWN';
    return rawId.toUpperCase().replaceAll('/', '_').replaceAll('\\', '_');
  }

  static Future<void> generateAndDownloadInvoice({
    required Map<String, dynamic> saleDetails,
    Owner? owner,
  }) async {
    final pdf = await _buildPdfDocument(saleDetails, owner);
    final invoiceId = getSanitizedInvoiceId(saleDetails);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_$invoiceId.pdf',
    );
  }

  static Future<void> shareInvoice({
    required Map<String, dynamic> saleDetails,
    Owner? owner,
  }) async {
    final pdf = await _buildPdfDocument(saleDetails, owner);
    final invoiceId = getSanitizedInvoiceId(saleDetails);
    final bytes = await pdf.save();

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Invoice_$invoiceId.pdf');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Invoice #$invoiceId from ${owner?.shopName ?? 'Small Store'}',
        subject: 'Invoice #$invoiceId',
      ),
    );
  }

  static Future<pw.Document> _buildPdfDocument(Map<String, dynamic> saleDetails, Owner? owner) async {
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    final pdf = pw.Document();

    final items = saleDetails['items'] as List<dynamic>? ?? [];
    final totalAmount = (saleDetails['totalAmount'] ?? 0.0).toDouble();
    final paymentMethod = saleDetails['paymentMethod'] ?? 'cash';
    final customerName = saleDetails['customerName'] ?? 'Walk-in Customer';
    final date =
        (DateTime.tryParse(saleDetails['createdAt'] ?? '') ?? DateTime.now()).toLocal();
    final invoiceId = getSanitizedInvoiceId(saleDetails);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
          italic: italicFont,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Business-First Header: Dynamic Shop Branding
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        (owner?.shopName ?? 'SALE INVOICE').toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 24,
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
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.grey300)),
                      pw.Text('#$invoiceId', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 2, color: PdfColor.fromInt(0xFF2563EB)),
              pw.SizedBox(height: 24),

              // 2. Transaction Meta-data
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BILL TO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.SizedBox(height: 4),
                      pw.Text(customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _buildSummaryLabelValue('DATE', DateFormat('MMM dd, yyyy').format(date)),
                      _buildSummaryLabelValue('METHOD', paymentMethod.toUpperCase()),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 32),

              // 3. Items Table: Shaded Professional Grid
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.white, width: 0), // Use cell shading instead of borders
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableCell('DESCRIPTION', isHeader: true),
                      _buildTableCell('QTY', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('RATE', isHeader: true, align: pw.TextAlign.right),
                      _buildTableCell('TOTAL', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Body
                  if (items.isEmpty)
                    _buildBodyRow('Balance Settlement', '1', totalAmount, totalAmount)
                  else
                    ...items.map((item) {
                      final price = (item['price'] ?? 0.0).toDouble();
                      final qty = item['quantity'] ?? 1;
                      return _buildBodyRow(
                        item['name'] ?? 'Unknown Item',
                        '$qty ${item['unit'] ?? ''}',
                        price,
                        price * qty,
                      );
                    }),
                ],
              ),
              
              pw.SizedBox(height: 32),

              // 4. Financial Summary Card
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 210,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFF8FAFC), // Shaded background
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                      border: pw.Border.all(color: PdfColors.grey200),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                            pw.Text('Rs ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Divider(thickness: 1, color: PdfColors.grey100),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rs ${totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2563EB))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // 5. Branded Footer
              pw.Divider(thickness: 1, color: PdfColors.grey200),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Thank you for your business!', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey500)),
                  pw.Text(
                    'Generated by ShopBook — Premium POS Intelligence',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.TableRow _buildBodyRow(String desc, String qty, double rate, double total) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5))),
      children: [
        _buildTableCell(desc),
        _buildTableCell(qty, align: pw.TextAlign.center),
        _buildTableCell('Rs ${rate.toStringAsFixed(0)}', align: pw.TextAlign.right),
        _buildTableCell('Rs ${total.toStringAsFixed(0)}', align: pw.TextAlign.right, isBold: true),
      ],
    );
  }

  static pw.Widget _buildSummaryLabelValue(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Padding _buildTableCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 10 : 9,
          color: isHeader ? PdfColors.grey800 : PdfColors.black,
        ),
        textAlign: align,
      ),
    );
  }
}


