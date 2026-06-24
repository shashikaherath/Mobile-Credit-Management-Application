import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/notifications/presentation/screens/notification_screen.dart';

class NotificationIcon extends StatelessWidget {
  final Color? color;
  final double size;

  const NotificationIcon({super.key, this.color, this.size = 22});

  @override
  Widget build(BuildContext context) {
    // Listens for changes in the notification state (e.g., new stock alerts)
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        return GestureDetector(
          onTap: () {
            // Open full notifications list
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ).then((_) {
              // Refresh counts when returning from the screen (in case any were read)
              if (context.mounted) notificationProvider.fetchNotifications();
            });
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none, // Allow the badge to sit outside the icon area
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: color ?? AppColors.textMedium,
                  size: size,
                ),
                // Only show the red dot if there are actually unread alerts
                if (notificationProvider.unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error, // High contrast red for urgency
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface, // Matches background to create a "cutout" look
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Center(
                        child: Text(
                          // Format count to fit within the small circle
                          notificationProvider.unreadCount > 9
                              ? '9+' // Cap at 9 to avoid overflow
                              : notificationProvider.unreadCount.toString(),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

