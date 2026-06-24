// ------------------------------------------------------------------------------
// File: notification_service.dart
// Purpose: Local Notification Engine and Badge Management.
// Rationale: Orchestrates the lifecycle of system-level alerts and 
//   application icon badges. Implements a unified singleton stream to 
//   ensure consistent notification handling across all app modules.
// ------------------------------------------------------------------------------
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Core: Interaction with OS notification trays
import 'package:app_badge_plus/app_badge_plus.dart'; // Extension: Updates the numeric launcher badge

class NotificationService {
  // --- Singleton Pattern ---
  // Rationale: Prevents multiple listeners and ensures consistent channel state.
  static final NotificationService _instance = NotificationService._internal(); // State: Private static instance
  factory NotificationService() => _instance; // Factory: Returns the shared singleton
  NotificationService._internal(); // Logic: Private internal constructor

  // Plugin: The primary interface for dispatching local notifications.
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /**
   * Logic: System Handshake.
   * Configures platform settings and requests user permissions for alerts.
   */
  Future<void> initialize() async {
    // --- Android: Channel Identity ---
    // Uses the app icon defined in standard Android mipmap resources.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // --- iOS: Permission Request ---
    // Rationale: iOS requires explicit user opt-in for alerts, badges, and sounds.
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true, // Permission: Visible pop-ups
      requestBadgePermission: true, // Permission: Numeric icon dots
      requestSoundPermission: true, // Permission: Audible alert tones
    );

    // Context: Bundle platform-specific configurations together.
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // Initialization: Finalize the link between our code and the target mobile OS.
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Logic: Hook for deep-linking (Action to take when user taps the notification).
      },
    );
  }

  /**
   * Logic: Dispatch Notification.
   * Triggers an immediate system alert with specific importance levels.
   */
  Future<void> showNotification({
    required int id, // Scope: Unique identifier (prevents duplicate alerts)
    required String title, // Header: Primary alert headline
    required String body, // Content: Secondary descriptive message
    String? payload, // State: Hidden metadata for navigation logic
  }) async {
    // --- Android Strategy ---
    // In Android 8+, notifications MUST be grouped into channels for user control.
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'credit_limit_channel', // Registry: Identification string in system settings
      'Credit Limit Alerts', // UX: Human-readable name for user settings
      channelDescription: 'Notifications for customer credit limit exceeded', // UX: Detail of what this channel sends
      importance: Importance.max, // Priority: High visual pop-up banner
      priority: Priority.high, // Hierarchy: Urgent delivery
      showWhen: true, // Polish: Display the arrival timestamp
    );

    // --- iOS Strategy ---
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true, // Action: Pop up on screen
      presentBadge: true, // Action: Update icon dot
      presentSound: true, // Action: Play system chime
    );

    // Bundle: Combine configurations for cross-platform execution.
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Execution: Push the notification to the device status bar.
    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /**
   * Logic: Launcher Badge Update.
   * Synchronizes the unread notification count with the app's home screen icon.
   */
  Future<void> updateBadgeCount(int count) async {
    bool isSupported = await AppBadgePlus.isSupported(); // Capability: Check OS hardware/launcher support
    if (isSupported) {
      AppBadgePlus.updateBadge(count); // Commit: Push the numeric value to the launcher
    }
  }
}

