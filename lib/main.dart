import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'providers/children_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/employees_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  // ✅ هذا السطر مهم جداً
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ تهيئة الـ Arabic locale للتواريخ
  await initializeDateFormatting('ar', null);
  
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
        ChangeNotifierProvider<EmployeesProvider>(
          create: (context) => EmployeesProvider(),
        ),
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