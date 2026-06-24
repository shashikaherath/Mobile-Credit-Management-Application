/**
 * Domain Entity: UserFeedback.
 * Represents a structured support request or bug report submitted by a user.
 * Rationale: Provides a unified data structure for both authenticated owner feedback
 * and unauthenticated public support tickets, ensuring identity traceability for admin triage.
 */
class UserFeedback {
  // --- Identity & Ownership ---
  final String id; // Protocol: Unique identifier (MongoDB _id)
  final String ownerId; // Traceability: Links to the registered Owner (empty for public tickets)
  final String ownerName; // Display: Cached name for high-speed admin listing
  
  // --- Content & Classification ---
  final String category; // Taxonomy: Classification (e.g., 'Error', 'Feature')
  final String message; // Payload: The descriptive body of the support request
  final DateTime createdAt; // Metadata: Timestamp for prioritization
  
  // --- Public Account Recovery Details ---
  final String? contactInfo; // Recovery: Phone/Email for unauthenticated users
  final String? claimedShopName; // Recovery: Used by public users to identify their locked store
  final bool isVerified; // Security: OTP status for identity-sensitive recovery requests

  UserFeedback({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.category,
    required this.message,
    required this.createdAt,
    this.contactInfo,
    this.claimedShopName,
    this.isVerified = false,
  });

  /**
   * Logic: Secure Deserialization.
   * Rationale: Handles multi-tenant identity mapping and ensures MongoDB compatibility.
   */
  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      // Strategy: Handle both standard 'id' and MongoDB '_id' variants.
      id: json['id'] ?? (json['_id'] ?? ''),
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      category: json['category'] ?? '',
      message: json['message'] ?? '',
      contactInfo: json['contactInfo'],
      claimedShopName: json['claimedShopName'],
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).toLocal()
          : DateTime.now(),
    );
  }

  /**
   * Logic: Administrative Serialization.
   * Rationale: Encapsulates feedback payload for transmission to the triage backend.
   */
  Map<String, dynamic> toJson() {
    return {
      'ownerName': ownerName, // Cached: Speeds up admin dashboard rendering
      'category': category,
      'message': message,
      'contactInfo': contactInfo,
      'claimedShopName': claimedShopName,
      'isVerified': isVerified, // Trace: Proves the claimant verified their phone via OTP
    };
  }
}

