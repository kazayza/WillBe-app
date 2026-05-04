import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/finance_session_details_model.dart';
import 'api_service.dart';

class FinanceSessionDetailsService {
  static const String _base =
      '${ApiService.baseUrl}/child-finance-browser';

  static Future<FinanceSessionDashboardModel> getSessionDashboard(
    int sessionId,
  ) async {
    final response = await http.get(
      Uri.parse('$_base/session-dashboard/$sessionId'),
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في تحميل بيانات العام المالي');
    }

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'حدث خطأ غير متوقع');
    }

    return FinanceSessionDashboardModel.fromJson(data);
  }

  static Future<FinanceSessionRecordsResponse> getSessionRecords({
    required int sessionId,
    required String branchId,
    required String status,
    required String kind,
    required String viewMode,
    required String sortBy,
    required String sortOrder,
    required String search,
    int page = 1,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse(
      '$_base/session-records/$sessionId'
      '?branchId=$branchId'
      '&status=$status'
      '&kind=$kind'
      '&viewMode=$viewMode'
      '&sortBy=$sortBy'
      '&sortOrder=$sortOrder'
      '&search=${Uri.encodeComponent(search)}'
      '&page=$page'
      '&pageSize=$pageSize',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('فشل في تحميل السجلات');
    }

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'حدث خطأ غير متوقع');
    }

    return FinanceSessionRecordsResponse.fromJson(data);
  }
}