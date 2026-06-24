// ------------------------------------------------------------------------------
// File: global_error_widget.dart
// Purpose: System-Wide Crash Recovery and Incident Reporting Bridge.
// Rationale: Intercepts unhandled framework exceptions (Flutter "Red Screen") 
//   to provide a premium, brand-consistent recovery UI. Bridges technical 
//   diagnostics with the automated triage system via FeedbackProvider, 
//   ensuring high-fidelity observability and fault tolerance.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand fonts (Poppins, JetBrains Mono)
import 'package:provider/provider.dart'; // State: Dependency injection for providers
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Semantic colors for error/warning
import 'package:frontend/core/utils/restart_widget.dart'; // Utility: Low-level widget tree reset
import 'package:frontend/features/auth/presentation/widgets/auth_background.dart'; // UI: Shared decorative background
import 'package:frontend/features/account/presentation/providers/feedback_provider.dart'; // Service: Backend reporting hook
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart'; // State: Current user identification

class GlobalErrorWidget extends StatefulWidget {
  // Details: Contains the exception type and stack trace provided by the Flutter framework.
  final FlutterErrorDetails errorDetails;

  const GlobalErrorWidget({super.key, required this.errorDetails});

  @override
  State<GlobalErrorWidget> createState() => _GlobalErrorWidgetState();
}

class _GlobalErrorWidgetState extends State<GlobalErrorWidget> {
  // --- UI State Configuration ---
  bool _showDetails = false; // Toggle: Expanded view for technical stack traces
  bool _isReporting = false; // Guard: Prevents duplicate error submissions

  /*
   * Logic: Integrated Bug Reporting.
   * Silently compiles the crash details and sends them to the backend for developer analysis.
   */
  Future<void> _reportError() async {
    setState(() => _isReporting = true); // UI: Show loading state on report button
    
    try {
      final provider = context.read<FeedbackProvider>(); // Retrieval: Error reporting service
      final ownerName = context.read<AuthProvider>().currentOwner?.name ?? 'Anonymous'; // Context: Identify who logged the crash
      
      // Strategy: Bundle current state and technical logs into a feedback object.
      final success = await provider.submitFeedback(
        'System Crash', // Category: Auto-categorize as a fatal error
        'Exception: ${widget.errorDetails.exception}\n\nStack Trace:\n${widget.errorDetails.stack}', // Content: Full diagnostic dump
        ownerName: ownerName,
      );
      
      // Polish: Provide immediate feedback to the user about their contribution.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Error reported successfully' : 'Failed to report error'),
            backgroundColor: success ? AppColors.primary : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Fallback: Handle network issues during reporting attempt
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not connect to reporting service'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isReporting = false); // Cleanup: Restore button state
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      showLogo: true, // Branding: Reinforce trust even during a crash
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Visual Status Indicator ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1), // Rationale: Soft warning background
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.report_problem_rounded,
                color: AppColors.error,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            
            // --- Human Language Messaging ---
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "The application encountered an unexpected error and couldn't continue.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // --- Primary Action: System Reset ---
            // Rationale: Most crashes are state-dependent; a full restart is the safest recovery path.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => RestartWidget.restartApp(context), // Logic: Wipe and rebuild the app tree
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  elevation: 0,
                ),
                child: const Text('Restart App'),
              ),
            ),
            const SizedBox(height: 12),
            
            // --- Secondary Action: Transparency & Reporting ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isReporting ? null : _reportError, // Guard: Prevents spamming the backend
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: _isReporting 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2, 
                        color: AppColors.primary
                      )
                    )
                  : const Text('Report Problem'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // --- Debugging Infrastructure: Technical Details ---
            // Rationale: Hidden by default for UX, but accessible for developer troubleshooting.
            TextButton(
              key: const Key('error_details_toggle'),
              onPressed: () => setState(() => _showDetails = !_showDetails),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMedium,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_showDetails ? 'Hide Technical Details' : 'Show Technical Details'),
                  Icon(
                    _showDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                ],
              ),
            ),
            
            // Container: Code-style viewport for the raw crash log.
            if (_showDetails) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05), // Rationale: "Terminal" style aesthetic
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                width: double.infinity,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SelectableText(
                    widget.errorDetails.toString(), // Content: The raw Dart/Flutter error dump
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppColors.textDark.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

