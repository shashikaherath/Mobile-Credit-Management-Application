import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: Business ID

class ReportPdfUtils {
  static Future<void> generateAndDownloadReport({
    required Map<String, dynamic> reportData,
    Owner? owner,
  }) async {
    // Load Unicode-capable fonts
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    final pdf = pw.Document();
    final now = DateTime.now();
    final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

    final summary = reportData['summary'] ?? {};
    final inventory = reportData['inventory'] ?? {};
    final topProducts = (reportData['topProducts'] as List?) ?? [];

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
            _buildBusinessHeader(owner, 'BUSINESS INTELLIGENCE'),
            pw.SizedBox(height: 12),
            pw.Divider(thickness: 2, color: PdfColor.fromInt(0xFF2563EB)),
            pw.SizedBox(height: 24),

            // Financial Summary Section
            _buildSectionHeader('FINANCIAL SUMMARY'),
            pw.SizedBox(height: 16),
            pw.GridView(
              crossAxisCount: 3,
              childAspectRatio: 0.4,
              children: [
                _buildSummaryStat(
                    'Today\'s Sales', currencyFormat.format(summary['todaysSales'] ?? 0)),
                _buildSummaryStat(
                    'Total Revenue', currencyFormat.format(summary['totalRevenue'] ?? 0)),
                _buildSummaryStat(
                    'Estimated Profit', currencyFormat.format(summary['totalProfit'] ?? 0)),
                _buildSummaryStat(
                    'Avg Order', currencyFormat.format(summary['averageOrderValue'] ?? 0)),
                _buildSummaryStat('Customer Credit',
                    currencyFormat.format(summary['totalCreditOutstanding'] ?? 0)),
                _buildSummaryStat('To Suppliers', currencyFormat.format(summary['totalPayable'] ?? 0)),
              ],
            ),
            pw.SizedBox(height: 32),

            // Inventory Health Section
            _buildSectionHeader('INVENTORY HEALTH'),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              children: [
                _buildTableRow(
                    'Total Stock Value', currencyFormat.format(inventory['totalValue'] ?? 0)),
                _buildTableRow('Total Items in Stock', '${inventory['itemCount'] ?? 0} items'),
                _buildTableRow('Low Stock Alerts', '${inventory['lowStockCount'] ?? 0} items'),
              ],
            ),
            pw.SizedBox(height: 32),

            // Top Selling Products Section
            if (topProducts.isNotEmpty) ...[
              _buildSectionHeader('TOP SELLING PRODUCTS'),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableCell('#', isHeader: true),
                      _buildTableCell('Product Name', isHeader: true),
                      _buildTableCell('Qty Sold', isHeader: true),
                      _buildTableCell('Revenue', isHeader: true),
                    ],
                  ),
                  ...topProducts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final product = entry.value;
                    return pw.TableRow(
                      children: [
                        _buildTableCell((index + 1).toString()),
                        _buildTableCell(product['name'] ?? 'Unknown'),
                        _buildTableCell('${product['quantity']} ${product['unit'] ?? ''}'),
                        _buildTableCell(currencyFormat.format(product['revenue'] ?? 0)),
                      ],
                    );
                  }),
                ],
              ),
            ],

          ];
        },
        footer: (pw.Context context) => _buildFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Management_Report_${DateFormat('yyyyMMdd').format(now)}.pdf',
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

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: PdfColor.fromInt(0xFF2563EB), width: 4)),
        color: PdfColors.grey50,
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2563EB)),
      ),
    );
  }

  static pw.Widget _buildSummaryStat(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
        ],
      ),
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5))),
      children: [
        _buildTableCell(label),
        _buildTableCell(value, isBold: true, align: pw.TextAlign.right),
      ],
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
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
  }) {
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

