// ------------------------------------------------------------------------------
// File: backend_discovery.dart
// Purpose: Zero-Config Infrastructure Handshake and Network Discovery.
// Rationale: Uses conditional implementation files to ensure the project
//   remains 100% buildable on all platforms (Web/Mobile/Desktop) while
//   providing UDP discovery functionality on supported native devices.
// ------------------------------------------------------------------------------
import 'dart:async';

// Conditional Import Strategy:
// Resolves to _mobile.dart for Android/iOS/Desktop.
// Resolves to _web.dart for Chrome/Surface Web.
import 'package:frontend/core/network/backend_discovery_mobile.dart' 
  if (dart.library.html) 'package:frontend/core/network/backend_discovery_web.dart' as impl;

class BackendDiscovery {
  // --- Interface Delegation ---
  // These methods map to the platform-specific implementation.

  static bool get hasDiscoveredBackend => impl.BackendDiscoveryImpl.hasDiscoveredBackend;

  static Future<void> startDiscovery() => impl.BackendDiscoveryImpl.startDiscovery();

  static void stopDiscovery() => impl.BackendDiscoveryImpl.stopDiscovery();

  static Future<bool> waitForDiscovery({
    Duration timeout = const Duration(seconds: 8),
  }) => impl.BackendDiscoveryImpl.waitForDiscovery(timeout: timeout);

  static Future<bool> testConnection(String ip) => impl.BackendDiscoveryImpl.testConnection(ip);
}
