import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  // 🔴 عدّل دول باسمك واسم المشروع على GitHub
  static const String githubUser = 'kazayza';
  static const String repoName = 'WillBe-app';

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // 1. نجيب الإصدار الحالي من التطبيق
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version; // مثلاً 1.0.0

      // 2. نجيب أحدث Release من GitHub
      final url = Uri.parse(
          'https://api.github.com/repos/$githubUser/$repoName/releases/latest');
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String latestVersion = data['tag_name']; // مثلاً v1.0.1
        
        // نشيل حرف 'v' لو موجود عشان المقارنة
        latestVersion = latestVersion.replaceAll('v', '');

        // 3. نقارن الإصدارات
        if (_isNewer(latestVersion, currentVersion)) {
          // فيه تحديث! نطلع Dialog
          final downloadUrl = data['assets'][0]['browser_download_url'];
          
          if (context.mounted) {
            _showUpdateDialog(context, latestVersion, downloadUrl, data['body']);
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  // دالة بسيطة لمقارنة الإصدارات
  static bool _isNewer(String latest, String current) {
    List<int> l = latest.split('.').map(int.parse).toList();
    List<int> c = current.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
      BuildContext context, String version, String url, String notes) {
    showDialog(
      context: context,
      barrierDismissible: false, // يمنع قفل النافذة بالضغط بره
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Color(0xFF6366F1)),
            const SizedBox(width: 10),
            const Text('تحديث جديد متوفر'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار الجديد: $version'),
            const SizedBox(height: 10),
            const Text('ما الجديد:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(notes ?? 'تحسينات وإصلاحات عامة.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لاحقاً'),
          ),
          ElevatedButton(
            onPressed: () {
              _launchURL(url);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('تحديث الآن', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  static Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}