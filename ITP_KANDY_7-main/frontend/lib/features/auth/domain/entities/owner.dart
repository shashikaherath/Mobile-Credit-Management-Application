/**
 * Auth Domain Entity: Owner.
 * Represents the primary identity of a shop manager within the ShopBook ecosystem.
 * Rationale: Acts as the root object for data isolation; most backend records (Products, Sales) are linked to an Owner ID.
 */
class Owner {
  // --- Core Identity Attributes ---
  final String id; // Protocol: Unique identifier (MongoDB _id) used for multi-tenant filtering
  final String name; // Profile: Legal or display name of the shop manager
  final String shopName; // Branding: The public name of the business entity
  final String phone; // Authentication: Verified mobile number used for SMS sign-in
  final String email; // Communication: Standardized backup/support contact (@gmail.com)
  
  // --- Authorization & Lifecycle ---
  final String status; // Lifecycle: Account state (e.g., 'pending', 'approved')
  final bool isSuspended; // Guard: Security flag to block access if administrative rules are violated
  final String role; // Permissions: Distinguishes between 'owner' and 'admin' accounts
  final String? profilePic; // Visuals: URL to Cloudinary-stored profile image
  final String createdAt; // Traceability: Timestamp of account creation
  final String? token; // Security: Cryptographically signed JWT session token

  Owner({
    required this.id,
    required this.name,
    this.shopName = '', 
    this.phone = '',
    required this.email,
    this.status = 'approved',
    this.isSuspended = false,
    this.role = 'owner',
    this.profilePic,
    this.createdAt = '',
    this.token,
  });

  /**
   * Logic: Deserialization Engine.
   * Rationale: Securely maps backend response keys (including MongoDB's _id variant) to the typed entity.
   */
  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      // Strategy: Handle both API 'id' and MongoDB '_id' formats to ensure compatibility.
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      shopName: json['shopName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'approved',
      isSuspended: json['isSuspended'] ?? false,
      role: json['role'] ?? 'owner',
      profilePic: json['profilePic'],
      createdAt: json['createdAt'] ?? '',
      token: json['token'],
    );
  }

  /**
   * Logic: Serialization Engine.
   * Rationale: Prepares the entity for backend updates (e.g., profile editing).
   */
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Persistence: Required to restore the identity on app restart
      'name': name,
      'shopName': shopName,
      'phone': phone,
      'email': email,
      'status': status,
      'isSuspended': isSuspended,
      'role': role,
      'profilePic': profilePic,
      'token': token,
    };
  }
}

