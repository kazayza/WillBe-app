import '../services/kpi_service.dart';

// ══════════════════════════════════════════════════════════════
// 🔔 نموذج التنبيه
// ══════════════════════════════════════════════════════════════
class KpiAlert {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? action;

  KpiAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.action,
  });

  factory KpiAlert.fromJson(Map<String, dynamic> json) {
    return KpiAlert(
      id: json['id'] ?? DateTime.now().toString(),
      type: json['type'] ?? 'warning',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      action: json['action'],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 🎯 نموذج التوصية
// ══════════════════════════════════════════════════════════════
class KpiRecommendation {
  final String text;
  final String priority;
  final IconType icon;

  KpiRecommendation({
    required this.text,
    required this.priority,
    this.icon = IconType.checkCircle,
  });
}

enum IconType {
  checkCircle,
  warning,
  trending,
  target,
  users,
}

// ══════════════════════════════════════════════════════════════
// 📊 نموذج تحليل الأداء
// ══════════════════════════════════════════════════════════════
class PerformanceAnalysis {
  final String summary;
  final String trend;
  final double changePercent;
  final List<KpiAlert> alerts;
  final List<KpiRecommendation> recommendations;
  final PredictionData? prediction;

  PerformanceAnalysis({
    required this.summary,
    required this.trend,
    required this.changePercent,
    required this.alerts,
    required this.recommendations,
    this.prediction,
  });

  factory PerformanceAnalysis.generate({
    required MainKPIs currentKPIs,
    required List<DistributionItem> branches,
    required double previousAmount,
  }) {
    // حماية من القسمة على صفر
    double change = 0.0;

    if (previousAmount > 0 &&
        previousAmount.isFinite &&
        currentKPIs.totalAmount.isFinite) {
      change =
          ((currentKPIs.totalAmount - previousAmount) / previousAmount) * 100;
    }

    // حماية من NaN و Infinity
    if (change.isNaN || change.isInfinite) {
      change = 0.0;
    }

    final trend = change > 2
        ? 'up'
        : (change < -2 ? 'down' : 'stable');

    // توليد الملخص
    String summary;
    if (change > 0) {
      summary =
          'الإيرادات زادت بنسبة ${change.abs().toStringAsFixed(1)}% مقارنة بالفترة السابقة، مع تحسن ملحوظ في المتوسط اليومي.';
    } else if (change < 0) {
      summary =
          'الإيرادات انخفضت بنسبة ${change.abs().toStringAsFixed(1)}% مقارنة بالفترة السابقة. يُنصح بمراجعة الأداء.';
    } else {
      summary = 'الإيرادات مستقرة مقارنة بالفترة السابقة مع أداء ثابت.';
    }

    // توليد التنبيهات
    List<KpiAlert> alerts = [];

    for (var branch in branches) {
      if (branch.percentage < 10) {
        alerts.add(KpiAlert(
          id: 'branch_${branch.id}',
          type: 'warning',
          title: 'أداء ضعيف',
          message:
              '${branch.name}: نسبة مساهمة ${branch.percentage.toStringAsFixed(1)}% فقط',
        ));
      }
    }

    if (change < -10) {
      alerts.add(KpiAlert(
        id: 'decline',
        type: 'danger',
        title: 'انخفاض حاد',
        message: 'انخفاض الإيرادات بنسبة ${change.abs().toStringAsFixed(1)}%',
      ));
    }

    if (change > 15) {
      alerts.add(KpiAlert(
        id: 'growth',
        type: 'success',
        title: 'نمو ممتاز!',
        message: 'زيادة الإيرادات بنسبة ${change.toStringAsFixed(1)}%',
      ));
    }

    // توليد التوصيات
    List<KpiRecommendation> recommendations = [];

    if (change < 0) {
      recommendations.add(KpiRecommendation(
        text: 'مراجعة أسباب انخفاض الإيرادات',
        priority: 'high',
        icon: IconType.warning,
      ));
    }

    final weakBranches = branches.where((b) => b.percentage < 15).toList();
    if (weakBranches.isNotEmpty) {
      recommendations.add(KpiRecommendation(
        text: 'تعزيز الأداء في ${weakBranches.length} فروع ضعيفة',
        priority: 'high',
        icon: IconType.target,
      ));
    }

    recommendations.add(KpiRecommendation(
      text: 'زيادة التحصيل في الأسبوع الأخير من الشهر',
      priority: 'medium',
      icon: IconType.trending,
    ));

    recommendations.add(KpiRecommendation(
      text: 'استهداف ${(currentKPIs.uniqueChildren * 0.2).round()} طالب إضافي',
      priority: 'medium',
      icon: IconType.users,
    ));

    // التوقعات
    const daysInMonth = 30;
    final daysPassed = currentKPIs.activeDays > 0 ? currentKPIs.activeDays : 1;
    final projectedAmount =
        (currentKPIs.totalAmount / daysPassed) * daysInMonth;

    final prediction = PredictionData(
      projectedAmount: projectedAmount.isFinite ? projectedAmount : 0.0,
      confidence: daysPassed > 15
          ? 'high'
          : (daysPassed > 7 ? 'medium' : 'low'),
      daysRemaining: daysInMonth - daysPassed,
    );

    return PerformanceAnalysis(
      summary: summary,
      trend: trend,
      changePercent: change,
      alerts: alerts,
      recommendations: recommendations,
      prediction: prediction,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// 📈 نموذج التوقعات
// ══════════════════════════════════════════════════════════════
class PredictionData {
  final double projectedAmount;
  final String confidence;
  final int daysRemaining;

  PredictionData({
    required this.projectedAmount,
    required this.confidence,
    required this.daysRemaining,
  });
}