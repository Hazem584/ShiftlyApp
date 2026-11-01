import 'package:flutter/material.dart';

/// Extracted from Penpot Access & workspaces. Only used within AccessTheme.
abstract final class AccessTokens {
  static const canvas = Color(0xFFF7F8FC);
  static const ink = Color(0xFF17213C);
  static const primary = Color(0xFF4338CA);
  static const muted = Color(0xFF657087);
  static const line = Color(0xFFE1E5EF);
  static const soft = Color(0xFFECEBFF);
  static const darkCanvas = Color(0xFF101426);
  static const darkSurface = Color(0xFF1C233A);
  static const darkInk = Color(0xFFF2F4FC);
  static const darkMuted = Color(0xFFB2BDD4);
  static const darkLine = Color(0xFF36415C);
  static const darkPrimary = Color(0xFFB1A7FF);
  static Color mutedFor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
}
