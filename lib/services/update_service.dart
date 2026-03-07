import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UpdateService {
  static const String githubUser = 'kazayza';
  static const String repoName = 'WillBe-app';

  // ① التحقق من وجود تحديث
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      final url = Uri.parse(
          'https://api.github.com/repos/$githubUser/$repoName/releases/latest');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String latestVersion = data['tag_name'].toString().replaceAll('v', '');

        if (_isNewer(latestVersion, currentVersion)) {
          final downloadUrl = data['assets'][0]['browser_download_url'];

          if (context.mounted) {
            _showUpdateDialog(
                context, latestVersion, downloadUrl, data['body']);
          }
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  // ② مقارنة الإصدارات
  static bool _isNewer(String latest, String current) {
    List<int> l = latest.split('.').map(int.parse).toList();
    List<int> c = current.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  // ③ طلب الصلاحيات
  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      // صلاحية التثبيت
      var installStatus = await Permission.requestInstallPackages.status;
      if (!installStatus.isGranted) {
        installStatus = await Permission.requestInstallPackages.request();
        if (!installStatus.isGranted) return false;
      }

      // صلاحية التخزين
      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
      }
    }
    return true;
  }

  // ④ تحميل وتثبيت التحديث
  static Future<void> _downloadAndInstall(
      BuildContext context, String downloadUrl) async {
    // طلب الصلاحيات
    bool hasPermission = await _requestPermissions();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب منح صلاحية التثبيت')),
        );
      }
      return;
    }

    // متغيرات التحميل
    double progress = 0;
    bool isDownloading = true;
    String statusText = 'جاري بدء التحميل...';

    // عرض شاشة التحميل
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setState) {
              // بدء التحميل
              if (isDownloading) {
                isDownloading = false;
                _startDownload(
                  downloadUrl: downloadUrl,
                  onProgress: (received, total) {
                    setState(() {
                      progress = received / total;
                      statusText =
                          '${(received / 1024 / 1024).toStringAsFixed(1)} MB / ${(total / 1024 / 1024).toStringAsFixed(1)} MB';
                    });
                  },
                  onComplete: (filePath) {
                    Navigator.of(ctx).pop();
                    _installApk(filePath);
                  },
                  onError: (error) {
                    Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('فشل التحميل: $error')),
                      );
                    }
                  },
                );
              }

              return AlertDialog(
                title: Row(
                  children: const [
                    Icon(Icons.downloading, color: Color(0xFF6366F1)),
                    SizedBox(width: 10),
                    Text('جاري التحميل'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1)),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }

  // ⑤ بدء التحميل
  static Future<void> _startDownload({
    required String downloadUrl,
    required Function(double received, double total) onProgress,
    required Function(String filePath) onComplete,
    required Function(String error) onError,
  }) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        onError('لا يمكن الوصول للتخزين');
        return;
      }

      final savePath = '${directory.path}/willbee_update.apk';

      // حذف الملف القديم
      final oldFile = File(savePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      // تحميل الملف
      final dio = Dio();
      await dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received.toDouble(), total.toDouble());
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      // التحقق من الملف
      final file = File(savePath);
      if (await file.exists()) {
        final size = await file.length();
        debugPrint('✅ تم التحميل - الحجم: ${(size / 1024 / 1024).toStringAsFixed(2)} MB');

        if (size > 1000000) {
          onComplete(savePath);
        } else {
          onError('الملف المحمل غير صالح');
        }
      } else {
        onError('فشل حفظ الملف');
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  // ⑥ تثبيت الـ APK
  static Future<void> _installApk(String filePath) async {
    try {
      debugPrint('🚀 جاري فتح الملف للتثبيت: $filePath');
      final result = await OpenFilex.open(filePath);
      debugPrint('📋 نتيجة: ${result.type} - ${result.message}');
    } catch (e) {
      debugPrint('❌ خطأ في التثبيت: $e');
    }
  }

  // ⑦ شاشة التحديث
  static void _showUpdateDialog(
      BuildContext context, String version, String url, String? notes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.system_update, color: Color(0xFF6366F1)),
            SizedBox(width: 10),
            Text('تحديث جديد متوفر'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار الجديد: $version'),
            const SizedBox(height: 10),
            const Text('ما الجديد:',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
              Navigator.pop(ctx);
              _downloadAndInstall(context, url);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('تحديث الآن',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}