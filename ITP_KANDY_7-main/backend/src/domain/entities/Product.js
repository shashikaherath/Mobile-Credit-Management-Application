/**
 * Domain Layer: Product Entity.
 * Represents a single SKU (Stock Keeping Unit) in the shop's inventory.
 * Encapsulates core business rules for inventory valuation and stock health monitoring.
 */
class Product {
  /**
   * Logic: Entity Initialization.
   * Maps raw data from persistence or input into a structured business object.
   */
  constructor({
    id, // Unique identity (UUID)
    name, // Human-readable product title
    category, // Organizational tag (e.g. 'Snacks', 'Beverages')
    sellingPrice, // Revenue generated per unit sold
    purchasePrice, // Cost paid to supplier per unit
    stockQuantity, // Discrete units currently available in the shelf/wharehouse
    minimumStockLevel, // Threshold for low-stock alerting
    description, // Long-form product metadata
    imageUrl, // Visual asset reference
    unit, // Measurement type (e.g., 'kg', 'box', 'ea')
    notifyOutOfStock, // Business preference for automated alerts
    createdAt, // Date the product was first registered
    updatedAt, // Date of last profile modification
  }) {
    this.id = id;
    this.name = name;
    this.category = category;
    this.sellingPrice = sellingPrice;
    this.purchasePrice = purchasePrice || 0; // Stability: Default to 0 for cost-accounting safety
    this.stockQuantity = stockQuantity;
    this.minimumStockLevel = minimumStockLevel;
    
    // --- Logic: Default Value Fallbacks ---
    this.description = description || ''; // Clarity: Prevent 'null' displays in UI
    this.imageUrl = imageUrl || ''; // Performance: fallback to empty string for standard placeholder rendering
    this.unit = unit || 'ea'; // Standardize on 'each' if no unit specified
    this.notifyOutOfStock = notifyOutOfStock !== undefined ? notifyOutOfStock : true; // Policy: Alerts enabled by default
    this.createdAt = createdAt || new Date().toISOString(); // Audit: Genesis timestamp
    this.updatedAt = updatedAt || new Date().toISOString(); // Audit: Initial update time matches creation
  }

  /**
   * Logic: Stock Health Monitoring.
   * Dynamically evaluates if the product is at risk of going out of stock.
   * Business Rule: Low stock is defined as reaching or falling below the 'minimumStockLevel'.
   */
  get isLowStock() {
    return this.stockQuantity <= this.minimumStockLevel;
  }

  /**
   * Logic: Inventory Valuation KPI.
   * Calculates the total physical asset value currently sitting in the warehouse.
   * Business Rule: Inventory Value = Procurement Cost (purchasePrice) * Units on hand.
   */
  get inventoryValue() {
    // Stability: Clamp stock to 0 for valuation to prevent negative asset reporting.
    return this.purchasePrice * Math.max(0, this.stockQuantity);
  }

  /**
   * Logic: Data Serialization.
   * Converts the rich business object into a plain JSON structure for API delivery.
   * Note: Explicitly includes calculated getters to expose business logic to the Flutter frontend.
   */
  toJSON() {
    return {
      id: this.id,
      name: this.name,
      category: this.category,
      sellingPrice: this.sellingPrice,
      purchasePrice: this.purchasePrice,
      stockQuantity: this.stockQuantity,
      minimumStockLevel: this.minimumStockLevel,
      description: this.description,
      imageUrl: this.imageUrl,
      unit: this.unit,
      notifyOutOfStock: this.notifyOutOfStock,
      isLowStock: this.isLowStock, // Calculated: Critical for UI badges
      inventoryValue: this.inventoryValue, // Calculated: Critical for dashboard analytics
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }
}

// Module Export: Core entity for inventory-related business logic.
module.exports = Product;
