import 'dart:async';
import 'package:flutter/foundation.dart';

class BackendDiscoveryImpl {
  static bool get hasDiscoveredBackend => true;

  static Future<void> startDiscovery() async {
    debugPrint('📡 [Discovery] UDP discovery skipped on Web.');
  }

  static void stopDiscovery() {
    debugPrint('📡 [Discovery] Stopped.');
  }

  static Future<bool> waitForDiscovery({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    // Web: Always return true as discovery isn't possible and we rely on localhost/replit.
    return true; 
  }

  static Future<bool> testConnection(String ip) async {
    // Basic liveness check could be added here later if needed for Web manual IP entry.
    return true;
  }
}
