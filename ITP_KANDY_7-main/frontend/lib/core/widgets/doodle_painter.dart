// ------------------------------------------------------------------------------
// File: doodle_painter.dart
// Purpose: Deterministic Procedural Background Generation.
// Rationale: Generates a decorative, grocery-themed pattern using 
//   low-level canvas drawing APIs. Ensures a premium, customized aesthetic 
//   without relying on heavy binary image assets.
// ------------------------------------------------------------------------------
import 'dart:math' as math; // Library: Mathematical utilities for random distribution and rotation
import 'package:flutter/material.dart'; // Core: Flutter drawing and icon system

class DoodlePainter extends CustomPainter {
  // --- Styling ---
  final Color color; // Decoration: The tint applied to the background glyphs
  final double spacing; // Density: The pixel-gap between pattern elements

  DoodlePainter({
    required this.color,
    this.spacing = 80.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Inventory: Set of Material icons that represent the "Grocer/Store" brand identity.
    const iconDataList = [
      Icons.shopping_basket_outlined,
      Icons.apple_outlined,
      Icons.local_grocery_store_outlined,
      Icons.coffee_outlined,
      Icons.store_outlined,
      Icons.inventory_2_outlined,
      Icons.receipt_long_outlined,
      Icons.lunch_dining_outlined,
      Icons.local_drink_outlined,
      Icons.egg_outlined,
      Icons.bakery_dining_outlined,
      Icons.set_meal_outlined,
      Icons.local_cafe_outlined,
      Icons.fastfood_outlined,
      Icons.restaurant_outlined,
      Icons.wine_bar_outlined,
      Icons.water_drop_outlined,
      Icons.cookie_outlined,
      Icons.cake_outlined,
      Icons.outdoor_grill_outlined,
    ];

    /**
     * Logic: Deterministic Randomness.
     * Rationale: Uses a fixed seed (42) so the pattern remains identical every time the frame redraws.
     * Prevents the "Flicker" effect during UI transitions.
     */
    final random = math.Random(42); 

    // Algorithm: Grid-based placement with random jitter.
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Jitter: Shifts the position slightly to create a "hand-drawn" organic distribution.
        final offsetX = x + (random.nextDouble() - 0.5) * spacing * 0.5;
        final offsetY = y + (random.nextDouble() - 0.5) * spacing * 0.5;
        
        // Rotation: Tilts each icon to reinforce the playful/sketched aesthetic.
        final rotation = (random.nextDouble() - 0.5) * 0.6; // Scale: Approx -17 to +17 degrees

        // Selection: Pull a random icon from the store inventory.
        final iconData = iconDataList[random.nextInt(iconDataList.length)];

        // Execution: Delegate to the glyph drawing engine.
        _drawIcon(canvas, iconData, Offset(offsetX, offsetY), rotation);
      }
    }
  }

  /**
   * Logic: Character Rendering.
   * Rationale: Converts IconData into a TextPainter to render specific font-glyphs on the canvas.
   */
  void _drawIcon(Canvas canvas, IconData icon, Offset offset, double rotation) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint), // Translation: Map icon ID to font character
      style: TextStyle(
        fontSize: 24, // Scale: Maintain a subtle size relative to main UI content
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    );
    textPainter.layout(); // Requirement: Compute glyph dimensions before painting

    /**
     * Implementation: Coordinate Isolation.
     * Uses Canvas transformations to handle complex positioning and rotation.
     */
    canvas.save(); // Save: Push current state to stack
    canvas.translate(offset.dx, offset.dy); // Move: Origin to the icon center
    canvas.rotate(rotation); // Rotate: Apply the sketchy tilt

    // Paint: Centers the glyph on the translated origin.
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore(); // Restore: Pop state to avoid affecting next draws
  }

  @override
  bool shouldRepaint(covariant DoodlePainter oldDelegate) {
    // Strategy: Only repaint if visual properties have changed to save GPU cycles.
    return oldDelegate.color != color || oldDelegate.spacing != spacing;
  }
}

/**
 * Shared UI: Decorative Pattern Background.
 * A layout widget that paints the grocery doodles behind its children.
 */
class DoodleBackground extends StatelessWidget {
  final Widget? child; // The UI elements to render on top of the doodles
  final Color? color; // Optional: Override the brand-faint color
  final double spacing; // Optional: Density of the pattern elements

  const DoodleBackground({
    super.key,
    this.child,
    this.color,
    this.spacing = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DoodlePainter(
        // Rationale: Default to a low-opacity white for subtle texture.
        color: color ?? Colors.white.withValues(alpha: 0.1),
        spacing: spacing,
      ),
      child: child, // Content: Wrapped child rendering logic
    );
  }
}

