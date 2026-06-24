// ------------------------------------------------------------------------------
// File: admin_shell.dart
// Purpose: Multi-section navigation container for the Administrative interface.
// Rationale: Implements the root persistence hub for Admin-level screens.
//   Orchestrates cross-module synchronization (Owners, Health, Feedback) and 
//   maintains view state continuity via IndexedStack. Acts as the gateway for 
//   platform-wide system governance.
// ------------------------------------------------------------------------------
import 'dart:ui'; // UI: Layout filters and image effects
import 'package:flutter/material.dart'; // UI: Material toolkit
import 'package:provider/provider.dart'; // State: Dependency injection system
import 'package:frontend/features/admin/presentation/providers/admin_provider.dart'; // State: Admin data source
import 'package:frontend/features/admin/presentation/screens/admin_dashboard_screen.dart'; // Navigation: Core stats
import 'package:frontend/features/admin/presentation/screens/manage_feedback_screen.dart'; // Navigation: User sentiment
import 'package:frontend/features/admin/presentation/screens/manage_owners_screen.dart'; // Navigation: Store management
import 'package:frontend/features/admin/presentation/screens/admin_account_screen.dart'; // Navigation: Identity hub

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final adminProvider = context.read<AdminProvider>();
        adminProvider.fetchOwners();
        adminProvider.fetchSystemHealth();
      }
    });
  }

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const ManageFeedbackScreen(),
    const ManageOwnersScreen(),
    const AdminAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 0.5,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      0,
                      Icons.dashboard_outlined,
                      Icons.dashboard,
                      'Stats',
                    ),
                    _buildNavItem(
                      1,
                      Icons.feedback_outlined,
                      Icons.feedback,
                      'Feedback',
                    ),
                    _buildNavItem(
                      2,
                      Icons.people_outline,
                      Icons.people,
                      'Owners',
                    ),
                    _buildNavItem(
                      3,
                      Icons.admin_panel_settings_outlined,
                      Icons.admin_panel_settings,
                      'Admin',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;
    // Admin light mode theme: Deep Indigo/Blue
    final Color activeColor = Colors.indigo;
    final Color inactiveColor = Colors.grey[500]!;
    final Color activeBgColor = Colors.indigo.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

