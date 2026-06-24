// ------------------------------------------------------------------------------
// File: export_utils.dart
// Purpose: Cross-Platform Document Generation for Procurement Audits.
// Rationale: Provides a structured reporting engine for supplier directories, 
//   purchase histories, and payment receipts. Utilizes native printing 
//   capabilities for PDF generation, facilitating formal financial 
//   documentation and partner transparency.
// ------------------------------------------------------------------------------
import 'package:pdf/pdf.dart'; // PDF: Page format and colour definitions
import 'package:pdf/widgets.dart' as pw; // PDF: Widget tree for document layout
import 'package:printing/printing.dart'; // PDF: Native print/share dialog
import 'package:intl/intl.dart'; // Format: Date and currency formatting
import 'package:frontend/features/suppliers/domain/entities/supplier.dart'; // Domain: Supplier model
import 'package:frontend/features/suppliers/domain/entities/purchase.dart'; // Domain: Purchase model
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: Business ID

class SupplierExportUtils {
  static Future<void> exportSuppliersPdf(List<Supplier> suppliers, {Owner? owner}) async {
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    final totalPayable = suppliers.fold(0.0, (sum, s) => sum + s.totalPayable);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Business-First Header
            _buildBusinessHeader(owner, 'SUPPLIER DIRECTORY'),
            pw.SizedBox(height: 20),
            
            // 2. Summary Card
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                _buildSummaryBox('TOTAL PAYABLE', 'Rs ${totalPayable.toStringAsFixed(0)}', PdfColors.red700),
              ],
            ),
            pw.SizedBox(height: 24),

            // 3. Data Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.white, width: 0),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildCell('SUPPLIER NAME', isHeader: true),
                    _buildCell('PHONE', isHeader: true),
                    _buildCell('EMAIL', isHeader: true),
                    _buildCell('PAYABLE', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...suppliers.map((s) => pw.TableRow(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5))),
                      children: [
                        _buildCell(s.name),
                        _buildCell(s.phone),
                        _buildCell(s.email),
                        _buildCell('Rs ${s.totalPayable.toStringAsFixed(0)}',
                            align: pw.TextAlign.right,
                            isBold: true,
                            color: s.totalPayable > 0 ? PdfColors.red700 : null),
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
      name: 'suppliers_list_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> exportPurchasesPdf(List<Purchase> purchases, {Owner? owner}) async {
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    final totalPurchases = purchases.fold(0.0, (sum, p) => sum + p.totalAmount);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Business-First Header
            _buildBusinessHeader(owner, 'PURCHASE AUDIT REPORT'),
            pw.SizedBox(height: 20),

            // 2. Summary Card
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                _buildSummaryBox('TOTAL SPEND', 'Rs ${totalPurchases.toStringAsFixed(2)}', PdfColor.fromInt(0xFF065F46)),
              ],
            ),
            pw.SizedBox(height: 24),

            // 3. Itemized Data Blocks
            ...purchases.map((p) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 24),
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF8FAFC),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                    border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Record Metadata
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('INVOICE: ${p.invoiceNumber.isEmpty ? 'N/A' : p.invoiceNumber}',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                              pw.Text('SUPPLIER: ${p.supplierName.toUpperCase()}',
                                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(DateFormat('dd MMM yyyy').format(DateTime.tryParse(p.purchaseDate) ?? DateTime.now()),
                                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                              pw.Text('STATUS: ${p.status.toUpperCase()}',
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: p.status == 'settled' ? PdfColors.green700 : PdfColors.red700)),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 12),
                      pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                      pw.SizedBox(height: 8),

                      // Item List Header
                      pw.Row(
                        children: [
                          pw.Expanded(child: _buildSmallLabel('ITEM DESCRIPTION')),
                          _buildSmallLabel('QTY', width: 40, align: pw.TextAlign.center),
                          _buildSmallLabel('UNIT PRICE', width: 80, align: pw.TextAlign.right),
                          _buildSmallLabel('TOTAL', width: 80, align: pw.TextAlign.right),
                        ],
                      ),
                      pw.SizedBox(height: 4),

                      // Item Rows
                      ...p.items.map((item) => pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 2),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                    child: pw.Text(item['name'] ?? 'Unknown Item', style: const pw.TextStyle(fontSize: 9))),
                                pw.SizedBox(
                                    width: 40,
                                    child: pw.Text('${item['quantity']}',
                                        style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                                pw.SizedBox(
                                    width: 80,
                                    child: pw.Text('Rs ${(item['costPrice'] ?? item['price'] ?? 0).toStringAsFixed(2)}',
                                        style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                                pw.SizedBox(
                                    width: 80,
                                    child: pw.Text('Rs ${(item['total'] ?? 0).toStringAsFixed(2)}',
                                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                                        textAlign: pw.TextAlign.right)),
                              ],
                            ),
                          )),

                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text('GRAND TOTAL: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Rs ${p.totalAmount.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                  fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2563EB))),
                        ],
                      ),
                    ],
                  ),
                )),
          ];
        },
        footer: (pw.Context context) => _buildFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'purchase_records_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> exportPaymentReceiptPdf(Purchase purchase, {Owner? owner}) async {
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // 1. Header
            _buildBusinessHeader(owner, 'ELECTRONIC PAYMENT RECEIPT'),
            pw.SizedBox(height: 24),
            
            // 2. Receipt Identity
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RECEIPT NO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                    pw.Text('#${purchase.id.substring(purchase.id.length > 8 ? purchase.id.length - 8 : 0).toUpperCase()}', 
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('DATE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                    pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            
            pw.SizedBox(height: 24),
            
            // 3. Partner & Transaction Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Column(
                children: [
                  _buildReceiptRow('PAID TO', purchase.supplierName, isLarge: true),
                  pw.Divider(color: PdfColors.grey200, thickness: 0.5),
                  _buildReceiptRow('INVOICE REF', purchase.invoiceNumber.isEmpty ? 'N/A' : purchase.invoiceNumber),
                  _buildReceiptRow('PAYMENT METHOD', purchase.paymentMethod.toUpperCase()),
                  _buildReceiptRow('STATUS', 'CONFIRMED & SETTLED', color: PdfColor.fromInt(0xFF10B981)),
                ],
              ),
            ),

            pw.SizedBox(height: 32),

            // 4. Itemized Breakdown
            pw.Text('ITEMIZED BREAKDOWN', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
            pw.SizedBox(height: 12),
            
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(4),
                1: const pw.FixedColumnWidth(50),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(80),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildCell('ITEM DESCRIPTION', isHeader: true),
                    _buildCell('QTY', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('UNIT PRICE', isHeader: true, align: pw.TextAlign.right),
                    _buildCell('TOTAL', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                // Item Rows
                ...purchase.items.map((item) {
                  final qty = (item['quantity'] ?? 0);
                  final price = (item['costPrice'] ?? item['price'] ?? 0).toDouble();
                  final total = (item['total'] ?? (qty * price)).toDouble();
                  
                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5))
                    ),
                    children: [
                      _buildCell(item['name'] ?? 'Unknown Item'),
                      _buildCell('$qty', align: pw.TextAlign.center),
                      _buildCell('Rs ${price.toStringAsFixed(2)}', align: pw.TextAlign.right),
                      _buildCell('Rs ${total.toStringAsFixed(2)}', align: pw.TextAlign.right, isBold: true),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 24),

            // 5. Final Payment Totals
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 200,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('SUBTOTAL', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                          pw.Text('Rs ${purchase.subtotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      if (purchase.tax > 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TAX', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                            pw.Text('Rs ${purchase.tax.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ],
                      pw.SizedBox(height: 8),
                      pw.Divider(thickness: 1, color: PdfColors.grey300),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL PAID', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                          pw.Text('Rs ${purchase.amountPaid.toStringAsFixed(2)}', 
                              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2563EB))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 40),
            
            // 6. Verification Note
            pw.Center(
              child: pw.Text('This is a system-generated document. No signature required.', 
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic)),
            ),
          ];
        },
        footer: (pw.Context context) => _buildFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'receipt_${purchase.invoiceNumber}.pdf',
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

  static pw.Widget _buildSmallLabel(String text, {double? width, pw.TextAlign align = pw.TextAlign.left}) {
    final widget = pw.Text(text,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600), textAlign: align);
    if (width != null) return pw.SizedBox(width: width, child: widget);
    return widget;
  }

  static pw.Widget _buildReceiptRow(String label, String value, {bool isLarge = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: isLarge ? 12 : 10, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
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


