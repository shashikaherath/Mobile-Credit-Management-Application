// ------------------------------------------------------------------------------
// File: main_shell.dart
// Purpose: Multi-Module Orchestration and Navigation Router.
// Rationale: Serves as the primary application scaffold, managing the 
//   lifecycle of top-level feature modules through a unified bottom 
//   navigation architecture. Implements global tab switching logic and 
//   coordinates cross-feature state refreshes via static keys.
// ------------------------------------------------------------------------------
import 'dart:ui'; // UI: Graphics foundations
import 'package:flutter/material.dart'; // UI: Flutter Material widgets
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/home/presentation/screens/home_screen.dart';
import 'package:frontend/features/products/presentation/screens/inventory_screen.dart';
import 'package:frontend/features/sales/presentation/screens/new_sale_screen.dart';
import 'package:frontend/features/credit/presentation/screens/credit_list_screen.dart';
import 'package:frontend/features/account/presentation/screens/account_screen.dart';

class MainShell extends StatefulWidget {
  static final GlobalKey<HomeScreenState> homeKey =
      GlobalKey<HomeScreenState>();
  static final GlobalKey<InventoryScreenState> inventoryKey =
      GlobalKey<InventoryScreenState>();
  const MainShell({super.key});

  /// Allows child widgets to change the current active tab of the MainShell.
  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    if (state != null) {
      state._onTabTapped(index);
    }
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0; // Tracks the currently active tab (0 to 4)

  @override
  void initState() {
    super.initState();
    // Fetch initial notifications once the widget tree is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().fetchNotifications();
    });
  }

  // List of primary feature screens corresponding to the navbar icons
  final List<Widget> _screens = [
    HomeScreen(key: MainShell.homeKey), // Dashboard / Summary
    InventoryScreen(key: MainShell.inventoryKey), // Product management
    const NewSaleScreen(), // POS / Billing
    const CreditListScreen(), // Dept / Customer loans
    const AccountScreen(), // Settings and user profile
  ];

  // Logic to handle tab switching and list refreshing
  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // If user taps the active tab again, trigger a scroll-to-top or refresh
      if (index == 0) MainShell.homeKey.currentState?.refresh();
      if (index == 1) MainShell.inventoryKey.currentState?.refresh();
      return;
    }

    setState(() => _currentIndex = index); // Update the active index
    if (index == 0) MainShell.homeKey.currentState?.refresh(); // Auto-refresh home on entry
    if (index == 1) MainShell.inventoryKey.currentState?.refresh(); // Auto-refresh inventory on entry
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true, // Crucial for glassmorphism to show content behind the bar
      body: IndexedStack(
        index: _currentIndex, // Preserves the state of each screen when switching
        children: _screens,
      ),
      bottomNavigationBar: _buildPremiumNavbar(), // Floating glassmorphic navbar
    );
  }

  // Builder for the custom floating navigation bar with glassmorphism and animations
  Widget _buildPremiumNavbar() {
    const double barHeight = 72; // Standard height for the interactive area
    const double horizontalPadding = 20; // Side margins for the floating look
    const double bottomMargin = 24; // Lift the bar off the bottom edge

    return Container(
      height: barHeight + MediaQuery.of(context).padding.bottom + bottomMargin,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        10,
        horizontalPadding,
        MediaQuery.of(context).padding.bottom + bottomMargin,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32), // Rounded outer corners
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // Premium frosted glass effect
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8), // Translucent white base
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6), // Subtle light border for glass edges
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withValues(alpha: 0.05), // Soft drop shadow
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth = constraints.maxWidth / 5; // Divide bar into 5 equal slots
                return Stack(
                  children: [
                    // Sliding Indicator: The green/blue pill that moves behind the icons
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      left: _currentIndex * itemWidth + 6,
                      top: 6,
                      bottom: 6,
                      child: Container(
                        width: itemWidth - 12,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.accentGreen, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Nav Items Row: The actual icons and text labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Home'),
                        _buildNavItem(1, Icons.shopping_basket_outlined, Icons.shopping_basket_rounded, 'Products'),
                        _buildNavItem(2, Icons.receipt_outlined, Icons.receipt_rounded, 'Sales'),
                        _buildNavItem(3, Icons.people_outline, Icons.people_rounded, 'Credit'),
                        _buildNavItem(4, Icons.person_outline, Icons.person_rounded, 'Account'),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Builder for a single navigation tab with scaling animations
  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final bool isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index), // Navigate to this index
        behavior: HitTestBehavior.opaque, // Ensures the entire area is tappable
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with subtle pop animation when selected
            AnimatedScale(
              scale: isActive ? 1.1 : 1.0, 
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                isActive ? activeIcon : icon, // Switch to filled icon if active
                color: isActive ? Colors.white : AppColors.textMedium, // Toggle color
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            // Dynamic text style transitions (boldness/color)
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textMedium,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}


