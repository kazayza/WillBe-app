import 'package:flutter/material.dart';
import 'app_colors.dart';

class FinanceTheme {
  FinanceTheme._();

  // === لوحة الألوان الجديدة (Modern Blue & Warm Gold) ===
  static const Color primary = Color(0xFF283593);       // أزرق نيلي دافئ (Indigo 800)
  static const Color primaryLight = Color(0xFF3949AB);  // أزرق نيلي فاتح
  static const Color accent = Color(0xFFFFB300);         // ذهبي دافئ (Amber 600)
  static const Color accentLight = Color(0xFFFFC107);    // ذهبي فاتح

  static const Color success = Color(0xFF00C853);       // أخضر حيوي
  static const Color error = Color(0xFFFF1744);         // أحمر واضح
  static const Color warning = Color(0xFFFF9100);       // برتقالي ذهبي
  static const Color info = Color(0xFF2979FF);          // أزرق معلومات

  static const Color textPrimary = Color(0xFF212121);   // أسود ناعم
  static const Color textSecondary = Color(0xFF757575); // رمادي متوازن
  static const Color textHint = Color(0xFFBDBDBD);     // رمادي باهت

  static const Color border = Color(0xFFE0E0E0);       // بوردر فاتح جداً
  static const Color divider = Color(0xFFF5F5F5);       // فواصل خفيفة

  // === التدرجات ===
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF283593), Color(0xFF3949AB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    colors: [Color(0xFF283593), Color(0xFF1A237E)],
    begin: Alignment(-1.0, -0.5),
    end: Alignment(1.0, 0.5),
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFFB300), Color(0xFFFFC107)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // === دعم الثيم الداكن (بياخد من ملفك القديم بأمان) ===
  static Color bg(BuildContext context) => AppColors.getBg(context);
  static Color card(BuildContext context) => AppColors.getCard(context);
  static Color borderCtx(BuildContext context) => AppColors.getBorder(context);
  static Color text(BuildContext context) => AppColors.getText(context);
  static Color textSec(BuildContext context) => AppColors.getTextSecondary(context);
}