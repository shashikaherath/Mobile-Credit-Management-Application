// ------------------------------------------------------------------------------
// File: shimmer_loading.dart
// Purpose: Multi-step visual feedback system for async data fetching.
// Rationale: Implements the "skeleton screen" pattern to reduce perceived 
//   load time. Provides a ghost-layout mask that animates over gray placeholder 
//   primitives until real domain data arrives.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Flutter UI framework
import 'package:shimmer/shimmer.dart'; // Plugin: Provides the linear gradient animation engine

class ShimmerLoading extends StatelessWidget {
  // --- UI Configuration ---
  final Widget child; // Structure: The template or "skeleton" to wrap with the animation
  final bool isLoading; // Protocol: Visibility toggle (true = animated ghost, false = real data)

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    // Logic: Guard clause. If data has arrived, bypass the animation and show the real widget.
    if (!isLoading) return child;

    /**
     * Implementation: Shimmer Effect.
     * Uses a moving linear gradient to create a "pulsing" light effect over gray boxes.
     */
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!, // Rationale: Neutral background for unpopulated areas
      highlightColor: Colors.grey[100]!, // Rationale: The "light streak" that moves across the UI
      period: const Duration(milliseconds: 1500), // Speed: Balanced for a smooth, non-distracting pulse
      child: child,
    );
  }
}

/**
 * Shared UI: Shimmer Skeleton Box.
 * A layout-neutral container used to represent text lines, images, or buttons in a loading state.
 */
class ShimmerSkeleton extends StatelessWidget {
  // --- Geometric Settings ---
  final double? width; // Dimension: Horizontal size (null = flexible/expanded)
  final double? height; // Dimension: Vertical size
  final double borderRadius; // Polish: Matches the roundness of the target UI element (e.g., product cards)

  const ShimmerSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Rationale: Color must be absolute for the Shimmer parent to properly mask it.
        color: Colors.black, 
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

