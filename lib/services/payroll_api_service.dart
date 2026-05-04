import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payroll_model.dart';
import '../services/api_service.dart';


class PayrollApiService {
  
  static String get baseUrl => '${ApiService.baseUrl}/salaries';

  // ==============================================================
  // 1. جلب الرواتب (ذكي: أرشيف أو حساب جديد + حفظ تلقائي)
  // ==============================================================
  Future<PayrollResponse> fetchPayroll({
  required int month,
  required int year,
  int? branchId,
  int? workerTypeId,
  int? empId,
  String? user,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/fetch'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'month': month,
        'year': year,
        'branchId': branchId,
        'workerTypeId': workerTypeId,
        'empId': empId,
        'user': user ?? 'System',
      }),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonData = json.decode(response.body);
      return PayrollResponse.fromJson(jsonData);
    } else {
      throw Exception('فشل جلب الرواتب. كود الخطأ: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('تعذر الاتصال بالخادم: $e');
  }
}

  // ==============================================================
  // 2. حفظ التعديلات اليدوية (مسودة)
  // ==============================================================
  Future<bool> updateDraft({
    required int expenseId,
    required String user,
    required List<PayrollModel> payrollList,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/draft'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'expenseId': expenseId,
          'user': user,
          'payrollList': payrollList.map((e) => e.toJson()).toList(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('خطأ في حفظ المسودة: ${response.body}');
        return false;
      }
    } catch (e) {
      print('خطأ في الاتصال: $e');
      return false;
    }
  }

  // ==============================================================
  // 3. اعتماد الرواتب (نهائي)
  // ==============================================================
  Future<bool> approvePayroll({
    required int expenseId,
    required int month,
    required int year,
    required String user,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'expenseId': expenseId,
          'month': month,
          'year': year,
          'user': user,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('خطأ في الاعتماد: ${response.body}');
        return false;
      }
    } catch (e) {
      print('خطأ في الاتصال: $e');
      return false;
    }
  }
}