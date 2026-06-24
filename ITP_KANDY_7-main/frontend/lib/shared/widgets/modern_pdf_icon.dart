// ------------------------------------------------------------------------------
// File: modern_pdf_icon.dart
// Purpose: Multi-layer visual representation for PDF document actions.
// Rationale: Implements a custom, scaleable document-with-badge pattern to 
//   ensure high recognition of export operations. Aligned with the application's 
//   professional aesthetic over standard generic icons.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Layout primitives
import 'package:google_fonts/google_fonts.dart'; // Styling: Dynamic typography
class ModernPdfIcon extends StatelessWidget {
  final Color? color;
  final double size;
  final bool useStandardColors;

  const ModernPdfIcon({
    super.key,
    this.color,
    this.size = 24,
    this.useStandardColors = false,
  });

  @override
  Widget build(BuildContext context) {
    // Base colors for a professional look (red = PDF standard)
    final baseColor = color ?? (useStandardColors ? Colors.white : Colors.grey.shade700); // Main icon body color
    final badgeColor = useStandardColors ? Colors.white : const Color(0xFFEF4444); // The signature red for PDF
    final textColor = useStandardColors ? const Color(0xFFEF4444) : Colors.white; // Contrast color for the text label

    return SizedBox(
      width: size + 4, // Leave a tiny buffer for the badge shadow
      height: size + 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The background document silhouette
          Icon(
            Icons.description_rounded,
            color: baseColor,
            size: size,
          ),
          // The "PDF" micro-label overlay
          Positioned(
            bottom: size * 0.1, // Positioned relative to total icon size for scaling
            right: size * 0.05,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * 0.1, // Dynamic padding based on icon scale
                vertical: size * 0.02,
              ),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(size * 0.15), // Scaleable roundness
                boxShadow: [
                  if (!useStandardColors)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2), // Subtle depth
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Text(
                'PDF', // Clear file type identification
                style: GoogleFonts.inter(
                  fontSize: size * 0.32, // Sized to fit precisely within the badge
                  fontWeight: FontWeight.w900, // Ultra-bold for readability at small sizes
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

