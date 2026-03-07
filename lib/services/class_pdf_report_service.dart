import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class ClassPdfReportService {
  
  /// تحميل الخط العربي
  static Future<pw.Font> _loadArabicFont() async {
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  /// تحميل الخط العربي Bold
  static Future<pw.Font> _loadArabicBoldFont() async {
    final fontData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
    return pw.Font.ttf(fontData);
  }

  /// تحميل اللوجو
  static Future<Uint8List> _loadLogo() async {
    final logoData = await rootBundle.load('assets/images/logo.png');
    return logoData.buffer.asUint8List();
  }

  /// تقرير قائمة أطفال الفصل (الدالة الرئيسية)
  static Future<Uint8List> generateChildrenListReport({
    required String className,
    required int capacity,
    required List<dynamic> children,
    required Map<String, dynamic>? statistics,
  }) async {
    // تحميل الخطوط واللوجو
    final arabicFont = await _loadArabicFont();
    final arabicBoldFont = await _loadArabicBoldFont();
    final logoBytes = await _loadLogo();
    final logoImage = pw.MemoryImage(logoBytes);

    final pdf = pw.Document();
    
    // تنسيق التاريخ
    String formatDate(dynamic date) {
      if (date == null) return '-';
      try {
        final DateTime dateTime = date is String ? DateTime.parse(date) : date;
        return DateFormat('yyyy/MM/dd').format(dateTime);
      } catch (e) {
        return date.toString();
      }
    }

    // التاريخ الحالي
    final now = DateTime.now();
    final currentDate = DateFormat('yyyy/MM/dd - hh:mm a').format(now);

    // الثيم
    final theme = pw.ThemeData.withFont(
      base: arabicFont,
      bold: arabicBoldFont,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: theme,
        margin: const pw.EdgeInsets.all(40),
        
        // الهيدر
        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // اللوجو
                pw.Image(logoImage, width: 60, height: 60),
                
                // العنوان
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'قائمة طلاب الفصل',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      className,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                // التاريخ
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'تاريخ الطباعة',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      currentDate,
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          );
        },

        // الفوتر
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'صفحة ${context.pageNumber} من ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
                pw.Text(
                  'تم إنشاء التقرير بواسطة النظام',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },

        // المحتوى
        build: (context) {
          return [
            // الإحصائيات
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              margin: const pw.EdgeInsets.only(bottom: 20),
              decoration: pw.BoxDecoration(
                color: PdfColors.indigo50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.indigo100),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('عدد الطلاب', '${children.length}', arabicBoldFont, arabicFont),
                  if (capacity > 0)
                    _buildStatItem('السعة', '$capacity', arabicBoldFont, arabicFont),
                  if (statistics != null) ...[
                    _buildStatItem('نسبة الإشغال', '${statistics['occupancyRate'] ?? 0}%', arabicBoldFont, arabicFont),
                    _buildStatItem('متوسط العمر', '${statistics['averageAge'] ?? 0} سنة', arabicBoldFont, arabicFont),
                  ],
                ],
              ),
            ),

            // جدول الطلاب
            if (children.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(40),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'لا يوجد طلاب في هذا الفصل',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(3),
                  4: const pw.FlexColumnWidth(0.7),
                },
                children: [
                  // رأس الجدول (من اليمين لليسار)
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                    children: [
                      _buildTableHeader('ملاحظات', arabicBoldFont),
                      _buildTableHeader('تاريخ الالتحاق', arabicBoldFont),
                      _buildTableHeader('العمر', arabicBoldFont),
                      _buildTableHeader('اسم الطالب', arabicBoldFont),
                      _buildTableHeader('م', arabicBoldFont),
                    ],
                  ),
                  // صفوف البيانات
                  ...children.asMap().entries.map((entry) {
                    final index = entry.key;
                    final child = entry.value;
                    final isEven = index % 2 == 0;
                    
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.white : PdfColors.grey50,
                      ),
                      children: [
                        _buildTableCell(child['AssignNotes'] ?? '-', arabicFont, align: pw.TextAlign.right, fontSize: 9),
                        _buildTableCell(formatDate(child['JoinDate']), arabicFont),
                        _buildTableCell('${child['Age'] ?? '-'}', arabicFont),
                        _buildTableCell(child['FullNameArabic'] ?? '-', arabicFont, align: pw.TextAlign.right),
                        _buildTableCell('${index + 1}', arabicFont),
                      ],
                    );
                  }).toList(),
                ],
              ),
              
            pw.SizedBox(height: 20),
            
            // ملخص
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'إجمالي عدد الطلاب: ${children.length} طالب',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// 🆕 Wrapper للتوافق مع الكود القديم
  static Future<Uint8List> generateChildrenList({
    required String className,
    required List<dynamic> children,
  }) async {
    return generateChildrenListReport(
      className: className,
      capacity: 0,
      children: children,
      statistics: null,
    );
  }

  /// عنصر إحصائية
  static pw.Widget _buildStatItem(String label, String value, pw.Font boldFont, pw.Font regularFont) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(
            font: regularFont,
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
      ],
    );
  }

  /// رأس الجدول
  static pw.Widget _buildTableHeader(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// خلية الجدول
  static pw.Widget _buildTableCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.center, double fontSize = 10}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
        ),
        textAlign: align,
      ),
    );
  }
  
  /// كشف حضور فارغ بالأيام
  static Future<Uint8List> generateAttendanceSheet({
    required String className,
    required List<dynamic> children,
    required int daysCount,
  }) async {
    final arabicFont = await _loadArabicFont();
    final arabicBoldFont = await _loadArabicBoldFont();
    final logoBytes = await _loadLogo();
    final logoImage = pw.MemoryImage(logoBytes);

    final pdf = pw.Document();

    final now = DateTime.now();
    final currentDate = DateFormat('yyyy/MM/dd').format(now);
    final monthName = DateFormat('MMMM yyyy', 'ar').format(now);

    final theme = pw.ThemeData.withFont(
      base: arabicFont,
      bold: arabicBoldFont,
    );

    // حساب عدد الصفوف في كل صفحة
    final int rowsPerPage = 28;
    final int totalPages = (children.length / rowsPerPage).ceil();

    for (int pageIndex = 0; pageIndex < (totalPages == 0 ? 1 : totalPages); pageIndex++) {
      final int startIndex = pageIndex * rowsPerPage;
      final int endIndex = (startIndex + rowsPerPage > children.length) 
          ? children.length 
          : startIndex + rowsPerPage;
      final pageChildren = children.sublist(startIndex, endIndex);

      // حساب الصفوف الفارغة لملء الصفحة
      final int emptyRows = rowsPerPage - pageChildren.length;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          textDirection: pw.TextDirection.rtl,
          theme: theme,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              children: [
                // الهيدر
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Image(logoImage, width: 40, height: 40),
                      pw.Column(
                        children: [
                          pw.Text(
                            'كشف الحضور والغياب',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.indigo,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '$className - $monthName',
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('تاريخ: $currentDate', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                          pw.Text('صفحة ${pageIndex + 1} من ${totalPages == 0 ? 1 : totalPages}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                        ],
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 8),
                
                // الجدول
                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
                    columnWidths: _buildColumnWidths(daysCount),
                    children: [
                      // رأس الجدول
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.indigo),
                        children: [
                          _buildAttendanceHeader('الغياب', arabicBoldFont),
                          _buildAttendanceHeader('الحضور', arabicBoldFont),
                          for (int i = daysCount; i >= 1; i--)
                            _buildAttendanceHeader('$i', arabicBoldFont),
                          _buildAttendanceHeader('اسم الطالب', arabicBoldFont),
                          _buildAttendanceHeader('م', arabicBoldFont),
                        ],
                      ),
                      // صفوف الطلاب
                      ...pageChildren.asMap().entries.map((entry) {
                        final index = entry.key + startIndex;
                        final child = entry.value;
                        final isEven = index % 2 == 0;
                        
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: isEven ? PdfColors.white : PdfColors.grey100,
                          ),
                          children: [
                            _buildAttendanceCell('', arabicFont),
                            _buildAttendanceCell('', arabicFont),
                            for (int i = 0; i < daysCount; i++)
                              _buildAttendanceCell('', arabicFont),
                            _buildAttendanceCell(
                              child['FullNameArabic'] ?? '-', 
                              arabicFont, 
                              align: pw.TextAlign.right,
                            ),
                            _buildAttendanceCell('${index + 1}', arabicFont),
                          ],
                        );
                      }).toList(),
                      // صفوف فارغة لملء الصفحة
                      for (int i = 0; i < emptyRows; i++)
                        pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: (pageChildren.length + i) % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                          ),
                          children: [
                            _buildAttendanceCell('', arabicFont),
                            _buildAttendanceCell('', arabicFont),
                            for (int j = 0; j < daysCount; j++)
                              _buildAttendanceCell('', arabicFont),
                            _buildAttendanceCell('', arabicFont),
                            _buildAttendanceCell('', arabicFont),
                          ],
                        ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 6),
                
                // الفوتر - المفتاح
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      _buildLegendItem('ح = حاضر', arabicFont, PdfColors.green),
                      pw.SizedBox(width: 25),
                      _buildLegendItem('غ = غائب', arabicFont, PdfColors.red),
                      pw.SizedBox(width: 25),
                      _buildLegendItem('م = متأخر', arabicFont, PdfColors.orange),
                      pw.SizedBox(width: 25),
                      _buildLegendItem('ع = عذر', arabicFont, PdfColors.blue),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// بناء عرض الأعمدة
  static Map<int, pw.TableColumnWidth> _buildColumnWidths(int daysCount) {
    final Map<int, pw.TableColumnWidth> widths = {};
    
    // الغياب (أقصى الشمال)
    widths[0] = const pw.FixedColumnWidth(35);
    // الحضور
    widths[1] = const pw.FixedColumnWidth(35);
    // الأيام
    for (int i = 2; i < daysCount + 2; i++) {
      widths[i] = const pw.FixedColumnWidth(22);
    }
    // اسم الطالب
    widths[daysCount + 2] = const pw.FlexColumnWidth(3);
    // م (أقصى اليمين)
    widths[daysCount + 3] = const pw.FixedColumnWidth(25);
    
    return widths;
  }

  /// رأس جدول الحضور
  static pw.Widget _buildAttendanceHeader(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 1),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// خلية جدول الحضور
  static pw.Widget _buildAttendanceCell(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 1),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 8,
        ),
        textAlign: align,
        maxLines: 1,
      ),
    );
  }

  /// عنصر المفتاح
  static pw.Widget _buildLegendItem(String text, pw.Font font, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 10,
          height: 10,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          text,
          style: pw.TextStyle(font: font, fontSize: 8),
        ),
      ],
    );
  }
}