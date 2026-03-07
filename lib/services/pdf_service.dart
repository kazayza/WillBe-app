import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'kpi_service.dart';
import '../models/Income_kpi_analysis_models.dart';

class PdfService {
  static Future<void> generateAndShareReport({
    required BuildContext context,
    required DashboardData data,
    required String period,
    required DateTime fromDate,
    required DateTime toDate,
    PerformanceAnalysis? analysis,
  }) async {
    final pdf = pw.Document();
    
    // استخدام تنسيق الأرقام الإنجليزية
    final currencyFormat = NumberFormat('#,###', 'en_US'); 
    final dateFormat = DateFormat('yyyy/MM/dd');
    final monthYearFormat = DateFormat('MMMM yyyy', 'ar');

    // 📅 حساب تواريخ الفترة السابقة بدقة للعرض
    final duration = toDate.difference(fromDate);
    final prevFromDate = fromDate.subtract(duration + const Duration(days: 1));
    final prevToDate = fromDate.subtract(const Duration(days: 1));

    // تحميل الخط العربي
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicFontBold = await PdfGoogleFonts.cairoBold();

    // حساب البيانات
    final totalAmount = data.mainKPIs.totalAmount;
    final changePercent = data.mainKPIs.changes?.totalAmount ?? 0;
    final previousAmount = changePercent != -100 && changePercent != 0
        ? totalAmount / (1 + changePercent / 100)
        : totalAmount * 0.9;

    // ألوان
    final primaryColor = PdfColor.fromHex('#6366F1');
    final successColor = PdfColor.fromHex('#10B981');
    final errorColor = PdfColor.fromHex('#EF4444');
    final warningColor = PdfColor.fromHex('#F59E0B');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFontBold,
        ),
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(
          arabicFontBold,
          dateFormat,
          monthYearFormat,
          fromDate,
          toDate,
          prevFromDate, // 🆕 تاريخ البدء السابق
          prevToDate,   // 🆕 تاريخ الانتهاء السابق
          period,
          primaryColor,
        ),
        footer: (context) => _buildFooter(context, arabicFont),
        build: (context) => [
          // 1️⃣ الملخص التنفيذي
          _buildSectionTitle('الملخص التنفيذي', arabicFontBold, primaryColor),
          pw.SizedBox(height: 10),
          _buildExecutiveSummary(
            data: data,
            currencyFormat: currencyFormat,
            previousAmount: previousAmount,
            changePercent: changePercent,
            arabicFont: arabicFont,
            arabicFontBold: arabicFontBold,
            primaryColor: primaryColor,
            successColor: successColor,
            errorColor: errorColor,
          ),
          pw.SizedBox(height: 25),

          // 2️⃣ المؤشرات الأساسية
          _buildSectionTitle('المؤشرات الأساسية', arabicFontBold, primaryColor),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildKpiCard(
                  title: 'إجمالي الإيرادات',
                  value: '${currencyFormat.format(data.mainKPIs.totalAmount.round())} ج.م',
                  change: data.mainKPIs.changes?.totalAmount,
                  color: primaryColor,
                  arabicFont: arabicFont,
                  arabicFontBold: arabicFontBold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildKpiCard(
                  title: 'المتوسط اليومي',
                  value: '${currencyFormat.format(data.mainKPIs.dailyAverage.round())} ج.م',
                  change: data.mainKPIs.changes?.dailyAverage,
                  color: successColor,
                  arabicFont: arabicFont,
                  arabicFontBold: arabicFontBold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildKpiCard(
                  title: 'عدد العمليات',
                  value: '${data.mainKPIs.totalTransactions}',
                  change: data.mainKPIs.changes?.totalTransactions,
                  color: warningColor,
                  arabicFont: arabicFont,
                  arabicFontBold: arabicFontBold,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildKpiCard(
                  title: 'الأطفال المحصلين',
                  value: '${data.mainKPIs.uniqueChildren}',
                  change: null,
                  color: PdfColor.fromHex('#EC4899'),
                  arabicFont: arabicFont,
                  arabicFontBold: arabicFontBold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 25),

          // 3️⃣ جدول المقارنة
          _buildSectionTitle('مقارنة الفترات', arabicFontBold, primaryColor),
          pw.SizedBox(height: 10),
          _buildComparisonTable(
            data: data,
            currencyFormat: currencyFormat,
            previousAmount: previousAmount,
            arabicFont: arabicFont,
            arabicFontBold: arabicFontBold,
            successColor: successColor,
            errorColor: errorColor,
          ),
          pw.SizedBox(height: 25),

          // 4️⃣ ترتيب الفروع
          if (data.distributions.byBranch.isNotEmpty) ...[
            _buildSectionTitle('ترتيب الفروع', arabicFontBold, primaryColor),
            pw.SizedBox(height: 10),
            _buildBranchRanking(
              branches: data.distributions.byBranch,
              currencyFormat: currencyFormat,
              arabicFont: arabicFont,
              arabicFontBold: arabicFontBold,
              primaryColor: primaryColor,
            ),
            pw.SizedBox(height: 25),
          ],

          // 5️⃣ مقارنة أفضل فرعين
          if (data.distributions.byBranch.length >= 2) ...[
            _buildSectionTitle('مقارنة أفضل فرعين', arabicFontBold, primaryColor),
            pw.SizedBox(height: 10),
            _buildTopBranchesComparison(
              branches: data.distributions.byBranch,
              currencyFormat: currencyFormat,
              arabicFont: arabicFont,
              arabicFontBold: arabicFontBold,
              primaryColor: primaryColor,
              successColor: successColor,
            ),
            pw.SizedBox(height: 25),
          ],

          // 6️⃣ توزيع الأنواع
          if (data.distributions.byKind.isNotEmpty) ...[
            _buildSectionTitle('توزيع الأنواع', arabicFontBold, primaryColor),
            pw.SizedBox(height: 10),
            _buildDistributionTable(
              items: data.distributions.byKind,
              currencyFormat: currencyFormat,
              arabicFont: arabicFont,
              arabicFontBold: arabicFontBold,
              nameKey: 'النوع',
            ),
            pw.SizedBox(height: 25),
          ],

          // 7️⃣ توزيع الفروع
          if (data.distributions.byBranch.isNotEmpty) ...[
            _buildSectionTitle('توزيع الفروع', arabicFontBold, primaryColor),
            pw.SizedBox(height: 10),
            _buildDistributionTable(
              items: data.distributions.byBranch,
              currencyFormat: currencyFormat,
              arabicFont: arabicFont,
              arabicFontBold: arabicFontBold,
              nameKey: 'الفرع',
            ),
            pw.SizedBox(height: 25),
          ],

          // 8️⃣ التوصيات والتوقعات
          if (analysis != null) ...[
            _buildSectionTitle('التحليل والتوصيات', arabicFontBold, primaryColor),
            pw.SizedBox(height: 10),
            _buildAnalysisSection(
              analysis: analysis,
              currencyFormat: currencyFormat,
              arabicFont: arabicFont,
              arabicFontBold: arabicFontBold,
              primaryColor: primaryColor,
              successColor: successColor,
              warningColor: warningColor,
              errorColor: errorColor,
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        return await pdf.save();
      },
      format: PdfPageFormat.a4, 
      name: 'تقرير_مؤشرات_أداء_الإيرادات.pdf',
    );
  }

  // ══════════════════════════════════════════════════════════════
  // 🟢 Helper Widgets
  // ══════════════════════════════════════════════════════════════

  // 📐 رسم سهم هندسي (Vector) بدل النص لضمان الوضوح وعدم حدوث أخطاء
  static pw.Widget _buildArrowIcon(bool isUp, PdfColor color) {
    return pw.Container(
      width: 8,
      height: 8,
      child: pw.CustomPaint(
        size: const PdfPoint(8, 8),
        painter: (PdfGraphics canvas, PdfPoint size) {
          canvas.setFillColor(color);
          if (isUp) {
            // سهم لأعلى
            canvas.moveTo(0, 0);
            canvas.lineTo(size.x / 2, size.y);
            canvas.lineTo(size.x, 0);
          } else {
            // سهم لأسفل
            canvas.moveTo(0, size.y);
            canvas.lineTo(size.x / 2, 0);
            canvas.lineTo(size.x, size.y);
          }
          canvas.fillPath();
        },
      ),
    );
  }

  static pw.Widget _buildHeader(
    pw.Font arabicFontBold,
    DateFormat dateFormat,
    DateFormat monthYearFormat,
    DateTime fromDate,
    DateTime toDate,
    DateTime prevFrom,
    DateTime prevTo,
    String periodType,
    PdfColor primaryColor,
  ) {
    String periodText = '';
    if (periodType == 'custom') {
      periodText = '${dateFormat.format(fromDate)} - ${dateFormat.format(toDate)}';
    } else {
      periodText = monthYearFormat.format(fromDate);
    }

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'تقرير مؤشرات أداء الإيرادات',
                style: pw.TextStyle(
                  font: arabicFontBold,
                  fontSize: 20,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 8),
              // الفترة الحالية
              pw.Row(children: [
                pw.Text('الفترة الحالية: ', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, font: arabicFontBold)),
                pw.Text(periodText, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              ]),
              pw.SizedBox(height: 2),
              // فترة المقارنة (واضحة جداً الآن)
              pw.Row(children: [
                pw.Text('فترة المقارنة: ', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, font: arabicFontBold)),
                pw.Text('${dateFormat.format(prevFrom)} - ${dateFormat.format(prevTo)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ]),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'KPI',
              style: pw.TextStyle(
                  fontSize: 14, 
                  fontWeight: pw.FontWeight.bold, 
                  color: PdfColors.white
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font arabicFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'تم إنشاء التقرير بتاريخ ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}',
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: pw.TextStyle(
              font: arabicFont,
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionTitle(
    String title,
    pw.Font arabicFontBold,
    PdfColor primaryColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F0F0FF'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: primaryColor,
          width: 1,
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: arabicFontBold,
          fontSize: 14,
          color: primaryColor,
        ),
      ),
    );
  }

  static pw.Widget _buildExecutiveSummary({
    required DashboardData data,
    required NumberFormat currencyFormat,
    required double previousAmount,
    required double changePercent,
    required pw.Font arabicFont,
    required pw.Font arabicFontBold,
    required PdfColor primaryColor,
    required PdfColor successColor,
    required PdfColor errorColor,
  }) {
    final isPositive = changePercent >= 0;
    final changeColor = isPositive ? successColor : errorColor;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [
            PdfColor.fromHex('#4F46E5'), 
            PdfColor.fromHex('#4338CA'),
          ],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'إجمالي الإيرادات',
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 13,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${currencyFormat.format(data.mainKPIs.totalAmount.round())} ج.م',
                    style: pw.TextStyle(
                      font: arabicFontBold,
                      fontSize: 28,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Row(
                  children: [
                    _buildArrowIcon(isPositive, changeColor),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      '${changePercent.abs().toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        font: arabicFontBold,
                        fontSize: 14,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('العمليات', '${data.mainKPIs.totalTransactions}', arabicFont, arabicFontBold),
                _buildMiniStat('المتوسط اليومي', '${currencyFormat.format(data.mainKPIs.dailyAverage.round())} ج.م', arabicFont, arabicFontBold),
                _buildMiniStat('الأطفال', '${data.mainKPIs.uniqueChildren}', arabicFont, arabicFontBold),
                _buildMiniStat('أيام النشاط', '${data.mainKPIs.activeDays}', arabicFont, arabicFontBold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMiniStat(String label, String value, pw.Font arabicFont, pw.Font arabicFontBold) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(font: arabicFontBold, fontSize: 11, color: PdfColors.black),
        ),
      ],
    );
  }

  static pw.Widget _buildKpiCard({
    required String title,
    required String value,
    required double? change,
    required PdfColor color,
    required pw.Font arabicFont,
    required pw.Font arabicFontBold,
  }) {
    final isPositive = (change ?? 0) >= 0;
    final changeColor = isPositive ? PdfColor.fromHex('#10B981') : PdfColor.fromHex('#EF4444');

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(font: arabicFontBold, fontSize: 12, color: color),
          ),
          if (change != null) ...[
            pw.SizedBox(height: 5),
            pw.Row(
              children: [
                _buildArrowIcon(isPositive, changeColor),
                pw.SizedBox(width: 4),
                pw.Text(
                  '${change.abs().toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 8,
                    color: changeColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildComparisonTable({
    required DashboardData data,
    required NumberFormat currencyFormat,
    required double previousAmount,
    required pw.Font arabicFont,
    required pw.Font arabicFontBold,
    required PdfColor successColor,
    required PdfColor errorColor,
  }) {
    final prevTransactions = data.mainKPIs.changes?.totalTransactions != null
        ? data.mainKPIs.totalTransactions / (1 + data.mainKPIs.changes!.totalTransactions! / 100)
        : data.mainKPIs.totalTransactions * 0.9;

    final prevAvg = data.mainKPIs.changes?.avgTransaction != null
        ? data.mainKPIs.avgTransaction / (1 + data.mainKPIs.changes!.avgTransaction! / 100)
        : data.mainKPIs.avgTransaction * 0.9;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('المؤشر', arabicFontBold, isHeader: true),
            _buildTableCell('الفترة الحالية', arabicFontBold, isHeader: true),
            _buildTableCell('الفترة السابقة', arabicFontBold, isHeader: true),
            _buildTableCell('التغيير', arabicFontBold, isHeader: true),
          ],
        ),
        _buildComparisonRow(
          'إجمالي الإيرادات',
          '${currencyFormat.format(data.mainKPIs.totalAmount.round())} ج.م',
          '${currencyFormat.format(previousAmount.round())} ج.م',
          data.mainKPIs.changes?.totalAmount ?? 0,
          arabicFont,
          successColor,
          errorColor,
        ),
        _buildComparisonRow(
          'عدد العمليات',
          '${data.mainKPIs.totalTransactions}',
          '${prevTransactions.round()}',
          data.mainKPIs.changes?.totalTransactions ?? 0,
          arabicFont,
          successColor,
          errorColor,
        ),
        _buildComparisonRow(
          'متوسط العملية',
          '${currencyFormat.format(data.mainKPIs.avgTransaction.round())} ج.م',
          '${currencyFormat.format(prevAvg.round())} ج.م',
          data.mainKPIs.changes?.avgTransaction ?? 0,
          arabicFont,
          successColor,
          errorColor,
        ),
      ],
    );
  }

  static pw.TableRow _buildComparisonRow(
    String label,
    String current,
    String previous,
    double change,
    pw.Font arabicFont,
    PdfColor successColor,
    PdfColor errorColor,
  ) {
    final isPositive = change >= 0;
    final color = isPositive ? successColor : errorColor;

    return pw.TableRow(
      children: [
        _buildTableCell(label, arabicFont),
        _buildTableCell(current, arabicFont),
        _buildTableCell(previous, arabicFont, color: PdfColors.grey600),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _buildArrowIcon(isPositive, color),
              pw.SizedBox(width: 4),
              pw.Text(
                '${change.abs().toStringAsFixed(1)}%',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 9,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          color: color ?? PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildBranchRanking({
    required List<DistributionItem> branches,
    required NumberFormat currencyFormat,
    required pw.Font arabicFont,
    required pw.Font arabicFontBold,
    required PdfColor primaryColor,
  }) {
    final sortedBranches = List<DistributionItem>.from(branches)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return pw.Column(
      children: sortedBranches.take(5).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final branch = entry.value;
        
        String rankText;
        PdfColor bgColor;
        
        if (index == 0) {
          rankText = 'الأول';
          bgColor = PdfColor.fromHex('#FEF3C7');
        } else if (index == 1) {
          rankText = 'الثاني';
          bgColor = PdfColor.fromHex('#F3F4F6');
        } else if (index == 2) {
          rankText = 'الثالث';
          bgColor = PdfColor.fromHex('#FFEDD5');
        } else {
          rankText = '${index + 1}';
          bgColor = PdfColors.white;
        }

        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: bgColor,
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 40,
                child: pw.Text(
                  rankText,
                  style: pw.TextStyle(font: arabicFontBold, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Text(
                  branch.name,
                  style: pw.TextStyle(font: arabicFontBold, fontSize: 10),
                ),
              ),
              pw.Text(
                '${currencyFormat.format(branch.amount.round())} ج.م',
                style: pw.TextStyle(font: arabicFont, fontSize: 10),
              ),
              pw.SizedBox(width: 15),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Text(
                  '${branch.percentage.toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    font: arabicFontBold,
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildTopBranchesComparison({
    required List<DistributionItem> branches,
    required NumberFormat currencyFormat,
    required pw.Font arabicFont,
    required pw.Font arabicFontBold,
    required PdfColor primaryColor,
    required PdfColor successColor,
  }) {
    final sortedBranches = List<DistributionItem>.from(branches)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final branch1 = sortedBranches[0];
    final branch2 = sortedBranches[1];

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: _buildBranchCard(branch1, currencyFormat, arabicFont, arabicFontBold, primaryColor, true),
          ),
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 15),
            child: pw.Text('ضد', style: pw.TextStyle(font: arabicFontBold, fontSize: 14, color: PdfColors.grey500)),
          ),
          pw.Expanded(
            child: _buildBranchCard(branch2, currencyFormat, arabicFont, arabicFontBold, successColor, false),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBranchCard(
    DistributionItem branch,
    NumberFormat currencyFormat,
    pw.Font arabicFont,
    pw.Font arabicFontBold,
    PdfColor color,
    bool isWinner,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100, 
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        children: [
          if (isWinner)
            pw.Text('الفائز', style: pw.TextStyle(font: arabicFontBold, fontSize: 10, color: color)),
          pw.SizedBox(height: 5),
          pw.Text(
            branch.name,
            style: pw.TextStyle(font: arabicFontBold, fontSize: 11, color: color),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${currencyFormat.format(branch.amount.round())} ج.م',
            style: pw.TextStyle(font: arabicFontBold, fontSize: 14, color: PdfColors.black),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '${branch.transactions} عملية',
            style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDistributionTable({
    required List<DistributionItem> items,
    required NumberFormat currencyFormat,
    required pw.Font arabicFont,
    required pw.Font arabicFontBold,
    required String nameKey,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell(nameKey, arabicFontBold, isHeader: true),
            _buildTableCell('الإيرادات', arabicFontBold, isHeader: true),
            _buildTableCell('العمليات', arabicFontBold, isHeader: true),
            _buildTableCell('النسبة', arabicFontBold, isHeader: true),
          ],
        ),
        ...items.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell(item.name, arabicFont),
              _buildTableCell('${currencyFormat.format(item.amount.round())} ج.م', arabicFont),
              _buildTableCell('${item.transactions}', arabicFont),
              _buildTableCell('${item.percentage.toStringAsFixed(1)}%', arabicFont),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildAnalysisSection({
    required PerformanceAnalysis analysis,
    required NumberFormat currencyFormat,
    required pw.Font arabicFont,
    required pw.Font arabicFontBold,
    required PdfColor primaryColor,
    required PdfColor successColor,
    required PdfColor warningColor,
    required PdfColor errorColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ملخص الأداء
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F0FDF4'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ملخص الأداء',
                style: pw.TextStyle(font: arabicFontBold, fontSize: 11, color: successColor),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                analysis.summary,
                style: pw.TextStyle(font: arabicFont, fontSize: 10),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 15),

        // التوصيات
        if (analysis.recommendations.isNotEmpty) ...[
          pw.Text(
            'التوصيات',
            style: pw.TextStyle(font: arabicFontBold, fontSize: 11),
          ),
          pw.SizedBox(height: 8),
          ...analysis.recommendations.map((rec) {
            PdfColor priorityColor;
            switch (rec.priority) {
              case 'high':
                priorityColor = errorColor;
                break;
              case 'medium':
                priorityColor = warningColor;
                break;
              default:
                priorityColor = successColor;
            }

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F9FAFB'), 
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border(right: pw.BorderSide(color: priorityColor, width: 3)),
              ),
              child: pw.Text(
                rec.text,
                style: pw.TextStyle(font: arabicFont, fontSize: 9),
              ),
            );
          }),
          pw.SizedBox(height: 15),
        ],

        // التوقعات
        if (analysis.prediction != null) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
               color: PdfColor.fromHex('#EEF2FF'), 
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'التوقعات',
                  style: pw.TextStyle(font: arabicFontBold, fontSize: 11, color: primaryColor),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'متوقع تحقيق ${currencyFormat.format(analysis.prediction!.projectedAmount.round())} ج.م بنهاية الشهر',
                  style: pw.TextStyle(font: arabicFont, fontSize: 10),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'متبقي ${analysis.prediction!.daysRemaining} يوم - دقة التوقع: ${analysis.prediction!.confidence == 'high' ? 'عالية' : (analysis.prediction!.confidence == 'medium' ? 'متوسطة' : 'منخفضة')}',
                  style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}