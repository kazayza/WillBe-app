import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/profit_loss_model.dart';

class PdfService {
  // ================= Fonts Cache =================
  static pw.Font? _font;
  static pw.Font? _fontBold;

  static Future<void> _loadFonts() async {
    _font ??= await PdfGoogleFonts.cairoRegular();
    _fontBold ??= await PdfGoogleFonts.cairoBold();
  }

  // ================= Config =================
  static const String currency = 'ج.م';

  static final NumberFormat numberFormat =
      NumberFormat('#,##0.00', 'ar');
  static final DateFormat dateFormat =
      DateFormat('yyyy/MM/dd', 'ar');

  // ================= Main =================
  static Future<Uint8List> generateProfitLossPDF(
    ProfitLossReport report,
  ) async {
    await _loadFonts();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: _font!,
          bold: _fontBold!,
        ),
        header: (context) => _buildHeader(report),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),

          // ================= Income =================
          _sectionTitle('الإيرادات', PdfColors.green800),

          if (report.income.operational.items.isNotEmpty)
            _subSection(
              'إيرادات تشغيلية',
              report.income.operational,
            ),

          if (report.income.other.items.isNotEmpty)
            _subSection(
              'إيرادات أخرى',
              report.income.other,
            ),

          _totalBox(
            'إجمالي الإيرادات',
            report.income.grandTotal,
            PdfColors.green800,
          ),

          _divider(),

          // ================= Expenses =================
          _sectionTitle('المصروفات', PdfColors.red800),

          if (report.expenses.salaries.items.isNotEmpty)
            _subSection(
              'الرواتب والأجور',
              report.expenses.salaries,
            ),

          if (report.expenses.operational.items.isNotEmpty)
            _subSection(
              'مصروفات تشغيلية',
              report.expenses.operational,
            ),

          if (report.expenses.nonOperational.items.isNotEmpty)
            _subSection(
              'مصروفات غير تشغيلية',
              report.expenses.nonOperational,
            ),

          _totalBox(
            'إجمالي المصروفات',
            report.expenses.grandTotal,
            PdfColors.red800,
          ),

          _divider(),

          // ================= Net Profit =================
          _netProfitBox(
            report.summary.netProfit,
            report.summary.profitMargin,
          ),

          pw.SizedBox(height: 20),

          // ================= Summary =================
          _summaryGrid(report.summary),
        ],
      ),
    );

    return pdf.save();
  }

  // ================= Header =================
  static pw.Widget _buildHeader(ProfitLossReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue800,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'قائمة الأرباح والخسائر',
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 22,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'الفترة: من ${dateFormat.format(DateTime.parse(report.period.startDate))} '
            'إلى ${dateFormat.format(DateTime.parse(report.period.endDate))}',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ================= Footer =================
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Center(
      child: pw.Text(
        'صفحة ${context.pageNumber} من ${context.pagesCount}',
        style: pw.TextStyle(font: _font, fontSize: 10),
      ),
    );
  }

  // ================= Section Title =================
  static pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10, bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1.5),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: _fontBold,
          fontSize: 16,
          color: color,
        ),
      ),
    );
  }

  // ================= Sub Section =================
  static pw.Widget _subSection(
    String title,
    GroupData group,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: _fontBold,
            fontSize: 14,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 6),

        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
            width: 0.5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(2),
          },
          children: [
            ...group.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: index.isEven
                      ? PdfColors.grey100
                      : PdfColors.white,
                ),
                children: [
                  _cell(item.name),
                  _cell(_format(item.amount)),
                ],
              );
            }),

            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              children: [
                _cell('الإجمالي', bold: true),
                _cell(_format(group.total), bold: true),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 10),
      ],
    );
  }

  // ================= Total Box =================
  static pw.Widget _totalBox(
    String title,
    double amount,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      margin: const pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        color: color.shade(0.15),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                  font: _fontBold, color: color)),
          pw.Text(_format(amount),
              style: pw.TextStyle(
                  font: _fontBold, color: color)),
        ],
      ),
    );
  }

  // ================= Net Profit =================
  static pw.Widget _netProfitBox(
    double netProfit,
    double margin,
  ) {
    final isProfit = netProfit >= 0;
    final color =
        isProfit ? PdfColors.green : PdfColors.red;

    final value = isProfit
        ? _format(netProfit)
        : '(${_format(netProfit.abs())})';

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: isProfit
              ? [PdfColors.green600, PdfColors.green900]
              : [PdfColors.red600, PdfColors.red900],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            isProfit ? 'صافي الربح' : 'صافي الخسارة',
            style: pw.TextStyle(
              font: _fontBold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 24,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'هامش الربح: ${margin.toStringAsFixed(1)}%',
            style: pw.TextStyle(
              font: _fontBold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ================= Summary =================
  static pw.Widget _summaryGrid(SummaryData summary) {
    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _summaryCard('الإيرادات', summary.totalIncome, PdfColors.green),
        _summaryCard('المصروفات', summary.totalExpenses, PdfColors.red),
        _summaryCard('الربح التشغيلي', summary.operatingProfit, PdfColors.blue),
        _summaryCard('هامش الربح', summary.profitMargin, PdfColors.amber,
            suffix: '%'),
      ],
    );
  }

  static pw.Widget _summaryCard(
    String title,
    double value,
    PdfColor color, {
    String suffix = '',
  }) {
    return pw.Container(
      width: 250,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(font: _font, color: color)),
          pw.SizedBox(height: 5),
          pw.Text(
            '${_format(value)}$suffix',
            style: pw.TextStyle(
              font: _fontBold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ================= Helpers =================
  static pw.Widget _cell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: bold ? _fontBold : _font,
          fontSize: 11,
        ),
      ),
    );
  }

  static pw.Widget _divider() => pw.Column(children: [
        pw.SizedBox(height: 20),
        pw.Divider(thickness: 2),
        pw.SizedBox(height: 20),
      ]);

  static String _format(double value) {
    return '${numberFormat.format(value)} $currency';
  }

  // ================= Share =================
  static Future<void> sharePDF(ProfitLossReport report) async {
    final pdf = await generateProfitLossPDF(report);
    await Printing.sharePdf(
      bytes: pdf,
      filename:
          'Profit_Loss_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }

  static Future<void> printPDF(ProfitLossReport report) async {
    final pdf = await generateProfitLossPDF(report);
    await Printing.layoutPdf(
      name: 'Profit Loss Report',
      onLayout: (format) => pdf,
    );
  }
}