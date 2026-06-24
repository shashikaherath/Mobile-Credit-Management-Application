// ------------------------------------------------------------------------------
// File: app_colors.dart
// Purpose: Deterministic Design System Color Tokens.
// Rationale: Defines the centralized visual palette for the ShopBook design 
//   system. Built on an Emerald Green brand identity with a Slate-based 
//   neutral scale to ensure cross-module visual consistency and premium 
//   aesthetic harmony.
// ------------------------------------------------------------------------------
import 'package:flutter/material.dart'; // UI: Framework color system

class AppColors {
  // --- Brand Identity: Emerald Growth Palette ---
  // Rationale: Green conveys growth, freshness, and financial success in retail.
  static const Color primary = Color(0xFF10B981); // Brand: Primary interactable green
  static const Color primaryDark = Color(0xFF059669); // Shade: Used for hover/pressed states

  // --- UI Infrastructure: Surface & Canvas ---
  static const Color background = Color(0xFFF8FAFC); // Canvas: Off-white to reduce glare
  static const Color surface = Color(0xFFFFFFFF); // Surface: Clean white for cards/dialogs
  static const Color divider = Color(0xFFE2E8F0); // Border: Subtle gray for logical separation

  // --- Typography Hierarchy: Slate Neutral Scale ---
  // Rationale: Using slate (blueish-gray) instead of pure black for a premium feel.
  static const Color textDark = Color(0xFF0F172A); // Heading: High-contrast primary text
  static const Color textMedium = Color(0xFF64748B); // Label: Secondary info and descriptions
  static const Color textLight = Color(0xFF94A3B8); // Hint: Placeholder and disabled states

  // --- Semantic Status: Actionable Feedback ---
  static const Color error = Color(0xFFEF4444); // Negative: Deletions and critical alerts
  static const Color warning = Color(0xFFF59E0B); // Caution: Pending status and low stock
  static const Color success = Color(0xFF10B981); // Positive: Confirmation and growth
  static const Color accentGreen = Color(0xFF6EE7B7); // Tertiary: Visual flair and charts

  // --- Themed Backgrounds: Status-Based Chips ---
  // These soft variants are used for the background of status cards to ensure text readability.
  static const Color cardGreenBg = Color(0xFFD1FAE5); // Success backgrounds
  static const Color cardRedBg = Color(0xFFFEE2E2);   // Error/Alert backgrounds
  static const Color cardOrangeBg = Color(0xFFFEF3C7); // Pending/Warning backgrounds
  static const Color cardBlueBg = Color(0xFFDBEAFE);  // Information backgrounds
}

