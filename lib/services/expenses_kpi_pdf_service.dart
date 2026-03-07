import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import '../models/expenses_kpi_model.dart';

class ExpensesKPIPdfService {
  static late pw.Font _arabicFont;
  static late pw.Font _arabicBoldFont;

  // ════════════════════════════════════════════════════════════
  // 🔤 تحميل الخطوط العربية
  // ════════════════════════════════════════════════════════════
  static Future<void> _loadFonts() async {
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    _arabicFont = pw.Font.ttf(fontData);
    _arabicBoldFont = pw.Font.ttf(boldFontData);
  }

  // ════════════════════════════════════════════════════════════
  // 📄 إنشاء التقرير الكامل
  // ════════════════════════════════════════════════════════════
  static Future<Uint8List> generateReport(ExpensesKPIModel data) async {
    await _loadFonts();

    final pdf = pw.Document();

    final baseStyle = pw.TextStyle(font: _arabicFont, fontSize: 10);
    final boldStyle = pw.TextStyle(font: _arabicBoldFont, fontSize: 10);
    final titleStyle = pw.TextStyle(font: _arabicBoldFont, fontSize: 14);
    final headerStyle = pw.TextStyle(
      font: _arabicBoldFont,
      fontSize: 12,
      color: PdfColors.white,
    );

    final primaryColor = PdfColor.fromHex('#2C3E50');
    final blueColor = PdfColor.fromHex('#3498DB');
    final greenColor = PdfColor.fromHex('#27AE60');
    final redColor = PdfColor.fromHex('#E74C3C');
    final orangeColor = PdfColor.fromHex('#E67E22');
    final purpleColor = PdfColor.fromHex('#8E44AD');
    final grayColor = PdfColor.fromHex('#7F8C8D');
    final lightGray = PdfColor.fromHex('#ECF0F1');
    final bgColor = PdfColor.fromHex('#F5F6FA');

    // ════════════════════════════════════════
    // صفحة 1: الغلاف + الملخص
    // ════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // الغلاف
              _buildCover(data, primaryColor, blueColor, titleStyle, baseStyle, boldStyle),

              pw.SizedBox(height: 20),

              // الملخص العام
              _buildSummarySection(data, primaryColor, blueColor, greenColor, redColor, baseStyle, boldStyle, titleStyle, grayColor, lightGray),

              pw.SizedBox(height: 16),

              // التوقعات
              _buildForecastSection(data, purpleColor, blueColor, greenColor, redColor, baseStyle, boldStyle, titleStyle, grayColor, lightGray),

              pw.SizedBox(height: 16),

              // المؤشرات المتقدمة
              _buildAdvancedSection(data, blueColor, greenColor, redColor, orangeColor, purpleColor, baseStyle, boldStyle, titleStyle, grayColor, lightGray),
            ],
          );
        },
      ),
    );

    // ════════════════════════════════════════
    // صفحة 2: أعلى البنود + المجموعات
    // ════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader('تحليل البنود والمجموعات', primaryColor, headerStyle),

              pw.SizedBox(height: 16),

              // أعلى 5 بنود
              if (data.top5Expenses.isNotEmpty)
                _buildTop5Section(data, primaryColor, blueColor, baseStyle, boldStyle, titleStyle, grayColor, lightGray),

              pw.SizedBox(height: 16),

              // أعلى 5 ارتفاعاً
              if (data.topIncreases.isNotEmpty)
                _buildTopChangesSection(
                  'أعلى 5 بنود ارتفاعاً',
                  data.topIncreases.map((e) => _ChangeItem(e.name, e.current, e.previous, e.change, true)).toList(),
                  redColor, baseStyle, boldStyle, titleStyle, grayColor, lightGray,
                ),

              pw.SizedBox(height: 16),

              // أعلى 5 توفيراً
              if (data.topSavings.isNotEmpty)
                _buildTopChangesSection(
                  'أعلى 5 بنود توفيراً',
                  data.topSavings.map((e) => _ChangeItem(e.name, e.current, e.previous, e.savingPercent, false)).toList(),
                  greenColor, baseStyle, boldStyle, titleStyle, grayColor, lightGray,
                ),
            ],
          );
        },
      ),
    );

    // ════════════════════════════════════════
    // صفحة 3: المجموعات + الفروع
    // ════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader('تحليل المجموعات والفروع', primaryColor, headerStyle),

              pw.SizedBox(height: 16),

              // جدول المجموعات
              if (data.groupsData.isNotEmpty)
                _buildGroupsTable(data, primaryColor, blueColor, greenColor, redColor, baseStyle, boldStyle, titleStyle, grayColor, lightGray),

              pw.SizedBox(height: 20),

              // جدول الفروع
              if (data.branchesData.isNotEmpty)
                _buildBranchesTable(data, primaryColor, blueColor, greenColor, redColor, baseStyle, boldStyle, titleStyle, grayColor, lightGray),
            ],
          );
        },
      ),
    );

    // ════════════════════════════════════════
    // صفحة 4: التنبيهات + التحليل المالي
    // ════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader('التنبيهات والتحليل المالي', primaryColor, headerStyle),

              pw.SizedBox(height: 16),

              // التنبيهات الذكية
              if (data.insights.isNotEmpty)
                _buildInsightsSection(data, redColor, orangeColor, greenColor, blueColor, baseStyle, boldStyle, titleStyle, grayColor, lightGray),

              pw.SizedBox(height: 16),

              // الملخص التنفيذي
              _buildFinancialSummary(data, primaryColor, blueColor, baseStyle, boldStyle, titleStyle, grayColor, lightGray),
            ],
          );
        },
      ),
    );

    // ════════════════════════════════════════
    // صفحة 5: التحليل المالي الكامل
    // ════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader('التحليل المالي التفصيلي', primaryColor, headerStyle),

              pw.SizedBox(height: 16),

              // تحليل الانحرافات
              if (data.financialAnalysis.deviationAnalysis.isNotEmpty)
                _buildAnalysisSection('تحليل الانحرافات', data.financialAnalysis.deviationAnalysis,
                    blueColor, baseStyle, boldStyle, titleStyle, lightGray),

              pw.SizedBox(height: 12),

              // تحليل المخاطر
              if (data.financialAnalysis.riskAnalysis.isNotEmpty)
                _buildAnalysisSection('تحليل المخاطر والتركز', data.financialAnalysis.riskAnalysis,
                    redColor, baseStyle, boldStyle, titleStyle, lightGray),

              pw.SizedBox(height: 12),

              // النقاط الإيجابية
              if (data.financialAnalysis.positivePoints.isNotEmpty)
                _buildAnalysisSection('النقاط الإيجابية', data.financialAnalysis.positivePoints,
                    greenColor, baseStyle, boldStyle, titleStyle, lightGray),

              pw.SizedBox(height: 12),

              // التوقعات
              if (data.financialAnalysis.forecast.isNotEmpty)
                _buildTextBlock('التوقعات', data.financialAnalysis.forecast,
                    purpleColor, baseStyle, boldStyle, titleStyle, lightGray),

              pw.SizedBox(height: 12),

              // المقارنة السنوية
              if (data.financialAnalysis.yearComparison.isNotEmpty)
                _buildTextBlock('المقارنة السنوية', data.financialAnalysis.yearComparison,
                    orangeColor, baseStyle, boldStyle, titleStyle, lightGray),
            ],
          );
        },
      ),
    );

    // ════════════════════════════════════════
    // صفحة 6: التوصيات
    // ════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader('التوصيات', primaryColor, headerStyle),

              pw.SizedBox(height: 16),

              // التوصيات
              _buildRecommendationsSection(data, greenColor, primaryColor, baseStyle, boldStyle, titleStyle, grayColor, lightGray),

              pw.Spacer(),

              // التذييل
              _buildFooter(primaryColor, grayColor, baseStyle, boldStyle),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ════════════════════════════════════════════════════════════
  // 🏢 الغلاف
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildCover(
    ExpensesKPIModel data,
    PdfColor primaryColor,
    PdfColor blueColor,
    pw.TextStyle titleStyle,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
  ) {
    final dates = data.dates;
    final now = DateTime.now();

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'تقرير مؤشرات أداء المصروفات',
            style: pw.TextStyle(font: _arabicBoldFont, fontSize: 20, color: PdfColors.white),
            textDirection: pw.TextDirection.rtl,
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: pw.BoxDecoration(
              color: blueColor,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              'الفترة: ${_formatDate(dates.current.start)} - ${_formatDate(dates.current.end)}',
              style: pw.TextStyle(font: _arabicFont, fontSize: 10, color: PdfColors.white),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'تاريخ التقرير: ${now.day}/${now.month}/${now.year}',
            style: pw.TextStyle(font: _arabicFont, fontSize: 9, color: PdfColor.fromHex('#BDC3C7')),
            textDirection: pw.TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📊 الملخص العام
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildSummarySection(
    ExpensesKPIModel data,
    PdfColor primaryColor,
    PdfColor blueColor,
    PdfColor greenColor,
    PdfColor redColor,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
    pw.TextStyle titleStyle,
    PdfColor grayColor,
    PdfColor lightGray,
  ) {
    final summary = data.summary;
    final prevColor = summary.vsPrevious.isUp ? redColor : greenColor;
    final yearColor = summary.vsLastYear.isUp ? redColor : greenColor;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: lightGray),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('الملخص العام', blueColor, titleStyle),
          pw.SizedBox(height: 12),

          // الإجمالي
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Text('إجمالي المصروفات',
                    style: pw.TextStyle(font: _arabicFont, fontSize: 10, color: PdfColor.fromHex('#BDC3C7')),
                    textDirection: pw.TextDirection.rtl),
                pw.SizedBox(height: 4),
                pw.Text('${_formatNumber(summary.totalCurrent)} ج.م',
                    style: pw.TextStyle(font: _arabicBoldFont, fontSize: 22, color: PdfColors.white),
                    textDirection: pw.TextDirection.rtl),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // المقارنات
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildCompareBox('vs الفترة السابقة', summary.vsPrevious.total,
                    summary.vsPrevious.percent, summary.vsPrevious.isUp, prevColor, baseStyle, boldStyle, grayColor, lightGray),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildCompareBox('vs العام السابق', summary.vsLastYear.total,
                    summary.vsLastYear.percent, summary.vsLastYear.isUp, yearColor, baseStyle, boldStyle, grayColor, lightGray),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // فترات المقارنة
          _buildDatesInfo(data.dates, blueColor, grayColor, baseStyle, boldStyle, lightGray),
        ],
      ),
    );
  }

  static pw.Widget _buildCompareBox(String title, double total, double percent, bool isUp,
      PdfColor color, pw.TextStyle baseStyle, pw.TextStyle boldStyle, PdfColor grayColor, PdfColor lightGray) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: lightGray),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(title, style: pw.TextStyle(font: _arabicFont, fontSize: 9, color: grayColor),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 4),
          pw.Text('${_formatNumber(total)} ج.م',
              style: pw.TextStyle(font: _arabicBoldFont, fontSize: 13),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: pw.BoxDecoration(color: color.shade(0.9), borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Text('${isUp ? "+" : "-"}${percent.abs()}%',
                style: pw.TextStyle(font: _arabicBoldFont, fontSize: 11, color: color),
                textDirection: pw.TextDirection.rtl),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDatesInfo(DateRanges dates, PdfColor blueColor, PdfColor grayColor,
      pw.TextStyle baseStyle, pw.TextStyle boldStyle, PdfColor lightGray) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: lightGray, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        children: [
          _buildDateRow('الفترة الحالية', dates.current.start, dates.current.end, dates.current.days, blueColor, baseStyle, boldStyle),
          pw.SizedBox(height: 4),
          _buildDateRow('الفترة السابقة', dates.previous.start, dates.previous.end, dates.previous.days, PdfColor.fromHex('#E67E22'), baseStyle, boldStyle),
          pw.SizedBox(height: 4),
          _buildDateRow('العام السابق', dates.lastYear.start, dates.lastYear.end, dates.lastYear.days, PdfColor.fromHex('#8E44AD'), baseStyle, boldStyle),
        ],
      ),
    );
  }

  static pw.Widget _buildDateRow(String label, DateTime? start, DateTime? end, int days,
      PdfColor color, pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    return pw.Row(
      children: [
        pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text('$label: ${_formatDate(start)} - ${_formatDate(end)} ($days يوم)',
              style: pw.TextStyle(font: _arabicFont, fontSize: 9),
              textDirection: pw.TextDirection.rtl),
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════
  // 🔮 التوقعات
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildForecastSection(ExpensesKPIModel data, PdfColor purpleColor, PdfColor blueColor,
      PdfColor greenColor, PdfColor redColor, pw.TextStyle baseStyle, pw.TextStyle boldStyle,
      pw.TextStyle titleStyle, PdfColor grayColor, PdfColor lightGray) {
    final forecast = data.forecast;
    final isOver = forecast.projectedTotal > data.summary.vsPrevious.total;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: lightGray), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('توقعات نهاية الشهر', purpleColor, titleStyle),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(child: _buildStatBox('حتى الآن', '${_formatNumber(forecast.totalSoFar)} ج.م', blueColor, lightGray, boldStyle, baseStyle)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildStatBox('المتوسط اليومي', '${_formatNumber(forecast.dailyAverage)} ج.م', purpleColor, lightGray, boldStyle, baseStyle)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildStatBox('المتوقع', '${_formatNumber(forecast.projectedTotal)} ج.م', isOver ? redColor : greenColor, lightGray, boldStyle, baseStyle)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('${forecast.daysElapsed} يوم مضى | ${forecast.daysRemaining} يوم متبقي من ${forecast.daysInMonth} يوم',
              style: pw.TextStyle(font: _arabicFont, fontSize: 9, color: grayColor),
              textDirection: pw.TextDirection.rtl, textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📈 المؤشرات المتقدمة
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildAdvancedSection(ExpensesKPIModel data, PdfColor blueColor, PdfColor greenColor,
      PdfColor redColor, PdfColor orangeColor, PdfColor purpleColor, pw.TextStyle baseStyle,
      pw.TextStyle boldStyle, pw.TextStyle titleStyle, PdfColor grayColor, PdfColor lightGray) {
    final adv = data.advanced;

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: lightGray), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('مؤشرات متقدمة', blueColor, titleStyle),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(child: _buildStatBox('عدد المعاملات', '${adv.totalTransactions}', blueColor, lightGray, boldStyle, baseStyle)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildStatBox('أيام نشطة', '${adv.activeDays}', greenColor, lightGray, boldStyle, baseStyle)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildStatBox('متوسط المعاملة', '${_formatNumber(adv.avgPerTransaction)}', purpleColor, lightGray, boldStyle, baseStyle)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(child: _buildStatBox('أعلى مصروف', '${_formatNumber(adv.maxSingleExpense)}', redColor, lightGray, boldStyle, baseStyle)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildStatBox('أقل مصروف', '${_formatNumber(adv.minSingleExpense)}', greenColor, lightGray, boldStyle, baseStyle)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: _buildStatBox('الانحراف', '${_formatNumber(adv.stdDeviation)}', orangeColor, lightGray, boldStyle, baseStyle)),
            ],
          ),
          if (adv.mostFrequentKind != null) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(color: lightGray, borderRadius: pw.BorderRadius.circular(6)),
              child: pw.Text(
                'أكثر بند تكراراً: ${adv.mostFrequentKind!.name} (${adv.mostFrequentKind!.count} معاملة - ${_formatNumber(adv.mostFrequentKind!.total)} ج.م)',
                style: pw.TextStyle(font: _arabicFont, fontSize: 9),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 🏆 أعلى 5 بنود
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildTop5Section(ExpensesKPIModel data, PdfColor primaryColor, PdfColor blueColor,
      pw.TextStyle baseStyle, pw.TextStyle boldStyle, pw.TextStyle titleStyle, PdfColor grayColor, PdfColor lightGray) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: lightGray), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('أعلى 5 بنود مصروفات', PdfColor.fromHex('#F39C12'), titleStyle),
          pw.SizedBox(height: 10),
          _buildTable(
            headers: ['#', 'البند', 'المجموعة', 'المبلغ', 'المعاملات', 'النسبة'],
            rows: data.top5Expenses.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return ['${i + 1}', e.name, e.group, '${_formatNumber(e.amount)}', '${e.transactions}', '${e.percent}%'];
            }).toList(),
            primaryColor: primaryColor,
            baseStyle: baseStyle,
            boldStyle: boldStyle,
            lightGray: lightGray,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📈📉 أعلى ارتفاعاً / توفيراً
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildTopChangesSection(String title, List<_ChangeItem> items, PdfColor color,
      pw.TextStyle baseStyle, pw.TextStyle boldStyle, pw.TextStyle titleStyle, PdfColor grayColor, PdfColor lightGray) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: lightGray), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(title, color, titleStyle),
          pw.SizedBox(height: 10),
          _buildTable(
            headers: ['#', 'البند', 'الحالي', 'السابق', 'التغير'],
            rows: items.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return ['${i + 1}', e.name, '${_formatNumber(e.current)}', '${_formatNumber(e.previous)}',
                '${e.isIncrease ? "+" : "-"}${e.change.abs()}%'];
            }).toList(),
            primaryColor: color,
            baseStyle: baseStyle,
            boldStyle: boldStyle,
            lightGray: lightGray,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📊 جدول المجموعات
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildGroupsTable(ExpensesKPIModel data, PdfColor primaryColor, PdfColor blueColor,
      PdfColor greenColor, PdfColor redColor, pw.TextStyle baseStyle, pw.TextStyle boldStyle,
      pw.TextStyle titleStyle, PdfColor grayColor, PdfColor lightGray) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: lightGray), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('تحليل المجموعات', blueColor, titleStyle),
          pw.SizedBox(height: 10),
          _buildTable(
            headers: ['المجموعة', 'الحالي', 'السابق', 'التغير', 'العام السابق', 'التغير السنوي'],
            rows: data.groupsData.map((g) {
              return [g.group, '${_formatNumber(g.current)}', '${_formatNumber(g.vsPrevious.amount)}',
                '${g.vsPrevious.change > 0 ? "+" : ""}${g.vsPrevious.change}%',
                '${_formatNumber(g.vsLastYear.amount)}',
                '${g.vsLastYear.change > 0 ? "+" : ""}${g.vsLastYear.change}%'];
            }).toList(),
            primaryColor: primaryColor,
            baseStyle: baseStyle,
            boldStyle: boldStyle,
            lightGray: lightGray,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 🏢 جدول الفروع
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildBranchesTable(ExpensesKPIModel data, PdfColor primaryColor, PdfColor blueColor,
      PdfColor greenColor, PdfColor redColor, pw.TextStyle baseStyle, pw.TextStyle boldStyle,
      pw.TextStyle titleStyle, PdfColor grayColor, PdfColor lightGray) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: lightGray), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('تحليل الفروع', PdfColor.fromHex('#16A085'), titleStyle),
          pw.SizedBox(height: 10),
          _buildTable(
            headers: ['الفرع', 'المبلغ', 'النسبة', 'التغير', 'التغير السنوي'],
            rows: data.branchesData.map((b) {
              return [b.name, '${_formatNumber(b.current)}', '${b.percentOfTotal}%',
                '${b.vsPrevious.change > 0 ? "+" : ""}${b.vsPrevious.change}%',
                '${b.vsLastYear.change > 0 ? "+" : ""}${b.vsLastYear.change}%'];
            }).toList(),
            primaryColor: primaryColor,
            baseStyle: baseStyle,
            boldStyle: boldStyle,
            lightGray: lightGray,
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 🚨 التنبيهات
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildInsightsSection(ExpensesKPIModel data, PdfColor redColor, PdfColor orangeColor,
      PdfColor greenColor, PdfColor blueColor, pw.TextStyle baseStyle, pw.TextStyle boldStyle,
      pw.TextStyle titleStyle, PdfColor grayColor, PdfColor lightGray) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: lightGray), borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('تنبيهات ذكية', orangeColor, titleStyle),
          pw.SizedBox(height: 10),
          ...data.insights.map((insight) {
            PdfColor color;
            switch (insight.type) {
              case 'danger': color = redColor; break;
              case 'warning': color = orangeColor; break;
              case 'success': color = greenColor; break;
              default: color = blueColor;
            }
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: color.shade(0.95),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: color.shade(0.8)),
              ),
              child: pw.Row(
                children: [
                  pw.Text(insight.icon, style: const pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(insight.title,
                            style: pw.TextStyle(font: _arabicBoldFont, fontSize: 10, color: color),
                            textDirection: pw.TextDirection.rtl),
                        pw.Text(insight.message,
                            style: pw.TextStyle(font: _arabicFont, fontSize: 9, color: grayColor),
                            textDirection: pw.TextDirection.rtl),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📋 الملخص التنفيذي
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildFinancialSummary(ExpensesKPIModel data, PdfColor primaryColor, PdfColor blueColor,
      pw.TextStyle baseStyle, pw.TextStyle boldStyle, pw.TextStyle titleStyle, PdfColor grayColor, PdfColor lightGray) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primaryColor.shade(0.8)),
        borderRadius: pw.BorderRadius.circular(10),
        color: primaryColor.shade(0.97),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('الملخص التنفيذي', primaryColor, titleStyle),
          pw.SizedBox(height: 10),
          pw.Text(data.financialAnalysis.executiveSummary,
              style: pw.TextStyle(font: _arabicFont, fontSize: 10, lineSpacing: 6),
              textDirection: pw.TextDirection.rtl),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📝 قسم تحليلي بنقاط
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildAnalysisSection(String title, List<String> items, PdfColor color,
      pw.TextStyle baseStyle, pw.TextStyle boldStyle, pw.TextStyle titleStyle, PdfColor lightGray) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color.shade(0.85)),
        borderRadius: pw.BorderRadius.circular(8),
        color: color.shade(0.97),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(title, color, titleStyle),
          pw.SizedBox(height: 8),
          ...items.map((item) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(width: 5, height: 5, margin: const pw.EdgeInsets.only(top: 4),
                    decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
                pw.SizedBox(width: 6),
                pw.Expanded(child: pw.Text(item, style: pw.TextStyle(font: _arabicFont, fontSize: 9, lineSpacing: 5),
                    textDirection: pw.TextDirection.rtl)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 📝 بلوك نص
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildTextBlock(String title, String text, PdfColor color,
      pw.TextStyle baseStyle, pw.TextStyle boldStyle, pw.TextStyle titleStyle, PdfColor lightGray) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color.shade(0.85)),
        borderRadius: pw.BorderRadius.circular(8),
        color: color.shade(0.97),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(title, color, titleStyle),
          pw.SizedBox(height: 8),
          pw.Text(text, style: pw.TextStyle(font: _arabicFont, fontSize: 9, lineSpacing: 5),
              textDirection: pw.TextDirection.rtl),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 💡 التوصيات
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildRecommendationsSection(ExpensesKPIModel data, PdfColor greenColor, PdfColor primaryColor,
      pw.TextStyle baseStyle, pw.TextStyle boldStyle, pw.TextStyle titleStyle, PdfColor grayColor, PdfColor lightGray) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: greenColor.shade(0.8)),
        borderRadius: pw.BorderRadius.circular(10),
        color: greenColor.shade(0.97),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('التوصيات', greenColor, titleStyle),
          pw.SizedBox(height: 10),
          ...data.financialAnalysis.recommendations.asMap().entries.map((entry) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: lightGray),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 18, height: 18,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(color: greenColor.shade(0.9), borderRadius: pw.BorderRadius.circular(4)),
                    child: pw.Text('${entry.key + 1}',
                        style: pw.TextStyle(font: _arabicBoldFont, fontSize: 9, color: greenColor)),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(child: pw.Text(entry.value,
                      style: pw.TextStyle(font: _arabicFont, fontSize: 9, lineSpacing: 5),
                      textDirection: pw.TextDirection.rtl)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // 🔧 عناصر مساعدة
  // ════════════════════════════════════════════════════════════
  static pw.Widget _buildPageHeader(String title, PdfColor color, pw.TextStyle style) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Text(title, style: style, textDirection: pw.TextDirection.rtl),
    );
  }

  static pw.Widget _buildSectionTitle(String title, PdfColor color, pw.TextStyle titleStyle) {
    return pw.Text(title,
        style: pw.TextStyle(font: _arabicBoldFont, fontSize: 13, color: color),
        textDirection: pw.TextDirection.rtl);
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color, PdfColor lightGray,
      pw.TextStyle boldStyle, pw.TextStyle baseStyle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(color: color.shade(0.93), borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(
        children: [
          pw.Text(value, style: pw.TextStyle(font: _arabicBoldFont, fontSize: 11, color: color),
              textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 2),
          pw.Text(label, style: pw.TextStyle(font: _arabicFont, fontSize: 8, color: color),
              textDirection: pw.TextDirection.rtl),
        ],
      ),
    );
  }

  static pw.Widget _buildTable({
    required List<String> headers,
    required List<List<String>> rows,
    required PdfColor primaryColor,
    required pw.TextStyle baseStyle,
    required pw.TextStyle boldStyle,
    required PdfColor lightGray,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: lightGray, width: 0.5),
      columnWidths: {for (var i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth()},
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryColor),
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Text(h,
                style: pw.TextStyle(font: _arabicBoldFont, fontSize: 8, color: PdfColors.white),
                textDirection: pw.TextDirection.rtl, textAlign: pw.TextAlign.center),
          )).toList(),
        ),
        ...rows.asMap().entries.map((entry) => pw.TableRow(
          decoration: pw.BoxDecoration(color: entry.key.isEven ? PdfColors.white : lightGray),
          children: entry.value.map((cell) => pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(cell,
                style: pw.TextStyle(font: _arabicFont, fontSize: 8),
                textDirection: pw.TextDirection.rtl, textAlign: pw.TextAlign.center),
          )).toList(),
        )),
      ],
    );
  }

  static pw.Widget _buildFooter(PdfColor primaryColor, PdfColor grayColor,
      pw.TextStyle baseStyle, pw.TextStyle boldStyle) {
    final now = DateTime.now();
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: primaryColor, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('WillBee System',
              style: pw.TextStyle(font: _arabicBoldFont, fontSize: 9, color: primaryColor)),
          pw.Text('تم إنشاء التقرير: ${now.day}/${now.month}/${now.year} - ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
              style: pw.TextStyle(font: _arabicFont, fontSize: 8, color: grayColor),
              textDirection: pw.TextDirection.rtl),
        ],
      ),
    );
  }

  static String _formatNumber(double number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toStringAsFixed(0);
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ChangeItem {
  final String name;
  final double current;
  final double previous;
  final double change;
  final bool isIncrease;

  _ChangeItem(this.name, this.current, this.previous, this.change, this.isIncrease);
}