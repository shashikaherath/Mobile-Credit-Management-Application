import 'package:flutter/material.dart';

/// A widget that animates numeric changes in text with a rolling effect.
class CounterText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimalPlaces;
  final Duration duration;

  const CounterText({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 2,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    // Animates the transition between an old value and the new value
    return TweenAnimationBuilder<double>(
      duration: duration, // How long the number roll takes
      tween: Tween<double>(begin: 0, end: value), // Transition start and end points
      curve: Curves.easeOutExpo, // Modern, fast-to-slow deceleration curve
      builder: (context, val, child) {
        return Text(
          // Compose the final string with prefix (e.g. $) and formatted digits
          '$prefix${val.toStringAsFixed(decimalPlaces)}$suffix',
          style: style,
        );
      },
    );
  }
}

