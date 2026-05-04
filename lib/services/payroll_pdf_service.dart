import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/payroll_model.dart';

class PayrollPdfService {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  // ======== تحميل الخطوط ========
  static Future<void> _loadFonts() async {
    if (_regularFont != null) return;
    try {
      final regularData =
          await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      _regularFont = pw.Font.ttf(regularData);

      final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      _boldFont = pw.Font.ttf(boldData);
    } catch (e) {
      print('خطأ في تحميل الخطوط: $e');
    }
  }

  // ======== ستايل النص ========
  static pw.TextStyle _textStyle({
    double size = 10,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: bold ? (_boldFont ?? _regularFont) : _regularFont,
      fontBold: _boldFont,
      fontSize: size,
      color: color ?? PdfColors.black,
    );
  }

  // ==============================================================
  // 📄 1. كشف رواتب كامل (كل الموظفين)
  // ==============================================================
  static Future<Uint8List> generatePayrollSheet({
    required List<PayrollModel> employees,
    required int month,
    required int year,
    required String monthName,
    String companyName = 'WillBe Kindergarten',
  }) async {
    await _loadFonts();

    final pdf = pw.Document();
    final selectedEmps = employees.where((e) => e.isSelected).toList();

    // حساب الإجماليات
    double totalBaseSalary = 0;
    double totalExtraTime = 0;
    double totalBadal = 0;
    double totalReward = 0;
    double totalPenalty = 0;
    double totalBusSub = 0;
    double totalAbsence = 0;
    double totalQstSolfa = 0;
    double totalSolfa = 0;
    double totalAdditions = 0;
    double totalDeductions = 0;
    double totalNet = 0;

    for (var emp in selectedEmps) {
      totalBaseSalary += emp.baseSalary;
      totalExtraTime += emp.extraTime;
      totalBadal += emp.badal;
      totalReward += emp.reward;
      totalPenalty += emp.penalty;
      totalBusSub += emp.busSub;
      totalAbsence += emp.absenceAmount;
      totalQstSolfa += emp.qstSolfa;
      totalSolfa += emp.solfa;
      totalAdditions += emp.totalAdditions;
      totalDeductions += emp.totalDeductions;
      totalNet += emp.netForEmployee;
    }

    // تقسيم الموظفين على صفحات (15 موظف لكل صفحة)
    const int perPage = 15;
    for (int pageStart = 0;
        pageStart < selectedEmps.length;
        pageStart += perPage) {
      final pageEnd = (pageStart + perPage > selectedEmps.length)
          ? selectedEmps.length
          : pageStart + perPage;
      final pageEmps = selectedEmps.sublist(pageStart, pageEnd);
      final isLastPage = pageEnd >= selectedEmps.length;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // الهيدر
                _buildPdfHeader(companyName, monthName, year),
                pw.SizedBox(height: 10),

                // الجدول
                pw.TableHelper.fromTextArray(
                  context: context,
                  border: pw.TableBorder.all(
                      color: PdfColors.grey400, width: 0.5),
                  cellAlignment: pw.Alignment.center,
                  cellStyle: _textStyle(size: 7),
                  headerStyle:
                      _textStyle(size: 7, bold: true, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1976D2),
                  ),
                  cellAlignments: {
                    0: pw.Alignment.center,
                    1: pw.Alignment.centerRight,
                  },
                  headerDirection: pw.TextDirection.rtl,
                  cellPadding: const pw.EdgeInsets.all(3),
                  headers: [
                    'م',
                    'كود',
                    'الاسم',
                    'الأساسي',
                    'إضافي',
                    'بدل',
                    'مكافأة',
                    'إجمالي+',
                    'جزاءات',
                    'باص',
                    'غياب',
                    'ق.سلفة',
                    'إجمالي-',
                    'سلفة',
                    'الصافي',
                  ],
                  data: [
                    ...pageEmps.asMap().entries.map((entry) {
                      final i = pageStart + entry.key + 1;
                      final emp = entry.value;
                      return [
                        '$i',
                        '${emp.empId}',
                        emp.empName,
                        emp.baseSalary.toStringAsFixed(0),
                        emp.extraTime.toStringAsFixed(0),
                        emp.badal.toStringAsFixed(0),
                        emp.reward.toStringAsFixed(0),
                        emp.totalAdditions.toStringAsFixed(0),
                        emp.penalty.toStringAsFixed(0),
                        emp.busSub.toStringAsFixed(0),
                        emp.absenceAmount.toStringAsFixed(0),
                        emp.qstSolfa.toStringAsFixed(0),
                        emp.totalDeductions.toStringAsFixed(0),
                        emp.solfa.toStringAsFixed(0),
                        emp.netForEmployee.toStringAsFixed(0),
                      ];
                    }),
                    // صف الإجماليات في آخر صفحة فقط
                    if (isLastPage)
                      [
                        '',
                        '',
                        'الإجمالي',
                        totalBaseSalary.toStringAsFixed(0),
                        totalExtraTime.toStringAsFixed(0),
                        totalBadal.toStringAsFixed(0),
                        totalReward.toStringAsFixed(0),
                        totalAdditions.toStringAsFixed(0),
                        totalPenalty.toStringAsFixed(0),
                        totalBusSub.toStringAsFixed(0),
                        totalAbsence.toStringAsFixed(0),
                        totalQstSolfa.toStringAsFixed(0),
                        totalDeductions.toStringAsFixed(0),
                        totalSolfa.toStringAsFixed(0),
                        totalNet.toStringAsFixed(0),
                      ],
                  ],
                ),
                pw.SizedBox(height: 10),

                // الفوتر
                if (isLastPage)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('عدد الموظفين: ${selectedEmps.length}',
                          style: _textStyle(size: 9, bold: true)),
                      pw.Text(
                          'صافي المطلوب: ${totalNet.toStringAsFixed(2)} ج',
                          style: _textStyle(size: 9, bold: true)),
                    ],
                  ),

                pw.Spacer(),
                // التوقيعات
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSignature('المدير المالي'),
                    _buildSignature('المدير العام'),
                    _buildSignature('المراجع'),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // ==============================================================
  // 🧾 2. شريط قبض لموظف واحد
  // ==============================================================
  // ==============================================================
// 🧾 2. شريط قبض لموظف واحد (النسخة المصححة)
// ==============================================================
static Future<Uint8List> generatePaySlip({
  required PayrollModel employee,
  required int month,
  required int year,
  required String monthName,
  String companyName = 'WillBe Kindergarten',
}) async {
  await _loadFonts();

  final pdf = pw.Document();
  final emp = employee;

  pdf.addPage(
    pw.Page(
      // ✅ تغيير لـ A4 أو تصغير الـ margins
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(15),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // الهيدر
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF1976D2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                children: [
                  pw.Text(companyName,
                      style: _textStyle(
                          size: 14, bold: true, color: PdfColors.white)),
                  pw.SizedBox(height: 2),
                  pw.Text('شريط قبض - شهر $monthName / $year',
                      style: _textStyle(size: 10, color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // بيانات الموظف
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoColumn('كود', '${emp.empId}'),
                  _buildInfoColumn('الاسم', emp.empName),
                  _buildInfoColumn('الوظيفة', emp.job ?? '-'),
                  _buildInfoColumn('الفرع', emp.branchName ?? '-'),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // ✅ الاستحقاقات والاستقطاعات جنب بعض
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // الاستحقاقات (يسار)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFE8F5E9),
                        border: pw.Border.all(
                            color: const PdfColor.fromInt(0xFF4CAF50)),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('الاستحقاقات',
                              style: _textStyle(
                                  size: 11,
                                  bold: true,
                                  color: const PdfColor.fromInt(0xFF2E7D32))),
                          pw.Divider(
                              color: const PdfColor.fromInt(0xFF4CAF50),
                              height: 8),
                          _buildAmountRow('الأساسي', emp.baseSalary),
                          _buildAmountRow('الإضافي', emp.extraTime),
                          _buildAmountRow('البدل', emp.badal),
                          _buildAmountRow('المكافأة', emp.reward),
                          pw.Divider(
                              color: const PdfColor.fromInt(0xFF4CAF50),
                              height: 8),
                          _buildAmountRow('الإجمالي', emp.totalAdditions,
                              bold: true),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),

                  // الاستقطاعات (يمين)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFFFEBEE),
                        border: pw.Border.all(
                            color: const PdfColor.fromInt(0xFFE53935)),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('الاستقطاعات',
                              style: _textStyle(
                                  size: 11,
                                  bold: true,
                                  color: const PdfColor.fromInt(0xFFC62828))),
                          pw.Divider(
                              color: const PdfColor.fromInt(0xFFE53935),
                              height: 8),
                          _buildAmountRow('الجزاءات', emp.penalty),
                          _buildAmountRow('الباص', emp.busSub),
                          _buildAmountRow(
                              'غياب (${emp.absenceDays})', emp.absenceAmount),
                          _buildAmountRow('قسط سلفة', emp.qstSolfa),
                          pw.Divider(
                              color: const PdfColor.fromInt(0xFFE53935),
                              height: 8),
                          _buildAmountRow('الإجمالي', emp.totalDeductions,
                              bold: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // السلفة (لو موجودة)
            if (emp.solfa > 0)
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF3E5F5),
                  border: pw.Border.all(
                      color: const PdfColor.fromInt(0xFF9C27B0)),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child:
                    _buildAmountRow('السلفة المصروفة', emp.solfa, bold: true),
              ),
            pw.SizedBox(height: 8),

            // الصافي
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: emp.netForEmployee >= 0
                    ? const PdfColor.fromInt(0xFF1976D2)
                    : const PdfColor.fromInt(0xFFE53935),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('صافي الراتب',
                      style: _textStyle(
                          size: 12, bold: true, color: PdfColors.white)),
                  pw.Text('${emp.netForEmployee.toStringAsFixed(2)} ج',
                      style: _textStyle(
                          size: 16, bold: true, color: PdfColors.white)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // الملاحظات
            if (emp.notes != null && emp.notes!.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text('ملاحظات: ${emp.notes}',
                    style: _textStyle(size: 8)),
              ),
            pw.SizedBox(height: 8),

            // التوقيع
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildSignature('توقيع الموظف'),
                _buildSignature('توقيع المدير'),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

// ✅ Helper جديد لعرض البيانات بشكل عمودي
static pw.Widget _buildInfoColumn(String label, String value) {
  return pw.Column(
    children: [
      pw.Text(label, style: _textStyle(size: 8, bold: true)),
      pw.SizedBox(height: 2),
      pw.Text(value, style: _textStyle(size: 9)),
    ],
  );
}

  // ======== Helpers ========
  static pw.Widget _buildPdfHeader(
      String companyName, String monthName, int year) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF1976D2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(companyName,
              style: _textStyle(size: 14, bold: true, color: PdfColors.white)),
          pw.Text('كشف رواتب شهر $monthName / $year',
              style: _textStyle(size: 12, color: PdfColors.white)),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: _textStyle(size: 10, bold: true)),
          pw.Text(value, style: _textStyle(size: 10)),
        ],
      ),
    );
  }

  static pw.Widget _buildAmountRow(String label, double amount,
      {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: _textStyle(size: 10, bold: bold)),
          pw.Text('${amount.toStringAsFixed(2)} ج',
              style: _textStyle(size: 10, bold: bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildSignature(String title) {
    return pw.Column(
      children: [
        pw.Text(title, style: _textStyle(size: 8)),
        pw.SizedBox(height: 20),
        pw.Container(
          width: 100,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey)),
          ),
        ),
      ],
    );
  }
}