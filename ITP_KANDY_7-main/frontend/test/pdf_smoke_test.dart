// ──────────────────────────────────────────────────────────────────────────────
// File: pdf_smoke_test.dart
// Purpose: Simple logic verification for PDF utilities.
// Rationale: Fast, low-complexity check to ensure sanitization logic is intact
//   after the font integration refactoring.
// ──────────────────────────────────────────────────────────────────────────────
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/sales/presentation/utils/invoice_pdf_utils.dart';

void main() {
  group('InvoicePdfUtils Smoke Tests', () {
    test('getSanitizedInvoiceId should sanitize local IDs correctly', () {
      final saleDetails = {
        'id': 'INV/2026/001',
      };
      
      final sanitized = InvoicePdfUtils.getSanitizedInvoiceId(saleDetails);
      
      // Verify sanitization logic
      expect(sanitized, 'INV_2026_001');
    });

    test('getSanitizedInvoiceId should handle missing IDs gracefully', () {
      final sanitized = InvoicePdfUtils.getSanitizedInvoiceId({});
      expect(sanitized, 'UNKNOWN');
    });

    test('getSanitizedInvoiceId should convert to uppercase', () {
      final saleDetails = {'id': 'inv-abc'};
      final sanitized = InvoicePdfUtils.getSanitizedInvoiceId(saleDetails);
      expect(sanitized, 'INV-ABC');
    });
  });
}
