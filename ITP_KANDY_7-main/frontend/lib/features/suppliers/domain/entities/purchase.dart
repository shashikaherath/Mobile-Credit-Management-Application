// ------------------------------------------------------------------------------
// File: purchase.dart
// Purpose: Domain entity representing a single inventory restock transaction.
// Rationale: Models the full lifecycle of a supplier purchase including line
//   items, tax, payment status, and residual debt. Used across Supplier
//   module for purchase recording, settlement, and PDF receipt generation.
// ------------------------------------------------------------------------------
class Purchase {
  final String id;
  final String supplierId;
  final String supplierName;
  final String invoiceNumber;
  final String purchaseDate;
  final List<dynamic> items;
  final double subtotal;
  final double tax;
  final double totalAmount;
  final double amountPaid;
  final double remaining;
  final String status;
  final String paymentMethod;
  final String notes;
  final String createdAt;

  Purchase({
    required this.id,
    this.supplierId = '',
    this.supplierName = '',
    this.invoiceNumber = '',
    this.purchaseDate = '',
    this.items = const [], // The list of products being restocked
    this.subtotal = 0,
    this.tax = 0,
    this.totalAmount = 0, // The final price the shop owner paid to the supplier
    this.amountPaid = 0, // How much of the total has already been paid
    this.remaining = 0, // The leftover debt to the supplier for this purchase
    this.status = 'pending',
    this.paymentMethod = 'cash',
    this.notes = '',
    this.createdAt = '',
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] ?? '',
      supplierId: json['supplierId'] ?? '',
      supplierName: json['supplierName'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      purchaseDate: json['purchaseDate'] ?? '',
      items: json['items'] ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      remaining: (json['remaining'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'] ?? 'cash',
      notes: json['notes'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'supplierId': supplierId,
      'supplierName': supplierName,
      'invoiceNumber': invoiceNumber,
      'purchaseDate': purchaseDate,
      'items': items,
      'subtotal': subtotal,
      'tax': tax,
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      'status': status,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }
}

