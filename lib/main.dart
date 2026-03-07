import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'providers/auth_provider.dart';
import 'providers/children_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/employees_provider.dart';
import 'providers/classes_provider.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
import 'providers/crm_kpi_provider.dart';
import 'providers/financial_settings_provider.dart';
import 'providers/expenses_kpi_provider.dart';
import 'providers/debt_provider.dart';




// ✅ دالة استقبال الإشعارات في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('إشعار في الخلفية: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ تهيئة Firebase
  await Firebase.initializeApp();
  
  // ✅ تهيئة الإشعارات
  await NotificationService.initialize();
  
  // ✅ ربط دالة الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // ✅ تهيئة الـ Arabic locale للتواريخ
  await initializeDateFormatting('ar', null);
  tz.initializeTimeZones();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider<ChildrenProvider>(
          create: (context) => ChildrenProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CRMKPIProvider()
        ), 
        ChangeNotifierProvider<EmployeesProvider>(
          create: (context) => EmployeesProvider(),
        ),
        ChangeNotifierProvider<ClassesProvider>(
        create: (context) => ClassesProvider(),
        ),
        ChangeNotifierProvider<AttendanceProvider>(
        create: (context) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => FinancialSettingsProvider()),
        ChangeNotifierProvider(create: (_) => ExpensesKPIProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
      ],
      child: const WillBeeApp(),
    ),
  );
}

class WillBeeApp extends StatelessWidget {
  const WillBeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    const primaryBlue = Color(0xFF4AA3F8);
    const accentYellow = Color(0xFFFFE600);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WILL BE Kindergarten',

      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: accentYellow,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),

      // Dark Theme
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: accentYellow,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),

      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      home: const LoginScreen(),
    );
  }
}