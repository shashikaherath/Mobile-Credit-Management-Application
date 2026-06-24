// ------------------------------------------------------------------------------
// File: notification_screen.dart
// Purpose: Displays the in-app notification inbox with read/unread management.
// Rationale: Provides a chronological feed of system events (low stock alerts,
//   supplier additions, etc.) with swipe-to-delete, mark-as-read, and
//   bulk clear-all actions. Uses time-ago formatting for recency cues.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Flutter Material widgets
import 'package:google_fonts/google_fonts.dart'; // UI: Poppins typography
import 'package:provider/provider.dart'; // State: Provider read/watch
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Brand colour tokens
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart'; // State: Notification data
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        leading: AppBackButton(
          onTap: () => Navigator.pop(context),
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isEmpty) {
                return const SizedBox.shrink();
              }
              return Row(
                children: [
                  TextButton(
                    onPressed: () => provider.markAllAsRead(),
                    child: Text(
                      'Mark All Read',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.error,
                    ),
                    onPressed: () => _confirmClearAll(context, provider),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.notifications.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (provider.notifications.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: provider.fetchNotifications,
              color: AppColors.primary,
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                itemCount: provider.notifications.length,
                separatorBuilder: (context, index) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notification = provider.notifications[index];
                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text('Delete Notification'),
                          content: Text(
                            'Are you sure you want to delete this notification?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                'Delete',
                                style: GoogleFonts.poppins(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      // Data cleanup: Removing the notification from both local provider state and backend.
                      provider.deleteNotification(notification.id);
                    },
                    child: _NotificationListTile(
                      notification: notification,
                      onTap: () {
                        if (!notification.isRead) {
                          // State update: Mark as read on tap to synchronize visibility across devices.
                          provider.markAsRead(notification.id);
                        }
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No notifications yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'re all caught up! Check back later.',
            style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear All Notifications'),
        content: Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearAllNotifications();
              Navigator.pop(context);
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationListTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationListTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Read/Unread visualization: Using subtle background shifts and borders to denote message priority.
          color: notification.isRead
              ? Colors.white
              : _getIconColor(notification.type).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: notification.isRead
              ? Border.all(color: Colors.grey.shade100)
              : Border.all(
                  color: _getIconColor(notification.type).withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconColor(notification.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(notification.type),
                color: _getIconColor(notification.type),
                size: 22,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: GoogleFonts.poppins(
                      fontWeight: notification.isRead
                          ? FontWeight.w600
                          : FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textMedium,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatTime(notification.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4, left: 8),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getIconColor(notification.type),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'success':
        return Icons.check_circle_outline;
      case 'alert':
        return Icons.error_outline;
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'credit':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'warning':
        return AppColors.warning;
      case 'success':
        return AppColors.primary;
      case 'alert':
        return AppColors.error;
      case 'delivery':
        return Colors.blue;
      case 'credit':
        return Colors.indigo;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime date) {
    // Relative time logic: Converting timestamps to human-readable 'ago' strings for better UX.
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

