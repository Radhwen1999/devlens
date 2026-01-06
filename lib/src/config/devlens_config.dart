import 'package:flutter/material.dart';

/// Configuration for DevLens
class DevLensConfig {
  /// Maximum number of requests to store
  final int maxRequests;

  /// Whether to show performance metrics
  final bool showMetrics;

  /// Theme configuration
  final DevLensTheme theme;

  const DevLensConfig({
    this.maxRequests = 200,
    this.showMetrics = true,
    this.theme = const DevLensTheme(),
  });
}

/// Theme for the DevLens floating panel
class DevLensTheme {
  // Background colors
  final Color panelBackground;
  final Color headerBackground;
  final Color codeBackground;

  // Text colors
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Syntax highlighting
  final Color jsonKey;
  final Color jsonString;
  final Color jsonNumber;
  final Color jsonBoolean;
  final Color jsonNull;
  final Color highlightColor;
  final Color highlightBorder;

  // Status colors
  final Color success;
  final Color warning;
  final Color error;

  // Accent
  final Color accent;

  // Border
  final Color border;

  // Shadow
  final List<BoxShadow> shadow;

  const DevLensTheme({
    this.panelBackground = const Color(0xFF0D1117),
    this.headerBackground = const Color(0xFF161B22),
    this.codeBackground = const Color(0xFF0D1117),
    this.textPrimary = const Color(0xFFE6EDF3),
    this.textSecondary = const Color(0xFF8B949E),
    this.textMuted = const Color(0xFF6E7681),
    this.jsonKey = const Color(0xFF79C0FF),
    this.jsonString = const Color(0xFFA5D6FF),
    this.jsonNumber = const Color(0xFF79C0FF),
    this.jsonBoolean = const Color(0xFFFF7B72),
    this.jsonNull = const Color(0xFF8B949E),
    this.highlightColor = const Color(0xFF1F6FEB),
    this.highlightBorder = const Color(0xFF58A6FF),
    this.success = const Color(0xFF3FB950),
    this.warning = const Color(0xFFD29922),
    this.error = const Color(0xFFF85149),
    this.accent = const Color(0xFF58A6FF),
    this.border = const Color(0xFF30363D),
    this.shadow = const [
      BoxShadow(
        color: Color(0x40000000),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
      BoxShadow(
        color: Color(0x20000000),
        blurRadius: 48,
        offset: Offset(0, 16),
      ),
    ],
  });

  /// Light theme preset
  static const DevLensTheme light = DevLensTheme(
    panelBackground: Color(0xFFFFFFFF),
    headerBackground: Color(0xFFF6F8FA),
    codeBackground: Color(0xFFF6F8FA),
    textPrimary: Color(0xFF24292F),
    textSecondary: Color(0xFF57606A),
    textMuted: Color(0xFF8C959F),
    jsonKey: Color(0xFF0550AE),
    jsonString: Color(0xFF0A3069),
    jsonNumber: Color(0xFF0550AE),
    jsonBoolean: Color(0xFFCF222E),
    jsonNull: Color(0xFF8C959F),
    highlightColor: Color(0xFFDDF4FF),
    highlightBorder: Color(0xFF54AEFF),
    success: Color(0xFF1A7F37),
    warning: Color(0xFF9A6700),
    error: Color(0xFFCF222E),
    accent: Color(0xFF0969DA),
    border: Color(0xFFD0D7DE),
    shadow: [
      BoxShadow(
        color: Color(0x15000000),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
  );
}