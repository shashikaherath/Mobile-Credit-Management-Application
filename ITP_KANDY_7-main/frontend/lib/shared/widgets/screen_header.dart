// ------------------------------------------------------------------------------
// File: screen_header.dart
// Purpose: Global visual anchor for feature screens.
// Rationale: Orchestrates the primary identity block for all modules. 
//   Integrates tactile back-navigation, hierarchical typography, and dynamic 
//   action slots to ensure consistent brand elevation and usability.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI framework
import 'package:google_fonts/google_fonts.dart'; // Typography: Brand fonts (Poppins)
import 'package:frontend/core/theme/app_colors.dart'; // Theme: Semantic colors for text and UI elements
import 'package:frontend/shared/widgets/app_back_button.dart'; // Standardized navigation trigger
import 'package:frontend/shared/widgets/tactile_scale.dart'; // UI: Physics-based touch feedback

class ScreenHeader extends StatelessWidget {
  // --- UI Configuration ---
  final String title; // Header: Primary descriptive title of the screen
  final String? subtitle; // Detail: Optional supporting text for context (e.g., "Add new record")
  final Widget? action; // Slot: Optional widget for screen-specific actions (e.g., Search, Sync)
  final bool showBackButton; // Logic: Controls visibility of the navigation trigger
  final VoidCallback? onBack; // Action: Manual override for back navigation
  final VoidCallback? onActionTap; // Action: Tap callback for the action slot
  final Color? titleColor; // Styling: Manual color override for title
  final Color? subtitleColor; // Styling: Manual color override for subtitle
  final EdgeInsets padding; // Layout: Internal spacing from screen edges

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.showBackButton = false,
    this.onBack,
    this.onActionTap,
    this.titleColor,
    this.subtitleColor,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Navigation Logic ---
                    // Rationale: Nested screens require a prominent, custom-styled back trigger.
                    if (showBackButton) ...[
                      AppBackButton(
                        onTap: onBack,
                        margin: const EdgeInsets.only(bottom: 12),
                      ),
                    ],
                    // --- Primary Typography ---
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: titleColor ?? AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    // --- Secondary Details ---
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor ?? AppColors.textMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // --- Dynamic Action Slot ---
              // Rationale: Allows screens to inject unique UI (like a search bar or a + button).
              if (action != null) ...[
                const SizedBox(width: 16),
                TactileScale(
                  onTap: onActionTap,
                  child: action!, // Implementation: Render the injected widget
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

