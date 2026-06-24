// ------------------------------------------------------------------------------
// File: admin_account_screen.dart
// Purpose: Administrative profile and system-wide settings navigation hub.
// Rationale: Acts as the secondary control interface where administrators 
//   manage their personal security (PII), invoke disaster recovery (Backup), 
//   and review legal/privacy guidelines. Implements a high-contrast theme 
//   distinct from the standard store-owner interface.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Material framework
import 'package:provider/provider.dart'; // State: Reactive dependency consumption
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Identity source of truth
import 'package:frontend/features/auth/presentation/screens/login_screen.dart'; // Navigation: Session exit destination
import 'package:frontend/features/admin/presentation/screens/admin_profile_screen.dart'; // Navigation: Admin identity settings
import 'package:frontend/features/admin/presentation/screens/database_backup_screen.dart'; // Navigation: System recovery
import 'package:frontend/features/account/presentation/screens/privacy_policy_screen.dart'; // Navigation: Data governance
import 'package:frontend/shared/widgets/screen_header.dart'; // UI: Consistent screen branding

class AdminAccountScreen extends StatelessWidget {
  const AdminAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: Admin might use a different auth provider or the same one.
    // Assuming same one for now but distinct UI theme.
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(
                title: 'Admin Settings',
                subtitle: 'System & network control',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildProfileSection(authProvider),
                    const SizedBox(height: 32),
                    _buildSettingsList(context, authProvider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(AuthProvider auth) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings,
            size: 48,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          auth.currentOwner?.name ?? 'System Administrator',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          auth.currentOwner?.email ?? 'admin@gmail.com',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context, AuthProvider auth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'Update your name, email and phone',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
              );
            },
          ),
          /* 
          _buildSettingsItem(
            icon: Icons.security,
            title: 'Security Logs',
            subtitle: 'View system access history',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.notifications_active_outlined,
            title: 'System Notifications',
            subtitle: 'Broadcast to all store owners',
            onTap: () {},
          ),
          */
          _buildSettingsItem(
            icon: Icons.backup_outlined,
            title: 'Database Backup',
            subtitle: 'Secure ZIP archive',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DatabaseBackupScreen()),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Data protection guidelines',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out from ShopBook Admin',
            iconColor: Colors.redAccent,
            onTap: () {
              auth.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.indigo).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? Colors.indigo, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 13),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
    );
  }
}

