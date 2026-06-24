import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/network/api_client.dart';

class BackendDiscoveryImpl {
  static const int _broadcastPort = 5555;
  static RawDatagramSocket? _socket;
  static bool _isSearching = false;
  static bool _hasDiscoveredBackend = false;

  static bool get hasDiscoveredBackend => _hasDiscoveredBackend;

  static Future<void> startDiscovery() async {
    if (_isSearching) return;
    _isSearching = true;

    try {
      debugPrint('📡 [Discovery] Starting UDP discovery on port $_broadcastPort...');
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
      _socket?.broadcastEnabled = true;

      _socket?.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final Datagram? dg = _socket?.receive();
          if (dg != null) {
            _processPacket(dg);
          }
        }
      });
    } catch (e) {
      debugPrint('❌ [Discovery] Failed to start UDP discovery: $e');
      _isSearching = false;
    }
  }

  static void stopDiscovery() {
    _socket?.close();
    _socket = null;
    _isSearching = false;
    debugPrint('📡 [Discovery] Stopped.');
  }

  static Future<bool> waitForDiscovery({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    // Strategy: Parallelize Reachability and Discovery.
    // Instead of waiting for a dead IP to timeout, we trigger UDP scanning
    // at the same time. The first one to find the server wins.
    
    final completer = Completer<bool>();
    final deadline = DateTime.now().add(timeout);

    // 1. Immediate check: Try the last known IP (if it's not the default emulator ID)
    if (ApiClient.serverIp != '10.0.2.2') {
      _isServerReachable(ApiClient.serverIp).then((reachable) {
        if (reachable && !completer.isCompleted) {
          _hasDiscoveredBackend = true;
          completer.complete(true);
        }
      });
    }

    // 2. Immediate scan: Start listening for UDP heartbeats if not already active
    if (!_isSearching) {
      startDiscovery();
    }

    // 3. Polling loop: Wait for either check above to succeed or the total timeout.
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_hasDiscoveredBackend || DateTime.now().isAfter(deadline)) {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete(_hasDiscoveredBackend);
        }
      }
    });

    return completer.future;
  }

  static Future<bool> _isServerReachable(String address) async {
    try {
      // Strategy: Detect if the address is a hostname (e.g. Replit domain) vs a bare IP.
      // Hostnames use HTTPS and don't need a port suffix.
      final bool isHostname = address.contains('.') && !RegExp(r'^[\d.]+$').hasMatch(address);
      final Uri uri;
      if (isHostname) {
        uri = Uri.parse('https://$address/health');
      } else {
        uri = Uri.parse('http://$address:${ApiClient.serverPort}/health');
      }
      // Reduced timeout: 3s for remote servers, 1.5s is too short for Replit cold-starts.
      final response = await http.get(uri).timeout(const Duration(milliseconds: 3000));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> testConnection(String ip) => _isServerReachable(ip);

  static void _processPacket(Datagram dg) {
    try {
      final String message = utf8.decode(dg.data);
      final Map<String, dynamic> data = jsonDecode(message);
      if (data['service'] == 'shopbook' && data['ip'] != null) {
        final String foundIp = data['ip'];
        final int foundPort = data['port'] ?? 3000; // Handshake: Use port from heartbeat
        
        if (foundIp != ApiClient.serverIp) {
          ApiClient.setServerIp(foundIp);
        }
        if (foundPort != ApiClient.serverPort) {
          ApiClient.setServerPort(foundPort);
        }
        _hasDiscoveredBackend = true;
      }
    } catch (e) {
      // Failure: Silently drop malformed packets from unrelated network noise
    }
  }
}
