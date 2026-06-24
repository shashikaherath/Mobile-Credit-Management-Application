// ------------------------------------------------------------------------------
// File: owner_pdf_utils.dart
// Purpose: Administrative business intelligence and data export service.
// Rationale: Facilitates the generation of standardized PDF reports for the 
//   platform's store owner database. Supports status-based filtering and 
//   implements layout logic compatible with the 'pdf' and 'printing' packages.
// ------------------------------------------------------------------------------
import 'package:pdf/pdf.dart'; // Domain: PDF color and page format constants
import 'package:pdf/widgets.dart' as pw; // Domain: PDF widget primitives
import 'package:printing/printing.dart'; // Infrastructure: Platform-native print spools
import 'package:intl/intl.dart'; // Utils: Semantic date formatting
import 'package:frontend/features/auth/domain/entities/owner.dart'; // Domain: Owner entity model

class OwnerPdfUtils {
  static Future<void> generateOwnerListPdf({
    required List<Owner> owners,
    String? filterName,
  }) async {
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
            // 1. Executive Admin Header
            pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SHOPBOOK ADMIN CONSOLE',
                          style: pw.TextStyle(
                              fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF2563EB)),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('PLATFORM BUSINESS INTELLIGENCE',
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('STORE OWNER REPORT',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey400)),
                        pw.Text('Generated: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 2, color: PdfColor.fromInt(0xFF2563EB)),
              ],
            ),
            pw.SizedBox(height: 20),

            // 2. Filter Notification (if applicable)
            if (filterName != null && filterName != 'all') ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFF1F5F9),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Text(
                      'FILTER: ${filterName.toUpperCase()}',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
            ],
            pw.SizedBox(height: 24),

            // 3. Data Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.white, width: 0),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2.5),
                3: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildCell('SHOP NAME', isHeader: true),
                    _buildCell('OWNER', isHeader: true),
                    _buildCell('CONTACT DETAILS', isHeader: true),
                    _buildCell('STATUS', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                ...owners.map((owner) {
                  final isSuspended = owner.isSuspended || owner.status == 'suspended';
                  return pw.TableRow(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5))),
                    children: [
                      _buildCell(owner.shopName.isNotEmpty ? owner.shopName : 'N/A', isBold: true),
                      _buildCell(owner.name.isNotEmpty ? owner.name : 'N/A'),
                      _buildCell('${owner.phone}\n${owner.email}'),
                      _buildCell(
                        isSuspended ? 'SUSPENDED' : 'ACTIVE',
                        align: pw.TextAlign.center,
                        isBold: true,
                        color: isSuspended ? PdfColors.red700 : PdfColors.green700,
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total Registered Shops: ${owners.length}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              ],
            ),
          ];
        },
        footer: (pw.Context context) => _buildFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Store_Owner_List_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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

  static pw.Padding _buildCell(String text,
      {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left, PdfColor? color, bool isBold = false}) {
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

