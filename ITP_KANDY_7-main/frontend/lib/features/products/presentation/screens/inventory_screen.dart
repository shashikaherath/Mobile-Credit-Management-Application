// ------------------------------------------------------------------------------
// File: inventory_screen.dart
// Purpose: Primary Inventory Management and Product Intelligence Hub.
// Rationale: Serves as the central command for the product catalog. Features 
//   multi-layered filtering, paginated catalogs, shimmer loading states, and 
//   deep integration with the sales cart and PDF reporting engines.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI reactive system
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand font sets
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/core/theme/app_colors.dart'; // Styling: Design system tokens
import 'package:frontend/core/utils/snackbar_utils.dart'; // Feedback: Status notification component
import 'package:frontend/features/products/domain/entities/product.dart'; // Domain: Product entity
import 'package:frontend/features/products/presentation/providers/product_provider.dart'; // State: Inventory manager
import 'package:frontend/features/sales/presentation/providers/sale_provider.dart'; // State: Cart operations
import 'package:frontend/features/products/presentation/screens/add_product_screen.dart'; // Navigation: Product creation
import 'package:frontend/features/products/presentation/screens/edit_product_screen.dart'; // Navigation: Product editing
import 'package:frontend/features/products/presentation/utils/inventory_pdf_utils.dart'; // Export: PDF report generator
import 'package:frontend/features/products/presentation/utils/category_constants.dart'; // Config: Product taxonomy
import 'package:frontend/shared/widgets/tactile_scale.dart'; // UI: Haptic tap wrapper
import 'package:frontend/shared/widgets/counter_text.dart'; // UI: Animated number display
import 'package:frontend/shared/widgets/modern_pdf_icon.dart'; // UI: PDF action icon
import 'package:frontend/shared/widgets/screen_header.dart'; // UI: Reusable screen header
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Animation: Staggered list entry
import 'package:animate_do/animate_do.dart'; // Animation: Declarative transitions
import 'package:shimmer/shimmer.dart'; // Animation: Skeleton loading placeholders
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // Auth: User context

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => InventoryScreenState();
}

class InventoryScreenState extends State<InventoryScreen> {
  String _selectedFilter = 'All Items';
  final List<String> _selectedCategories = [];
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProductProvider>().fetchProducts();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 && // Trigger threshold (200px from bottom)
        _searchController.text.isEmpty) { // Avoid lazy load during active search filtering
      context.read<ProductProvider>().fetchProducts(refresh: false); // Append next page of data
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void refresh() {
    if (mounted) {
      context.read<ProductProvider>().fetchProducts();
    }
  }

  List<Product> _filterProducts(List<Product> products) {
    List<Product> filtered = products;
    // Layer 1: Stock level filtering
    if (_selectedFilter == 'Low Stock') {
      filtered = products.where((p) => p.isLowStock).toList();
    }

    // Layer 2: Domain-specific category selection
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((p) => _selectedCategories.contains(p.category)).toList();
    }
    
    // Layer 3: Fuzzy text search (Name/Category)
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where(
            (p) =>
                p.name.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query),
          )
          .toList();
    }
    return filtered; // Final derived list for UI rendering
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<ProductProvider>(
          builder: (context, provider, _) {
            final filteredProducts = _filterProducts(provider.products);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SlideInDown(
                    duration: const Duration(milliseconds: 400),
                    child: _buildHeader(context),
                  ),
                ),
                FadeInUp(duration: const Duration(milliseconds: 500), child: _buildSearchBar()),
                FadeInUp(duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200), child: _buildFilterChips()),
                Expanded(
                  child: provider.isLoading
                      ? _buildShimmerLoading()
                      : provider.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.error,
                              ),
                              SizedBox(height: 16),
                              Text(
                                provider.error!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: AppColors.textMedium,
                                ),
                              ),
                              SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: provider.fetchProducts,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: const Text('Retry'),
                                  ),
                                  if (provider.technicalDetails != null) ...[
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      onPressed: () {
                                        // Use the utility to show details
                                        SnackBarUtils.showDetailsDialog(context, provider.technicalDetails!);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.textMedium,
                                        side: BorderSide(color: Colors.grey.shade300),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Text('Details'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () => provider.fetchProducts(),
                            child: AnimationLimiter(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(24, 8, 24, 180),
                                itemCount: 1 + filteredProducts.length + (provider.isFetchingMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  // Add Header Cards (Inventory Value + Products Header) at the top
                                  if (index == 0) {
                                    return AnimationConfiguration.staggeredList(
                                      position: index,
                                      duration: const Duration(milliseconds: 375),
                                      child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                          child: Column(
                                            children: [
                                              _buildInventoryValueCard(provider),
                                              const SizedBox(height: 16),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  // Adjust index for products
                                  final productIndex = index - 1;
                                  
                                  if (productIndex < filteredProducts.length) {
                                    return AnimationConfiguration.staggeredList(
                                      position: index,
                                      duration: const Duration(milliseconds: 375),
                                      child: SlideAnimation(
                                        verticalOffset: 50.0,
                                        child: FadeInAnimation(
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: _ProductTile(product: filteredProducts[productIndex]),
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  // Show loading indicator at the bottom if fetching more
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventory_add_btn',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          ).then((_) {
            if (!context.mounted) return;
            context.read<ProductProvider>().fetchProducts();
          });
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text(
          'Add Product',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBar: const SizedBox(height: 110), // Buffer to clear the floating navbar in MainShell
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return ScreenHeader(
          title: 'Inventory',
          subtitle: 'Manage products and stock levels',
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          action: const ModernPdfIcon(),
          onActionTap: provider.products.isEmpty || provider.isLoading
              ? null
              : () {
                  final owner = context.read<AuthProvider>().currentOwner;
                  InventoryPdfUtils.generateAndDownloadInventoryReport(
                    products: provider.products,
                    owner: owner,
                  );
                },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.textDark.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search products, categories...',
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textLight,
            ),
            prefixIcon: Icon(Icons.search, color: AppColors.textLight),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All Items', 'Low Stock', 'Categories'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 0, 8),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final filterName = filters[index];
            final isSelected = filterName == 'Categories' 
                ? _selectedCategories.isNotEmpty 
                : _selectedFilter == filterName;
            
            return GestureDetector(
              onTap: () {
                if (filterName == 'Categories') {
                  _showAllCategoriesBottomSheet(context);
                } else {
                  setState(() => _selectedFilter = filterName);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey.shade200),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filterName == 'Categories' && _selectedCategories.isNotEmpty
                          ? 'Categories (${_selectedCategories.length})'
                          : filterName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textMedium,
                      ),
                    ),
                    if (filterName == 'Categories') ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: isSelected ? Colors.white : AppColors.textLight,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInventoryValueCard(ProductProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Product Value', // Capital asset valuation
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: 6),
              // Cumulative value of all stock based on purchase cost
              CounterText(
                value: provider.totalInventoryValue,
                prefix: 'Rs. ',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.inventory_outlined,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${provider.totalItemsInStock} Items in stock', // Total unit count
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Critical alert for reordering
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${provider.lowStockProducts.length} Low Stock',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }



  void _showAllCategoriesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categories',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (_selectedCategories.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() => _selectedCategories.clear());
                              setModalState(() {});
                            },
                            child: Text(
                              'Clear Selection',
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: ProductCategories.list.length,
                      itemBuilder: (context, index) {
                        final category = ProductCategories.list[index];
                        final isSelected = _selectedCategories.contains(category);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                              setModalState(() {});
                            },
                            title: Text(
                              category,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                color: isSelected ? AppColors.primary : AppColors.textDark,
                              ),
                            ),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor: isSelected 
                              ? AppColors.primary.withValues(alpha: 0.05)
                              : AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Apply Filter',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: 6,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              const SizedBox(height: 16),
              Shimmer.fromColors(
                baseColor: Colors.grey[200]!,
                highlightColor: Colors.grey[50]!,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[200]!,
            highlightColor: Colors.grey[50]!,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Open detailed modification interface
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditProductScreen(product: product),
          ),
        ).then((_) {
          if (!context.mounted) return;
          context.read<ProductProvider>().fetchProducts(); // Sync state after edit
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.textDark.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Product image
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    color: AppColors.textLight,
                                    size: 28,
                                  ),
                                ),
                          )
                        : Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.textLight,
                              size: 28,
                            ),
                          ),
                  ),
                  if (product.isLowStock)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Low Stock',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: 14),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Category: ${product.category}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          text:
                              'Rs. ${product.sellingPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: product.isLowStock
                                ? AppColors.primary
                                : AppColors.textDark,
                          ),
                          children: [
                            TextSpan(
                              text: '/${product.unit}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${product.stockQuantity} ${product.unit} left',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: product.isLowStock
                                      ? AppColors.error
                                      : AppColors.textLight,
                                ),
                              ),
                              SizedBox(height: 4),
                              SizedBox(
                                width: 60,
                                height: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: product.stockPercentage,
                                    backgroundColor: Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation(
                                      product.isLowStock
                                          ? AppColors.error
                                          : AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 8),
                            TactileScale(
              onTap: () {
                try {
                  context.read<SaleProvider>().addToCart(product); // Temporary cart staging
                  SnackBarUtils.showSnackBar(
                    context,
                    '${product.name} added to cart',
                  );
                } catch (e) {
                  SnackBarUtils.showSnackBar(
                    context,
                    e.toString(), // Validation failure feedback
                    isError: true,
                  );
                }
              },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: product.stockQuantity > 0
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: product.stockQuantity > 0
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 
                                            0.3,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Icon(
                                product.stockQuantity > 0
                                    ? Icons.add_shopping_cart
                                    : Icons.remove_shopping_cart,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProductScreen(product: product),
                            ),
                          ).then((_) {
                            if (!context.mounted) return;
                            context.read<ProductProvider>().fetchProducts();
                          });
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: Text(
                          'Edit',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          backgroundColor: Colors.green.shade50,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _showDeleteConfirmation(context),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          backgroundColor: Colors.red.shade50,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await context.read<ProductProvider>().deleteProduct(product.id);
              if (context.mounted) {
                if (success) {
                  SnackBarUtils.showSnackBar(
                    context,
                    'Product deleted successfully',
                  );
                } else {
                  SnackBarUtils.showSnackBar(
                    context,
                    'Failed to delete product',
                    isError: true,
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}

