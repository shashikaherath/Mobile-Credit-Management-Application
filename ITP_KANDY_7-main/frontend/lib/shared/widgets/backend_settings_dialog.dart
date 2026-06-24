// ------------------------------------------------------------------------------
// File: backend_settings_dialog.dart
// Purpose: Multi-Vector Connectivity Diagnostics and Manual Configuration.
// Rationale: Empowers the operator to resolve network isolation issues 
//   via UDP auto-discovery, manual IP pinning, and real-time latency testing.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand fonts (Outfit, Inter)
import 'package:frontend/core/network/api_client.dart'; // Service: Global IP management
import 'package:frontend/core/network/backend_discovery.dart'; // Service: UDP discovery & health-check engine

class BackendSettingsDialog extends StatefulWidget {
  const BackendSettingsDialog({super.key});

  @override
  State<BackendSettingsDialog> createState() => _BackendSettingsDialogState();
}

class _BackendSettingsDialogState extends State<BackendSettingsDialog> {
  // --- Controller & State ---
  late TextEditingController _ipController; // Input: Manages the raw IP string
  bool _isTesting = false; // Guard: Prevents concurrent ping requests
  bool _isScanning = false; // Guard: Prevents overlapping UDP broadcast listeners
  String? _testResult; // status: 'success' (green), 'fail' (red), or null (clean)

  @override
  void initState() {
    super.initState();
    // Logic: Initialize with the current active IP to maintain consistency.
    _ipController = TextEditingController(text: ApiClient.serverIp);
  }

  @override
  void dispose() {
    _ipController.dispose(); // Cleanup: Memory safety
    super.dispose();
  }

  /**
   * Logic: Configuration Persistence.
   * Updates the global ApiClient and shuts down the dialog.
   */
  void _save(String ip) {
    if (ip.trim().isEmpty) return; // Guard: Prevent null/empty configuration
    
    ApiClient.setServerIp(ip.trim()); // Action: Commit to memory/storage
    Navigator.pop(context); // Navigation: Return to the previous screen
    
    // Feedback: Direct visual confirmation of change.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Server IP updated to $ip'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /**
   * Logic: Real-time Reachability Test.
   * Rationale: Allows the user to verify an IP before committing the change.
   */
  Future<void> _testConnection() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    setState(() {
      _isTesting = true; // UI: Show progress indicator in suffix
      _testResult = null; // Reset previous state
    });

    // Implementation: Performs a small HTTP/Handshake request to verify the server.
    final reachable = await BackendDiscovery.testConnection(ip);

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _testResult = reachable ? 'success' : 'fail';
    });
  }

  /**
   * Logic: Zero-Config Auto-Discovery.
   * Rationale: Searches for the backend UDP heartbeat (Broadcast 10001) automatically.
   */
  Future<void> _autoScan() async {
    setState(() {
      _isScanning = true; // UI: Change button text and show spinner
      _testResult = null;
    });

    // Strategy: Stop any stale listeners and broadcast a fresh request.
    BackendDiscovery.stopDiscovery();
    BackendDiscovery.startDiscovery();

    // Timeout: Stop searching after 8s to prevent battery drain.
    final found = await BackendDiscovery.waitForDiscovery(
      timeout: const Duration(seconds: 8),
    );

    if (!mounted) return;

    if (found) {
      // Success: Discovered a heartbeat. Update the input field.
      setState(() {
        _ipController.text = ApiClient.serverIp;
        _isScanning = false;
        _testResult = 'success';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found backend at ${ApiClient.serverIp}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Fail: No heartbeat found. Revert to manual fallback.
      setState(() {
        _isScanning = false;
        _testResult = 'fail';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find the backend. Try manual entry.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Context: Render as a floating material dialog.
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section ---
            Row(
              children: [
                Icon(Icons.hub_rounded, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Server Connection',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ensure both devices are on the same Wi-Fi subnet.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            
            // --- Input Field Section ---
            Text(
              'Backend IP Address',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                hintText: 'IP or hostname (e.g. 192.168.1.10)',
                prefixIcon: const Icon(Icons.important_devices_rounded),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                // Indicator Logic: Multi-state suffix based on 'Testing' or 'Result'.
                suffixIcon: _isTesting
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _testResult == 'success'
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _testResult == 'fail'
                            ? const Icon(Icons.error_outline, color: Colors.red)
                            : null,
              ),
              keyboardType: TextInputType.url,
              onChanged: (_) {
                if (_testResult != null) {
                  setState(() => _testResult = null); // Strategy: Reset status while typing
                }
              },
            ),

            // Visual Trace: Textual feedback for the reachability test.
            if (_testResult != null) ...[
              const SizedBox(height: 8),
              Text(
                _testResult == 'success'
                    ? '✅ Server is reachable!'
                    : '❌ Connection timed out.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _testResult == 'success' ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 8),
            // Help Tooltip: Guidance on finding the laptop IP.
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[400]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search "ipconfig" on your laptop CMD and find the IPv4 Address.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Action Controls ---
            // 1. Connection Verifier
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isTesting ? null : _testConnection,
                icon: _isTesting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_find, size: 18),
                label: Text(_isTesting ? 'Verifying...' : 'Quick Test'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                // 2. UDP Radar Scanner
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isScanning ? null : _autoScan,
                    icon: _isScanning
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.radar, size: 18),
                    label: Text(_isScanning ? 'Scanning' : 'Auto Scan'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 3. Persistence Trigger
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _save(_ipController.text),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Save Device'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

