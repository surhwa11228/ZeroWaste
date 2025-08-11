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
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/board_list_screen.dart';
import 'screens/report_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ZeroWasteApp());
}

class ZeroWasteApp extends StatelessWidget {
  const ZeroWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZeroWaste',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      // NOTE: 'home'가 설정되면 'initialRoute'는 무시 가능
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasData) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),

      // initialRoute를 사용 시, 'home'을 제거하고 routes 기반으로 전환
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
        '/board': (_) => const BoardListScreen(),
        '/reportList': (_) => const ReportListScreen(),
      },
    );
  }
}
