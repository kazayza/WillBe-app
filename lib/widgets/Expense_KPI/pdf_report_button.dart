import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../models/expenses_kpi_model.dart';
import '../../services/expenses_kpi_pdf_service.dart';
import 'kpi_theme.dart';

class PdfReportButton extends StatelessWidget {
  final ExpensesKPIModel data;

  const PdfReportButton({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = KPITheme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // زر الطباعة / المعاينة
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _printReport(context),
              icon: const Icon(Icons.print, size: 18),
              label: const Text('طباعة التقرير'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.appBarBackground,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // زر المشاركة
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _shareReport(context),
              icon: const Icon(Icons.share, size: 18),
              label: const Text('مشاركة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.info,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printReport(BuildContext context) async {
    try {
      _showLoading(context, 'جاري إنشاء التقرير...');

      final pdfBytes = await ExpensesKPIPdfService.generateReport(data);

      if (context.mounted) Navigator.pop(context);

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'تقرير_مصروفات_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showError(context, 'خطأ في إنشاء التقرير: $e');
      }
    }
  }

  Future<void> _shareReport(BuildContext context) async {
    try {
      _showLoading(context, 'جاري إنشاء التقرير...');

      final pdfBytes = await ExpensesKPIPdfService.generateReport(data);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/expenses_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);

      if (context.mounted) Navigator.pop(context);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'تقرير مؤشرات أداء المصروفات',
        text: 'تقرير مؤشرات أداء المصروفات - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showError(context, 'خطأ في مشاركة التقرير: $e');
      }
    }
  }

  void _showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Colors.red,
      ),
    );
  }
}