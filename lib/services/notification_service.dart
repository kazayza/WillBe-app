import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // ✅ تهيئة الإشعارات
  static Future<void> initialize() async {
    // طلب الصلاحيات
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // إعداد الإشعارات المحلية
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // إنشاء قناة الإشعارات لـ Android
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'إشعارات مهمة',
      description: 'هذه القناة للإشعارات المهمة',
      importance: Importance.high,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // الاستماع للإشعارات وهو التطبيق مفتوح
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // ✅ جلب FCM Token
  static Future<String?> getToken() async {
    String? token = await _messaging.getToken();
    print('FCM Token: $token');
    return token;
  }

  // ✅ التعامل مع الإشعارات والتطبيق مفتوح
  static void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'إشعارات مهمة',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }
}