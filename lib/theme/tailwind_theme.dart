import 'package:flutter/material.dart';

class Tailwind {
  // Brand / Accents
  static const Color indigo50 = Color(0xFFeef2ff);
  static const Color indigo100 = Color(0xFFe0e7ff);
  static const Color indigo200 = Color(0xFFc7d2fe);
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
  static const Color rose400 = Color(0xFFfb7185);
  static const Color rose500 = Color(0xFFf43f5e);
  static const Color rose600 = Color(0xFFe11d48);
  
  static const Color emerald400 = Color(0xFF34d399);
  static const Color emerald500 = Color(0xFF10b981);
  static const Color emerald600 = Color(0xFF059669);
  
  static const Color amber50 = Color(0xFFfffbeb);
  static const Color amber200 = Color(0xFFfde68a);
  static const Color amber500 = Color(0xFFf59e0b);
  static const Color amber600 = Color(0xFFd97706);
  static const Color amber700 = Color(0xFFb45309);

  // Additional Subject Colors
  static const Color blue400 = Color(0xFF60a5fa);
  static const Color blue500 = Color(0xFF3b82f6);
  static const Color blue600 = Color(0xFF2563eb);
  
  static const Color teal500 = Color(0xFF14b8a6);
  static const Color teal600 = Color(0xFF0d9488);
  
  static const Color orange400 = Color(0xFFfb923c);
  static const Color orange500 = Color(0xFFf97316);
  static const Color orange600 = Color(0xFFea580c);
  
  static const Color yellow500 = Color(0xFFeab308);
  static const Color yellow600 = Color(0xFFca8a04);
  static const Color yellow700 = Color(0xFFa16207);
  
  static const Color cyan500 = Color(0xFF06b6d4);
  static const Color cyan600 = Color(0xFF0891b2);
  static const Color cyan700 = Color(0xFF0e7490);
  
  static const Color green500 = Color(0xFF22c55e);
  static const Color green600 = Color(0xFF16a34a);
  static const Color green700 = Color(0xFF15803d);
  
  static const Color indigo400 = Color(0xFF818cf8);
  
  static const Color purple500 = Color(0xFFa855f7);
  static const Color purple600 = Color(0xFF9333ea);
  
  static const Color red500 = Color(0xFFef4444);
  
  static const Color pink400 = Color(0xFFf472b6);
  static const Color pink500 = Color(0xFFec4899);
  
  static const Color blueGrey = Color(0xFF607d8b);

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
  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 8),
      blurRadius: 10,
      spreadRadius: -6,
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
