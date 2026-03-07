import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
// Model للقسط الواحد
// ═══════════════════════════════════════════════════════════════
class InstallmentItem {
  double amount;
  DateTime date;
  final TextEditingController amountController;

  InstallmentItem({
    required this.amount,
    required this.date,
  }) : amountController = TextEditingController(
          text: amount.toStringAsFixed(0),
        );

  double get currentAmount {
    return double.tryParse(amountController.text) ?? 0;
  }

  void dispose() {
    amountController.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════
// أنواع التوزيع
// ═══════════════════════════════════════════════════════════════
enum DistributionType {
  equal,       // متساوي
  descending,  // تنازلي
  ascending,   // تصاعدي
  frontLoaded, // مقدم كبير
}

extension DistributionTypeExtension on DistributionType {
  String get arabicName {
    switch (this) {
      case DistributionType.equal:
        return 'متساوي';
      case DistributionType.descending:
        return 'تنازلي';
      case DistributionType.ascending:
        return 'تصاعدي';
      case DistributionType.frontLoaded:
        return 'مقدم كبير';
    }
  }

  IconData get icon {
    switch (this) {
      case DistributionType.equal:
        return Icons.drag_handle;
      case DistributionType.descending:
        return Icons.trending_down;
      case DistributionType.ascending:
        return Icons.trending_up;
      case DistributionType.frontLoaded:
        return Icons.vertical_align_top;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// قوالب التقسيط الجاهزة
// ═══════════════════════════════════════════════════════════════
class InstallmentTemplate {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int numberOfInstallments;
  final bool isCustom;

  const InstallmentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.numberOfInstallments,
    this.isCustom = false,
  });

  static List<InstallmentTemplate> getTemplates(double totalAmount) {
    final formatter = (double val) => val.toStringAsFixed(0);
    
    return [
      InstallmentTemplate(
        id: 'two',
        name: 'قسطين',
        description: '${formatter(totalAmount / 2)} ج.م × 2',
        icon: Icons.looks_two_rounded,
        color: const Color(0xFF6366F1),
        numberOfInstallments: 2,
      ),
      InstallmentTemplate(
        id: 'three',
        name: 'ربع سنوي',
        description: '${formatter(totalAmount / 3)} ج.م × 3',
        icon: Icons.looks_3_rounded,
        color: const Color(0xFF10B981),
        numberOfInstallments: 3,
      ),
      InstallmentTemplate(
        id: 'four',
        name: '4 أقساط',
        description: '${formatter(totalAmount / 4)} ج.م × 4',
        icon: Icons.looks_4_rounded,
        color: const Color(0xFFF59E0B),
        numberOfInstallments: 4,
      ),
      InstallmentTemplate(
        id: 'six',
        name: 'نصف سنوي',
        description: '${formatter(totalAmount / 6)} ج.م × 6',
        icon: Icons.looks_6_rounded,
        color: const Color(0xFFEC4899),
        numberOfInstallments: 6,
      ),
      InstallmentTemplate(
        id: 'twelve',
        name: 'سنوي',
        description: '${formatter(totalAmount / 12)} ج.م × 12',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF8B5CF6),
        numberOfInstallments: 12,
      ),
      const InstallmentTemplate(
        id: 'custom',
        name: 'تخصيص',
        description: 'حدد عدد الأقساط بنفسك',
        icon: Icons.tune_rounded,
        color: Color(0xFF64748B),
        numberOfInstallments: 0,
        isCustom: true,
      ),
    ];
  }
}