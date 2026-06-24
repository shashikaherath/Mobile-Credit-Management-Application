// ------------------------------------------------------------------------------
// File: tactile_scale.dart
// Purpose: Haptic-like interaction bridge for high-fidelity touch feedback.
// Rationale: Implements a physics-based scaling animation that shrinks widgets 
//   during touch events. Creates a physical "click" sensation and provides 
//   immediate visual confirmation of user intent.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI framework

class TactileScale extends StatefulWidget {
  // --- UI Configuration ---
  final Widget child; // Structure: The component to be wrapped (e.g., Button, Icon)
  final VoidCallback? onTap; // Action: Triggered when the user successfully finishes a tap
  final double scaleDown; // Animation: The target scale factor (0.95 = 5% shrinkage)
  final Duration duration; // Timing: Speed of the transition (must be fast for snappiness)

  const TactileScale({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<TactileScale> createState() => _TactileScaleState();
}

class _TactileScaleState extends State<TactileScale> with SingleTickerProviderStateMixin {
  // --- Animation Controllers ---
  late AnimationController _controller; // Logic: Orchestrates the timeline of the scale
  late Animation<double> _scaleAnimation; // Implementation: Maps 0.0->1.0 to 1.0->scaleDown

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    // Interpolation: Uses a smooth curve to prevent mechanical/stiff movement.
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Cleanup: Destroy controller to free memory
    super.dispose();
  }

  /*
   * Logic: Interaction Start.
   * Rationale: Shrink immediately on touch to give the user immediate visual feedback.
   */
  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      _controller.forward(); // Action: Move to 0.95 scale
    }
  }

  /*
   * Logic: Interaction Success.
   * Rationale: Reset scale and then execute the callback for a "pop" effect.
   */
  void _handleTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      _controller.reverse(); // Action: Back to 1.0 scale
      widget.onTap!(); // Notification: Execute parent logic
    }
  }

  /*
   * Logic: Interaction Cancel (Drag Away).
   * Rationale: If the user pulls their finger away, reset the scale without triggering the action.
   */
  void _handleTapCancel() {
    if (widget.onTap != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Controller: Captures raw touch gestures to drive the animation.
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation, 
        child: widget.child,
      ),
    );
  }
}

