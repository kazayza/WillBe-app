import 'package:flutter/material.dart';

class AppColors {
  // ══════════════════════════════════════════════════════════
  // 🎨 الألوان الأساسية
  // ══════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF8B5CF6);
  static const Color secondary = Color(0xFF10B981);
  
  // ══════════════════════════════════════════════════════════
  // 🌙 Light Mode
  // ══════════════════════════════════════════════════════════
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Colors.white;
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);
  
  // ══════════════════════════════════════════════════════════
  // 🌑 Dark Mode
  // ══════════════════════════════════════════════════════════
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
  
  // ══════════════════════════════════════════════════════════
  // 🎯 ألوان الحالات
  // ══════════════════════════════════════════════════════════
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // ══════════════════════════════════════════════════════════
  // 📊 ألوان الـ Charts
  // ══════════════════════════════════════════════════════════
  static const List<Color> chartColors = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFF3B82F6),
  ];
  
  // ══════════════════════════════════════════════════════════
  // 🔧 Helper Methods
  // ══════════════════════════════════════════════════════════
  
  static Color getBg(bool isDark) => isDark ? darkBg : lightBg;
  
  static Color getCard(bool isDark) => isDark ? darkCard : lightCard;
  
  static Color getText(bool isDark) => isDark ? darkText : lightText;
  
  static Color getTextSecondary(bool isDark) => 
      isDark ? darkTextSecondary : lightTextSecondary;
  
  static Color getBorder(bool isDark) => isDark ? darkBorder : lightBorder;
  
  static Color getChartColor(int index) => 
      chartColors[index % chartColors.length];
      
  // ══════════════════════════════════════════════════════════
  // 🎴 Card Decoration
  // ══════════════════════════════════════════════════════════
  static BoxDecoration getCardDecoration(bool isDark, {Color? shadowColor}) {
    return BoxDecoration(
      color: getCard(isDark),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: getBorder(isDark), width: 1),
      boxShadow: [
        BoxShadow(
          color: shadowColor?.withOpacity(0.1) ?? 
                 (isDark ? Colors.black26 : Colors.black12),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // ══════════════════════════════════════════════════════════
  // 🌈 Gradient
  // ══════════════════════════════════════════════════════════
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}