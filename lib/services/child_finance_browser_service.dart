import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/child_finance_browser_model.dart';
import 'api_service.dart';

class ChildFinanceBrowserService {
  static const String _base =
      '${ApiService.baseUrl}/child-finance-browser';

  static Future<List<SessionOverviewModel>> getSessionsOverview() async {
    final response = await http.get(
      Uri.parse('$_base/sessions-overview'),
    );

    if (response.statusCode != 200) {
      throw Exception('فشل في تحميل الأعوام المالية');
    }

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'حدث خطأ غير متوقع');
    }

    final List list = data['data'] ?? [];
    return list.map((e) => SessionOverviewModel.fromJson(e)).toList();
  }
}