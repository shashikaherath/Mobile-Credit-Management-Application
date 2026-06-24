// ------------------------------------------------------------------------------
// File: app_back_button.dart
// Purpose: Standardized Back Navigation Anchor.
// Rationale: Unifies the back button design across all modules using a 
//   premium "Tactile" container style. Matches the design established in 
//   the Supplier Management module for visual consistency and premium feel.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/shared/widgets/tactile_scale.dart';

class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  const AppBackButton({
    super.key,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return TactileScale(
      onTap: onTap ?? () => Navigator.maybePop(context),
      child: Container(
        margin: margin,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
