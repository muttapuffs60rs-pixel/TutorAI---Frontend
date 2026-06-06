import 'package:flutter/material.dart';

class Tailwind {
  // Brand / Accents
  static const Color indigo50 = Color(0xFFeef2ff);
  static const Color indigo100 = Color(0xFFe0e7ff);
  static const Color indigo500 = Color(0xFF6366f1);
  static const Color indigo600 = Color(0xFF4f46e5);
  static const Color indigo900 = Color(0xFF312e81);
  
  // Neutrals / Slates
  static const Color white = Color(0xFFffffff);
  static const Color slate50 = Color(0xFFf8fafc);
  static const Color slate100 = Color(0xFFf1f5f9);
  static const Color slate200 = Color(0xFFe2e8f0);
  static const Color slate300 = Color(0xFFcbd5e1);
  static const Color slate400 = Color(0xFF94a3b8);
  static const Color slate500 = Color(0xFF64748b);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1e293b);
  static const Color slate900 = Color(0xFF0f172a);
  
  // Status / Alerts
  static const Color rose500 = Color(0xFFf43f5e);
  static const Color emerald500 = Color(0xFF10b981);
  static const Color amber500 = Color(0xFFf59e0b);

  // Shadows
  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0D000000), // slate900 / 5%
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];
  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x1A000000), // slate900 / 10%
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
    BoxShadow(
      color: Color(0x0F000000), // slate900 / 6%
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -1,
    ),
  ];
  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -2,
    ),
  ];

  // Border Radius
  static BorderRadius roundedMd = BorderRadius.circular(6);
  static BorderRadius roundedLg = BorderRadius.circular(8);
  static BorderRadius roundedXl = BorderRadius.circular(12);
  static BorderRadius rounded2Xl = BorderRadius.circular(16);
  static BorderRadius rounded3Xl = BorderRadius.circular(24);
  static BorderRadius roundedFull = BorderRadius.circular(9999);
}
