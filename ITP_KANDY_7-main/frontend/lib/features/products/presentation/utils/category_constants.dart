/**
 * Configuration: Product Taxonomy Constants.
 * Centralizes the list of product categories used across Add, Edit, and Filter UIs.
 * Rationale: Single source of truth prevents category drift between screens
 * and simplifies future category additions without multi-file changes.
 */
class ProductCategories {
  static const List<String> list = [
    'Grains & Staples',
    'Fruits',
    'Vegetables',
    'Dairy & Eggs',
    'Bakery',
    'Household / Personal Care',
  ];
}

