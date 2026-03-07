import 'package:flutter/material.dart';

class KPITheme {
  final bool isDark;

  KPITheme({required this.isDark});

  // ════════════════════════════════════════
  // 🎨 الألوان الأساسية
  // ════════════════════════════════════════
  Color get background => isDark
      ? const Color(0xFF1A1A2E)
      : const Color(0xFFF5F6FA);

  Color get cardBackground => isDark
      ? const Color(0xFF16213E)
      : Colors.white;

  Color get cardBorder => isDark
      ? const Color(0xFF1F3460)
      : Colors.transparent;

  Color get textPrimary => isDark
      ? const Color(0xFFE0E0E0)
      : const Color(0xFF2C3E50);

  Color get textSecondary => isDark
      ? const Color(0xFF8E8E8E)
      : const Color(0xFF7F8C8D);

  Color get textMuted => isDark
      ? const Color(0xFF5A5A5A)
      : const Color(0xFFBDC3C7);

  Color get divider => isDark
      ? const Color(0xFF1F3460)
      : const Color(0xFFECF0F1);

  Color get sectionBackground => isDark
      ? const Color(0xFF0F3460).withOpacity(0.3)
      : const Color(0xFFF5F6FA);

  Color get appBarBackground => isDark
      ? const Color(0xFF0F3460)
      : const Color(0xFF2C3E50);

  // ════════════════════════════════════════
  // 🎨 ألوان المؤشرات
  // ════════════════════════════════════════
  Color get positive => const Color(0xFF27AE60);
  Color get negative => const Color(0xFFE74C3C);
  Color get warning => const Color(0xFFE67E22);
  Color get info => const Color(0xFF3498DB);
  Color get purple => const Color(0xFF8E44AD);
  Color get teal => const Color(0xFF16A085);

  Color get positiveLight => isDark
      ? const Color(0xFF27AE60).withOpacity(0.15)
      : const Color(0xFF27AE60).withOpacity(0.08);

  Color get negativeLight => isDark
      ? const Color(0xFFE74C3C).withOpacity(0.15)
      : const Color(0xFFE74C3C).withOpacity(0.08);

  Color get warningLight => isDark
      ? const Color(0xFFE67E22).withOpacity(0.15)
      : const Color(0xFFE67E22).withOpacity(0.08);

  Color get infoLight => isDark
      ? const Color(0xFF3498DB).withOpacity(0.15)
      : const Color(0xFF3498DB).withOpacity(0.08);

  // ════════════════════════════════════════
  // 📦 ديكور الكارت
  // ════════════════════════════════════════
  BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(16),
    border: isDark ? Border.all(color: cardBorder, width: 0.5) : null,
    boxShadow: isDark
        ? []
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
  );

  // ════════════════════════════════════════
  // 🔧 دالة مساعدة
  // ════════════════════════════════════════
  static KPITheme of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return KPITheme(isDark: brightness == Brightness.dark);
  }
}