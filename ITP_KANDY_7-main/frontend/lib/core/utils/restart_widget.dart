// ------------------------------------------------------------------------------
// File: restart_widget.dart
// Purpose: Global Application State Reset and Recovery Handler.
// Rationale: Provides a "Hard Reset" mechanism for the entire application 
//   by forcing a full widget tree reconstruction. Allows the system to 
//   recover from fatal state inconsistencies or unhandled exceptions 
//   by wiping the internal registry and returning to a clean bootstrap state.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // Core: Interaction with the Flutter framework

class RestartWidget extends StatefulWidget {
  // child: The root application widget (e.g., ShopBookApp).
  final Widget child;

  const RestartWidget({super.key, required this.child});

  /*
   * Logic: Remote Lifecycle Trigger.
   * Rationale: Traverses the context upwards to locate the primary state 
   *   controller and initiates a full system rotation. Can be triggered 
   *   from any high-level bridge (e.g., GlobalErrorWidget).
   */
  static void restartApp(BuildContext context) {
    // Strategy: Traverse the context upwards to locate the stateful controller.
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  // key: The unique identifier that determines the identity of the widget tree.
  Key key = UniqueKey();

  /**
   * Logic: State Clearing.
   * Rotates the UniqueKey which forces Flutter to discard the old subtree and build a new one.
   */
  void restartApp() {
    setState(() {
      // Implementation: By creating a new Key, the framework treats the next build as a brand-new instance.
      key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Container: Wraps the app in a KeyedSubtree to isolate the restart scope.
    return KeyedSubtree(
      key: key, 
      child: widget.child,
    );
  }
}

