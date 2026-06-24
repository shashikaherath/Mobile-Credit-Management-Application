// ------------------------------------------------------------------------------
// File: supplier.dart
// Purpose: Domain entity representing an external business partner/supplier.
// Rationale: Provides a strongly-typed model for supplier profile data
//   including aggregate payable balance. Used across Supplier module screens,
//   providers, and PDF export utilities.
// ------------------------------------------------------------------------------
class Supplier {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String email;
  final String notes;
  final String status;
  final double totalPayable;
  final String createdAt;

  Supplier({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.email = '',
    this.notes = '',
    this.status = 'active',
    this.totalPayable = 0, // The amount of money the shop owner owes this supplier
    this.createdAt = '',
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'active',
      totalPayable: (json['totalPayable'] ?? 0).toDouble(),
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'notes': notes,
    };
  }
}

