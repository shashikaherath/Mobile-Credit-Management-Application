/**
 * Domain Entity: Product.
 * Represents a single SKU (Stock Keeping Unit) in the shop's inventory.
 * Rationale: Acts as the foundational data model linking sales transactions,
 * stock management, and supplier purchase records across the entire system.
 */
class Product {
  // --- Core Identity ---
  final String id; // Protocol: Unique identifier (MongoDB _id)
  final String name; // Display: Product title visible on shelf and receipts
  final String category; // Taxonomy: Used for filtering and reporting (see ProductCategories)

  // --- Pricing Model ---
  final double sellingPrice; // Revenue: Customer-facing price per unit
  final double purchasePrice; // Cost: Supplier cost for profit margin calculation
  
  // --- Stock Management ---
  final int stockQuantity; // Inventory: Current units available on shelf
  final int minimumStockLevel; // Threshold: Safety limit triggering low-stock alerts
  
  // --- Metadata ---
  final String description; // Display: Optional product description
  final String imageUrl; // Media: Cloudinary-hosted product image URL
  final String unit; // Measurement: Display unit (e.g., 'kg', 'ea', 'L')
  final bool notifyOutOfStock; // Automation: Enable/disable stock alert notifications

  // --- Backend-Computed Fields ---
  final bool isLowStock; // Derived: Server-side calculation (stockQuantity <= minimumStockLevel)
  final double inventoryValue; // Derived: Server-side calculation (purchasePrice * stockQuantity)

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.sellingPrice,
    this.purchasePrice = 0,
    required this.stockQuantity,
    required this.minimumStockLevel,
    this.description = '',
    this.imageUrl = '',
    this.unit = 'ea',
    this.notifyOutOfStock = true,
    this.isLowStock = false,
    this.inventoryValue = 0,
  });

  /**
   * Logic: Secure Deserialization.
   * Rationale: Safely maps backend JSON to typed entity, handling both int and double
   * price values from MongoDB/Node.js for cross-platform numeric compatibility.
   */
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      // Strategy: Force .toDouble() to handle MongoDB returning int for round numbers.
      sellingPrice: (json['sellingPrice'] ?? 0).toDouble(),
      purchasePrice: (json['purchasePrice'] ?? 0).toDouble(),
      stockQuantity: (json['stockQuantity'] ?? 0).toInt(),
      minimumStockLevel: (json['minimumStockLevel'] ?? 0).toInt(),
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      unit: json['unit'] ?? 'ea',
      notifyOutOfStock: json['notifyOutOfStock'] ?? true,
      isLowStock: json['isLowStock'] ?? false,
      inventoryValue: (json['inventoryValue'] ?? 0).toDouble(),
    );
  }

  /**
   * Logic: Outbound Serialization.
   * Rationale: Encapsulates mutable product fields for create/update API calls.
   * Note: 'isLowStock' and 'inventoryValue' are omitted as they are server-computed.
   */
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'sellingPrice': sellingPrice,
      'purchasePrice': purchasePrice,
      'stockQuantity': stockQuantity,
      'minimumStockLevel': minimumStockLevel,
      'description': description,
      'imageUrl': imageUrl,
      'unit': unit,
      'notifyOutOfStock': notifyOutOfStock,
    };
  }

  /**
   * UI Helper: Stock Health Gauge.
   * Rationale: Returns a normalized 0.0–1.0 value representing stock fill level,
   * where 5× the minimum stock level is treated as "full capacity" for visual gauges.
   */
  double get stockPercentage {
    if (minimumStockLevel == 0) return 1.0;
    final maxStock = minimumStockLevel * 5; // Heuristic: 5x safety stock = full
    return (stockQuantity / maxStock).clamp(0.0, 1.0);
  }

  /// Identity Equality: Two products are identical if they share the same database ID.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

