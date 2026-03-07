import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expenses_kpi_model.dart';

class ExpensesKPIService {
  static const String _baseUrl = 'https://willbee-backend.vercel.app/api';

  static Future<ExpensesKPIModel> getExpensesKPI({
    String? periodType,
    String? startDate,
    String? endDate,
    int? branchId,
    String? groupId,
    int? kindId,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (periodType != null) queryParams['periodType'] = periodType;
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (branchId != null) queryParams['branchId'] = branchId.toString();
      if (groupId != null) queryParams['groupId'] = groupId;
      if (kindId != null) queryParams['kindId'] = kindId.toString();

      final uri = Uri.parse('$_baseUrl/expenses-kpi/kpi')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      print('🔵 Request URL: $uri');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      print('🟢 Status Code: ${response.statusCode}');
      print('🟢 Response Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ExpensesKPIModel.fromJson(json);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'حدث خطأ في جلب البيانات');
      }
    } on http.ClientException catch (e) {
      print('🔴 Client Error: $e');
      throw Exception('خطأ في الاتصال بالسيرفر');
    } on FormatException catch (e) {
      print('🔴 Format Error: $e');
      throw Exception('خطأ في تنسيق البيانات');
    } catch (e) {
      print('🔴 General Error: $e');
      if (e is Exception) rethrow;
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  static Future<ExpenseFiltersModel> getFilters() async {
    try {
      final uri = Uri.parse('$_baseUrl/expenses-kpi/filters');

      print('🔵 Filters URL: $uri');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      print('🟢 Filters Status: ${response.statusCode}');
      print('🟢 Filters Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ExpenseFiltersModel.fromJson(json);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'حدث خطأ في جلب الفلاتر');
      }
    } on http.ClientException catch (e) {
      print('🔴 Filters Client Error: $e');
      throw Exception('خطأ في الاتصال بالسيرفر');
    } on FormatException catch (e) {
      print('🔴 Filters Format Error: $e');
      throw Exception('خطأ في تنسيق البيانات');
    } catch (e) {
      print('🔴 Filters General Error: $e');
      if (e is Exception) rethrow;
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }
}