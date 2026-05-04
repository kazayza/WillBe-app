import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/profit_loss_model.dart';
import 'api_service.dart';

class ProfitLossService {
  static const String _baseEndpoint = '${ApiService.baseUrl}/profit-loss';

  // ============================================
  // 📊 التقرير التفصيلي
  // ============================================
  static Future<ProfitLossReport> getReport({
    required String startDate,
    required String endDate,
    String branchId = 'all',
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseEndpoint/report?startDate=$startDate&endDate=$endDate&branchId=$branchId',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return ProfitLossReport.fromJson(data);
        }
        throw Exception(data['error'] ?? 'فشل في جلب التقرير');
      }
      throw Exception('خطأ في الاتصال: ${response.statusCode}');
    } catch (e) {
      throw Exception('خطأ: $e');
    }
  }

  // ============================================
  // 📈 الملخص السريع
  // ============================================
  static Future<SummaryData> getSummary({String period = 'month'}) async {
    try {
      final uri = Uri.parse('$_baseEndpoint/summary?period=$period');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return SummaryData.fromJson(data['data']);
        }
        throw Exception(data['error'] ?? 'فشل في جلب الملخص');
      }
      throw Exception('خطأ في الاتصال: ${response.statusCode}');
    } catch (e) {
      throw Exception('خطأ: $e');
    }
  }

  // ============================================
  // 📅 التقرير الشهري
  // ============================================
  static Future<MonthlyTrendResponse> getMonthlyTrend({
    required int year,
    String branchId = 'all',
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseEndpoint/monthly-trend?year=$year&branchId=$branchId',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return MonthlyTrendResponse.fromJson(data);
        }
        throw Exception(data['error'] ?? 'فشل في جلب التقرير الشهري');
      }
      throw Exception('خطأ في الاتصال: ${response.statusCode}');
    } catch (e) {
      throw Exception('خطأ: $e');
    }
  }

  // ============================================
  // 🏢 تقرير الفروع
  // ============================================
  static Future<BranchReportResponse> getBranchReport({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseEndpoint/by-branch?startDate=$startDate&endDate=$endDate',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return BranchReportResponse.fromJson(data);
        }
        throw Exception(data['error'] ?? 'فشل في جلب تقرير الفروع');
      }
      throw Exception('خطأ في الاتصال: ${response.statusCode}');
    } catch (e) {
      throw Exception('خطأ: $e');
    }
  }
}