import 'package:flutter/material.dart';

class AppColors {
  // ══════════════════════════════════════════════════════════
  // 🎨 الألوان الأساسية (Brand Colors)
  // ══════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color secondary = Color(0xFF10B981);
  
  // ══════════════════════════════════════════════════════════
  // 💰 ألوان شاشة الرواتب
  // ══════════════════════════════════════════════════════════
  
  // الاستحقاقات
  static const Color payrollAdditions = Color(0xFF10B981);
  static const Color payrollAdditionsLight = Color(0xFFE8F5E9);
  static const Color payrollAdditionsBorder = Color(0xFF81C784);
  
  // الاستقطاعات
  static const Color payrollDeductions = Color(0xFFEF4444);
  static const Color payrollDeductionsLight = Color(0xFFFFEBEE);
  static const Color payrollDeductionsBorder = Color(0xFFE57373);
  
  // السلفة
  static const Color payrollAdvance = Color(0xFF9C27B0);
  static const Color payrollAdvanceLight = Color(0xFFF3E5F5);
  static const Color payrollAdvanceBorder = Color(0xFFBA68C8);
  
  // المسودة
  static const Color payrollDraft = Color(0xFFF57C00);
  static const Color payrollDraftLight = Color(0xFFFFF3E0);
  static const Color payrollDraftBorder = Color(0xFFFFB74D);
  
  // المعتمد
  static const Color payrollApproved = Color(0xFF10B981);
  static const Color payrollApprovedLight = Color(0xFFE8F5E9);
  static const Color payrollApprovedBorder = Color(0xFF81C784);
  
  // السالب/التحذير
  static const Color payrollNegative = Color(0xFFEF4444);
  static const Color payrollNegativeLight = Color(0xFFFFEBEE);
  
  // صافي الموظف
  static const Color payrollNetPositive = Color(0xFF1976D2);
  static const Color payrollNetNegative = Color(0xFFEF4444);
  
  // عدد الموظفين
  static const Color payrollCount = Color(0xFF3949AB);
  static const Color payrollCountLight = Color(0xFFE8EAF6);
  static const Color payrollCountBorder = Color(0xFF7986CB);
  
  // ══════════════════════════════════════════════════════════
  // 🌙 Light Mode
  // ══════════════════════════════════════════════════════════
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightCard = Colors.white;
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightDisabled = Color(0xFFE0E0E0);
  
  // ══════════════════════════════════════════════════════════
  // 🌑 Dark Mode
  // ══════════════════════════════════════════════════════════
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDisabled = Color(0xFF475569);
  
  // ══════════════════════════════════════════════════════════
  // 🎯 ألوان الحالات العامة
  // ══════════════════════════════════════════════════════════
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFE8F5E9);
  
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFF3E0);
  
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFFEBEE);
  
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFE3F2FD);
  
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
  // 🔧 Helper Methods - النسخة الجديدة (BuildContext)
  // ══════════════════════════════════════════════════════════
  
  static Color getBg(dynamic contextOrBool) {
    if (contextOrBool is BuildContext) {
      return Theme.of(contextOrBool).brightness == Brightness.dark 
          ? darkBg 
          : lightBg;
    } else if (contextOrBool is bool) {
      return contextOrBool ? darkBg : lightBg;
    }
    return lightBg;
  }
  
  static Color getCard(dynamic contextOrBool) {
    if (contextOrBool is BuildContext) {
      return Theme.of(contextOrBool).brightness == Brightness.dark 
          ? darkCard 
          : lightCard;
    } else if (contextOrBool is bool) {
      return contextOrBool ? darkCard : lightCard;
    }
    return lightCard;
  }
  
  static Color getText(dynamic contextOrBool) {
    if (contextOrBool is BuildContext) {
      return Theme.of(contextOrBool).brightness == Brightness.dark 
          ? darkText 
          : lightText;
    } else if (contextOrBool is bool) {
      return contextOrBool ? darkText : lightText;
    }
    return lightText;
  }
  
  static Color getTextSecondary(dynamic contextOrBool) {
    if (contextOrBool is BuildContext) {
      return Theme.of(contextOrBool).brightness == Brightness.dark 
          ? darkTextSecondary 
          : lightTextSecondary;
    } else if (contextOrBool is bool) {
      return contextOrBool ? darkTextSecondary : lightTextSecondary;
    }
    return lightTextSecondary;
  }
  
  static Color getBorder(dynamic contextOrBool) {
    if (contextOrBool is BuildContext) {
      return Theme.of(contextOrBool).brightness == Brightness.dark 
          ? darkBorder 
          : lightBorder;
    } else if (contextOrBool is bool) {
      return contextOrBool ? darkBorder : lightBorder;
    }
    return lightBorder;
  }
  
  static Color getDisabled(dynamic contextOrBool) {
    if (contextOrBool is BuildContext) {
      return Theme.of(contextOrBool).brightness == Brightness.dark 
          ? darkDisabled 
          : lightDisabled;
    } else if (contextOrBool is bool) {
      return contextOrBool ? darkDisabled : lightDisabled;
    }
    return lightDisabled;
  }
  
  static bool isDark(dynamic contextOrBool) {
    if (contextOrBool is BuildContext) {
      return Theme.of(contextOrBool).brightness == Brightness.dark;
    } else if (contextOrBool is bool) {
      return contextOrBool;
    }
    return false;
  }
  
  static Color getChartColor(int index) => 
      chartColors[index % chartColors.length];
  
  // ══════════════════════════════════════════════════════════
  // 🎴 Card Decoration
  // ══════════════════════════════════════════════════════════
  static BoxDecoration getCardDecoration(
    dynamic contextOrBool, {
    Color? customColor,
    Color? borderColor,
    double borderRadius = 12,
    double borderWidth = 1,
  }) {
    final isDarkMode = isDark(contextOrBool);
    
    return BoxDecoration(
      color: customColor ?? getCard(contextOrBool),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? getBorder(contextOrBool), 
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: isDarkMode 
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // ══════════════════════════════════════════════════════════
  // 💰 Payroll Specific Decorations
  // ══════════════════════════════════════════════════════════
  
  static BoxDecoration getAdditionsCardDecoration() {
    return BoxDecoration(
      color: payrollAdditionsLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: payrollAdditions, width: 1.5),
    );
  }
  
  static BoxDecoration getDeductionsCardDecoration() {
    return BoxDecoration(
      color: payrollDeductionsLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: payrollDeductions, width: 1.5),
    );
  }
  
  static BoxDecoration getAdvanceCardDecoration() {
    return BoxDecoration(
      color: payrollAdvanceLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: payrollAdvanceBorder, width: 1),
    );
  }
  
  static BoxDecoration getDraftCardDecoration() {
    return BoxDecoration(
      color: payrollDraftLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: payrollDraft, width: 1.5),
    );
  }
  
  static BoxDecoration getApprovedCardDecoration() {
    return BoxDecoration(
      color: payrollApprovedLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: payrollApproved, width: 1.5),
    );
  }
  
  static BoxDecoration getCountCardDecoration() {
    return BoxDecoration(
      color: payrollCountLight,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: payrollCountBorder, width: 1.5),
    );
  }
  
  static BoxDecoration getSummaryCardDecoration(Color color) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
    );
  }
  
  static LinearGradient getNetGradient(bool isPositive) {
    return LinearGradient(
      colors: isPositive
          ? [payrollNetPositive, const Color(0xFF1565C0)]
          : [payrollNetNegative, const Color(0xFFD32F2F)],
    );
  }
  
  // ══════════════════════════════════════════════════════════
  // 🌈 Gradients
  // ══════════════════════════════════════════════════════════
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

 
}