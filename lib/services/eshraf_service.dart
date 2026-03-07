import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/eshraf_type_model.dart';
//import '../config/api_config.dart';

class EshrafService {
  // جلب أنواع الإشراف
  static Future<List<EshrafType>> getEshrafTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/lookup/eshraf-types'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => EshrafType.fromJson(json)).toList();
      } else {
        throw Exception('فشل تحميل الأنواع');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // إضافة جزاء/مكافأة
  static Future<bool> addEshraf({
    required int empId,
    required double amount,
    required DateTime date,
    required String kind,
    required String notes,
    required String user,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/eshraf/add'),
        headers: ApiConfig.headers,
        body: json.encode({
          'empId': empId,
          'amount': amount,
          'date': date.toIso8601String(),
          'kind': kind,
          'notes': notes,
          'user': user,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('فشل الحفظ: $e');
    }
  }
}