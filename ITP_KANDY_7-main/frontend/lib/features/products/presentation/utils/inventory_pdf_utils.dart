// ------------------------------------------------------------------------------
// File: inventory_pdf_utils.dart
// Purpose: Multi-format Procurement Reporting Engine.
// Rationale: Generates industry-standard A4 PDF reports for inventory 
//   procurement, providing offline synchronization of stock levels, pricing, 
//   and critical alert statuses for administrative decision support.
// ------------------------------------------------------------------------------
import 'package:pdf/pdf.dart'; // PDF: Core PDF styling constants
import 'package:pdf/widgets.dart' as pw; // PDF: Widget-based document builder
import 'package:printing/printing.dart'; // PDF: Print/download system integration
import 'package:intl/intl.dart'; // Formatting: Date localization
import 'package:frontend/features/products/domain/entities/product.dart'; // Domain: Product entity
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: Business ID

class InventoryPdfUtils {
  static Future<void> generateAndDownloadInventoryReport({
    required List<Product> products,
    Owner? owner,
  }) async {
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    final pdf = pw.Document();
    final now = DateTime.now();

    // Calculations for Executive Summary
    final totalProducts = products.length;
    final lowStockCount = products.where((p) => p.isLowStock).length;
    // Logic: Financial Aggregation.
    // Business Rule: Use server-computed inventory value which already handles non-negative stock clamping.
    final totalStockValue = products.fold(0.0, (sum, p) => sum + p.inventoryValue);

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
            _buildBusinessHeader(owner, 'INVENTORY AUDIT'),
            pw.SizedBox(height: 24),

            // 2. Executive KPI Snapshot
            pw.Row(
              children: [
                pw.Expanded(child: _buildKpiBox('TOTAL ITEMS', totalProducts.toString(), PdfColor.fromInt(0xFF1E293B))),
                pw.SizedBox(width: 12),
                pw.Expanded(child: _buildKpiBox('LOW STOCK', lowStockCount.toString(), lowStockCount > 0 ? PdfColors.red700 : PdfColors.green700)),
                pw.SizedBox(width: 12),
                pw.Expanded(child: _buildKpiBox('TOTAL VALUE', 'Rs ${totalStockValue.toStringAsFixed(0)}', PdfColor.fromInt(0xFF2563EB))),
              ],
            ),
            pw.SizedBox(height: 32),

            // 3. Products Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.white, width: 0),
              columnWidths: {
                0: const pw.FlexColumnWidth(3.5),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell('PRODUCT', isHeader: true),
                    _buildTableCell('QTY', isHeader: true, align: pw.TextAlign.center),
                    _buildTableCell('BUY PRICE', isHeader: true, align: pw.TextAlign.right),
                    _buildTableCell('SELL PRICE', isHeader: true, align: pw.TextAlign.right),
                    _buildTableCell('VALUATION', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                // Table Body
                ...products.map((p) {
                  // Logic: Valuation Consistency.
                  // Business Rule: Use server-computed valuation for individual row accuracy.
                  final valuation = p.inventoryValue;
                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5))),
                    children: [
                      _buildTableCell(p.name, isBold: p.isLowStock),
                      _buildTableCell(
                        '${p.stockQuantity} ${p.unit}',
                        align: pw.TextAlign.center,
                        textColor: p.isLowStock ? PdfColors.red700 : PdfColors.black,
                        isBold: p.isLowStock,
                      ),
                      _buildTableCell('Rs ${p.purchasePrice.toStringAsFixed(0)}', align: pw.TextAlign.right),
                      _buildTableCell('Rs ${p.sellingPrice.toStringAsFixed(0)}', align: pw.TextAlign.right),
                      _buildTableCell('Rs ${valuation.toStringAsFixed(0)}', align: pw.TextAlign.right, isBold: true),
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
      name: 'Inventory_Audit_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildBusinessHeader(Owner? owner, String title) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              (owner?.shopName ?? 'STORE REPORT').toUpperCase(),
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF2563EB),
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
            pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400)),
            pw.Text(DateFormat('MMM dd, yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildKpiBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
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
          fontSize: isHeader ? 10 : 9,
          color: isHeader ? PdfColors.grey800 : textColor,
        ),
        textAlign: align,
      ),
    );
  }
}


