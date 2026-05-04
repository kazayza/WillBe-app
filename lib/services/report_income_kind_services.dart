import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/income_models.dart';

class ReportIncomeKindService {
  static const String baseUrl = 'https://willbee-backend.vercel.app/api';

  final http.Client _client = http.Client();

  // =============================================
  // 1. جلب الفروع
  // =============================================
  Future<List<BranchModel>> getBranches() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/general/branches'),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) => BranchModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ خطأ في جلب الفروع: $e');
      return [];
    }
  }

  // =============================================
  // 2. جلب مجموعات الإيراد
  // =============================================
  Future<List<String>> getIncomeGroups() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/report-income-kind/income-groups'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<String>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('❌ خطأ في جلب المجموعات: $e');
      return [];
    }
  }

  // =============================================
  // 3. جلب أنواع الإيراد حسب المجموعة
  // =============================================
  Future<List<IncomeKindModel>> getIncomeKindsByGroup(String? group) async {
    try {
      String url = '$baseUrl/report-income-kind/income-kinds-by-group';
      if (group != null && group.isNotEmpty) {
        url += '?group=$group';
      }

      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((item) => IncomeKindModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ خطأ في جلب أنواع الإيراد: $e');
      return [];
    }
  }

  // =============================================
  // 4. جلب تقرير الإيرادات
  // =============================================
  Future<Map<String, dynamic>> getIncomesReport({
    DateTime? fromDate,
    DateTime? toDate,
    int? branchId,
    String? incomeGroup,
    int? incomeKindId,
  }) async {
    try {
      final Map<String, String> params = {};

      if (fromDate != null) {
        params['fromDate'] = fromDate.toIso8601String().split('T').first;
      }
      if (toDate != null) {
        params['toDate'] = toDate.toIso8601String().split('T').first;
      }
      if (branchId != null && branchId > 0) {
        params['branchId'] = branchId.toString();
      }
      if (incomeGroup != null && incomeGroup.isNotEmpty) {
        params['incomeGroup'] = incomeGroup;
      }
      if (incomeKindId != null && incomeKindId > 0) {
        params['incomeKindId'] = incomeKindId.toString();
      }

      Uri uri = Uri.parse('$baseUrl/report-income-kind/incomes-report');
      if (params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'data': [], 'summary': {}};
    } catch (e) {
      print('❌ خطأ في جلب التقرير: $e');
      return {'success': false, 'data': [], 'summary': {}};
    }
  }

  // =============================================
  // 5. جلب قائمة الأطفال
  // =============================================
  Future<List<ChildModel>> getChildrenList({String? search}) async {
    try {
      String url = '$baseUrl/report-income-kind/children-list';
      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List list = data['data'];
          return list.map((item) => ChildModel.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ خطأ في جلب الأطفال: $e');
      return [];
    }
  }

  // =============================================
  // 6. جلب إيرادات طفل محدد
  // =============================================
  Future<Map<String, dynamic>> getChildIncomes({
    required int childId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final Map<String, String> params = {
        'childId': childId.toString(),
      };

      if (fromDate != null) {
        params['fromDate'] = fromDate.toIso8601String().split('T').first;
      }
      if (toDate != null) {
        params['toDate'] = toDate.toIso8601String().split('T').first;
      }

      Uri uri = Uri.parse('$baseUrl/report-income-kind/child-incomes');
      if (params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }

      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'data': [], 'summary': {}};
    } catch (e) {
      print('❌ خطأ في جلب إيرادات الطفل: $e');
      return {'success': false, 'data': [], 'summary': {}};
    }
  }

  // =============================================
  // 7. تصدير تقرير الإيرادات إلى Excel
  // =============================================
  Future<Uint8List> exportIncomesToExcel({
    DateTime? fromDate,
    DateTime? toDate,
    int? branchId,
    String? incomeGroup,
    int? incomeKindId,
  }) async {
    final response = await getIncomesReport(
      fromDate: fromDate,
      toDate: toDate,
      branchId: branchId,
      incomeGroup: incomeGroup,
      incomeKindId: incomeKindId,
    );

    if (response['success'] != true) {
      throw Exception('تعذر تحميل بيانات تقرير الإيرادات');
    }

    final List rawItems = response['data'] ?? [];
    final Map<String, dynamic> summary =
        Map<String, dynamic>.from(response['summary'] ?? {});

    final excel = Excel.createExcel();
    final sheet = excel['Incomes Report'];

    sheet.appendRow([
      TextCellValue('التاريخ'),
      TextCellValue('نوع الإيراد'),
      TextCellValue('المجموعة'),
      TextCellValue('الطفل'),
      TextCellValue('الفرع'),
      TextCellValue('رقم الإيصال'),
      TextCellValue('المبلغ'),
    ]);

    for (final raw in rawItems) {
      final item = IncomeItemModel.fromJson(Map<String, dynamic>.from(raw));

      sheet.appendRow([
        TextCellValue(_formatDate(item.incomeDate)),
        TextCellValue(item.incomeKindName),
        TextCellValue(item.incomeGroup),
        TextCellValue(item.childName ?? ''),
        TextCellValue(item.branchName ?? ''),
        TextCellValue(item.receiptNumber ?? ''),
        DoubleCellValue(item.amount),
      ]);
    }

    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('إجمالي الإيرادات'),
      DoubleCellValue(_toDouble(summary['totalAmount'])),
    ]);
    sheet.appendRow([
      TextCellValue('عدد المعاملات'),
      IntCellValue(summary['totalTransactions'] ?? 0),
    ]);
    sheet.appendRow([
      TextCellValue('عدد الأطفال'),
      IntCellValue(summary['totalChildren'] ?? 0),
    ]);
    sheet.appendRow([
      TextCellValue('متوسط الإيراد اليومي'),
      DoubleCellValue(_toDouble(summary['averageDaily'])),
    ]);

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('تعذر إنشاء ملف Excel');
    }

    return Uint8List.fromList(bytes);
  }

  // =============================================
  // 8. تصدير تقرير الإيرادات إلى PDF
  // =============================================
  Future<Uint8List> exportIncomesToPDF({
    DateTime? fromDate,
    DateTime? toDate,
    int? branchId,
    String? incomeGroup,
    int? incomeKindId,
  }) async {
    final response = await getIncomesReport(
      fromDate: fromDate,
      toDate: toDate,
      branchId: branchId,
      incomeGroup: incomeGroup,
      incomeKindId: incomeKindId,
    );

    if (response['success'] != true) {
      throw Exception('تعذر تحميل بيانات تقرير الإيرادات');
    }

    final List rawItems = response['data'] ?? [];
    final Map<String, dynamic> summary =
        Map<String, dynamic>.from(response['summary'] ?? {});

    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    final tableData = rawItems.map((raw) {
      final item = IncomeItemModel.fromJson(Map<String, dynamic>.from(raw));
      return [
        _formatDate(item.incomeDate),
        item.incomeKindName,
        item.incomeGroup,
        item.childName ?? '-',
        item.branchName ?? '-',
        item.receiptNumber ?? '-',
        _formatMoney(item.amount),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'تقرير الإيرادات',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: const [
                    'التاريخ',
                    'نوع الإيراد',
                    'المجموعة',
                    'الطفل',
                    'الفرع',
                    'رقم الإيصال',
                    'المبلغ',
                  ],
                  data: tableData,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellAlignment: pw.Alignment.centerRight,
                ),
                pw.SizedBox(height: 16),
                pw.Text('إجمالي الإيرادات: ${_formatMoney(_toDouble(summary['totalAmount']))}'),
                pw.Text('عدد المعاملات: ${summary['totalTransactions'] ?? 0}'),
                pw.Text('عدد الأطفال: ${summary['totalChildren'] ?? 0}'),
                pw.Text('متوسط الإيراد اليومي: ${_formatMoney(_toDouble(summary['averageDaily']))}'),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // =============================================
  // 9. تصدير إيرادات الطفل إلى Excel
  // =============================================
  Future<Uint8List> exportChildIncomesToExcel({
    required int childId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final response = await getChildIncomes(
      childId: childId,
      fromDate: fromDate,
      toDate: toDate,
    );

    if (response['success'] != true) {
      throw Exception('تعذر تحميل بيانات إيرادات الطفل');
    }

    final List rawItems = response['data'] ?? [];
    final Map<String, dynamic> summary =
        Map<String, dynamic>.from(response['summary'] ?? {});

    final excel = Excel.createExcel();
    final sheet = excel['Child Incomes'];

    sheet.appendRow([
      TextCellValue('التاريخ'),
      TextCellValue('نوع الإيراد'),
      TextCellValue('رقم الإيصال'),
      TextCellValue('الملاحظات'),
      TextCellValue('المبلغ'),
    ]);

    for (final raw in rawItems) {
      final item = ChildIncomeModel.fromJson(Map<String, dynamic>.from(raw));

      sheet.appendRow([
        TextCellValue(_formatDate(item.incomeDate)),
        TextCellValue(item.incomeKindName),
        TextCellValue(item.receiptNumber ?? ''),
        TextCellValue(item.notes ?? ''),
        DoubleCellValue(item.amount),
      ]);
    }

    sheet.appendRow([TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('إجمالي المدفوعات'),
      DoubleCellValue(_toDouble(summary['totalAmount'])),
    ]);
    sheet.appendRow([
      TextCellValue('عدد المعاملات'),
      IntCellValue(summary['totalTransactions'] ?? 0),
    ]);

    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('تعذر إنشاء ملف Excel');
    }

    return Uint8List.fromList(bytes);
  }

  // =============================================
  // 10. تصدير إيرادات الطفل إلى PDF
  // =============================================
  Future<Uint8List> exportChildIncomesToPDF({
    required int childId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final response = await getChildIncomes(
      childId: childId,
      fromDate: fromDate,
      toDate: toDate,
    );

    if (response['success'] != true) {
      throw Exception('تعذر تحميل بيانات إيرادات الطفل');
    }

    final List rawItems = response['data'] ?? [];
    final Map<String, dynamic> summary =
        Map<String, dynamic>.from(response['summary'] ?? {});

    final fontRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
    );
    final fontBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Cairo-Bold.ttf'),
    );

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    final tableData = rawItems.map((raw) {
      final item = ChildIncomeModel.fromJson(Map<String, dynamic>.from(raw));
      return [
        _formatDate(item.incomeDate),
        item.incomeKindName,
        item.receiptNumber ?? '-',
        item.notes ?? '-',
        _formatMoney(item.amount),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'إيرادات الطفل',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Table.fromTextArray(
                  headers: const [
                    'التاريخ',
                    'نوع الإيراد',
                    'رقم الإيصال',
                    'الملاحظات',
                    'المبلغ',
                  ],
                  data: tableData,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  cellAlignment: pw.Alignment.centerRight,
                ),
                pw.SizedBox(height: 16),
                pw.Text('إجمالي المدفوعات: ${_formatMoney(_toDouble(summary['totalAmount']))}'),
                pw.Text('عدد المعاملات: ${summary['totalTransactions'] ?? 0}'),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd', 'ar_EG').format(date);
  }

  String _formatMoney(double value) {
    return NumberFormat('#,##0.00', 'ar_EG').format(value);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  void dispose() {
    _client.close();
  }
}