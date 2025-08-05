import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/report_detail_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/admin_dashboard_screen.dart';

void main() {
  runApp(const ZeroWasteApp());
}

class ZeroWasteApp extends StatelessWidget {
  const ZeroWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZeroWaste (UI)',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/home': (_) => const HomeScreen(),
        '/report': (_) => const ReportScreen(),
        '/report-detail': (_) => const ReportDetailScreen(),
        '/mypage': (_) => const MyPageScreen(),
        '/admin': (_) => const AdminDashboardScreen(),
      },
    );
  }
}
