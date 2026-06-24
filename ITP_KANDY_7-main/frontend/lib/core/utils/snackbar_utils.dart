// ------------------------------------------------------------------------------
// File: snackbar_utils.dart
// Purpose: Deterministic User Feedback and Diagnostic Messaging.
// Rationale: Provides a unified infrastructure for displaying transient 
//   notifications and technical fault diagnostics. Ensures cross-module 
//   visual consistency for semantic alerts (Success, Error, Info) and 
//   facilitates high-fidelity bug reporting via a structured UI.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI framework components
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand fonts (Poppins, JetBrains Mono)
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Central design tokens

class SnackBarUtils {
  /*
   * Logic: Ephemeral Footer Alerts (Standard).
   * Rationale: Displays a floating banner at the viewport base. Utilizes 
   *   haptic-aligned timing and provides a bridge to the technical 
   *   diagnostic system for non-fatal runtime exceptions.
   */
  static void showSnackBar(
    BuildContext context, // Context: Required for accessing the ScaffoldMessenger
    String message, { // Content: User-facing message
    bool isError = false, // Configuration: Toggles semantic color (Green vs Red)
    String? technicalDetails, // Strategy: If present, adds a "DETAILS" action for diagnostics
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context); // Instance: The system manager for snackbars
    scaffoldMessenger.hideCurrentSnackBar(); // Logic: Clear previous alerts to prevent "stacking" lag

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4), // Polish: Internal breathing room
          child: Row(
            children: [
              // Icon: Visual status indicator
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              // Message: Primary notification text
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Rationale: Semi-transparent background allows content to "ghost" through, appearing premium.
        backgroundColor: isError
            ? AppColors.error.withValues(alpha: 0.95)
            : AppColors.primary.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating, // Physicality: Floats above UI instead of fixed bottom
        dismissDirection: DismissDirection.horizontal, // Interaction: Swift swipe-to-dismiss support
        margin: const EdgeInsets.only(
          bottom: 72, // Layout: Offset to avoid overlap with Bottom Navigation Bars
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Polish: Curated corner radius
        duration: Duration(seconds: technicalDetails != null ? 6 : 3), // Strategy: More time for tech-heavy alerts
        elevation: 4, // Depth: Subtle shadow for visual layer separation
        // Action: The bridge to the technical diagnostic system.
        action: technicalDetails != null
            ? SnackBarAction(
                label: 'DETAILS',
                textColor: Colors.white,
                onPressed: () => showDetailsDialog(context, technicalDetails),
              )
            : null,
      ),
    );
  }

  /*
   * Logic: High-Priority Toast (Top Placement).
   * Rationale: Redirects user attention to the upper viewport for critical 
   *   system-level alerts, such as connectivity transitions or background 
   *   infrastructure failures.
   */
  static void showTopSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    String? technicalDetails,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Mapping: Uses intense semantic colors for high-priority visibility.
        backgroundColor: isError ? const Color(0xFFE11D48) : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up, // Interaction: Swipe UP to dismiss (natural for top placement)
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 160, // Logic: Precise top-offset calculation
          left: 20,
          right: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        duration: Duration(seconds: technicalDetails != null ? 6 : 3),
        elevation: 8, // Depth: Stronger shadow for "Interruptive" component
        action: technicalDetails != null
            ? SnackBarAction(
                label: 'DETAILS',
                textColor: Colors.white,
                onPressed: () => showDetailsDialog(context, technicalDetails),
              )
            : null,
      ),
    );
  }

  /*
   * Logic: High-Fidelity Diagnostic Viewer.
   * Rationale: Renders a structured monospaced viewport for serialized 
   *   exception data. Enables users to capture and transmit exact 
   *   troubleshooting context to administrative support channels.
   */
  static void showDetailsDialog(BuildContext context, String details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Consistency: Matches brand buttons
        title: Row(
          children: [
            const Icon(Icons.bug_report_outlined, color: AppColors.error), // Icon: Industry-standard "Bug" status
            const SizedBox(width: 12),
            Text(
              'Technical Details',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // Layout: Wrap-content constraint
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Technical information for support:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textMedium,
              ),
            ),
            const SizedBox(height: 16),
            // Code Block: Monospaced viewport for technical log data.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100, // Aesthetic: "Code Editor" light mode
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              width: double.infinity,
              child: SelectableText(
                details, // Input: The raw trace or network response
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, // Rationale: Monospaced for log readability
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Close button: Direct route back to the app flow
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

