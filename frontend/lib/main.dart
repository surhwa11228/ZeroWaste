import 'package:flutter/material.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/report_list_screen.dart';
import 'screens/report_create_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/board_list_screen.dart';
import 'screens/board_write_screen.dart';
import 'screens/board_detail_screen.dart';
import 'screens/verify_email_screen.dart';

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

      home: const _RootGate(),

      // initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/verify-email': (ctx) {
          final args =
              ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
          return VerifyEmailScreen(email: args?['email'] as String?);
        },
        '/home': (_) => const HomeScreen(),
        '/report': (_) => const ReportScreen(),
        '/report/create': (_) => const ReportCreateScreen(),
        '/report/my': (_) => const MyReportsScreen(),
        '/mypage': (_) => const MyPageScreen(),
        '/admin': (_) => const AdminDashboardScreen(),
        '/board': (_) => const BoardListScreen(),
        '/boardWrite': (ctx) {
          final boardName =
              ModalRoute.of(ctx)!.settings.arguments as String? ?? 'freeBoard';
          return BoardWriteScreen(boardName: boardName);
        },
        '/boardDetail': (ctx) {
          final args = ModalRoute.of(ctx)!.settings.arguments as Map?;
          final boardName = args?['boardName'] as String? ?? 'freeBoard';
          final postId = args?['postId'] as String;
          return BoardDetailScreen(boardName: boardName, postId: postId);
        },
      },
    );
  }
}

/// 초기 라우팅 게이트:
/// - FirebaseAuth 상태를 관찰해 로그인되어 있으면 '/home', 아니면 '/login'으로
/// - 항상 pushNamedAndRemoveUntil로 이전 스택을 제거 ⇒ 뒤로가기로 온보딩/로그인으로 돌아가지 않음
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        // 로딩 중엔 스플래시 스타일로 대기
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final signedIn = snap.data != null;
          final target = signedIn ? '/home' : '/login';
          // ✅ 스택을 전부 비운 후 진입
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(target, (route) => false);
        });

        // Frame callback 동안 보여줄 얇은 로딩
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

/// 홈에서 뒤로가기 시 종료 확인 다이얼로그를 띄우는 가드.
/// - Android: '종료' 선택 시 SystemNavigator.pop()
/// - iOS: 강제 종료는 권장되지 않아 아무 동작 없이 닫힘(필요시 커스텀 처리 가능)
class ExitConfirmScope extends StatelessWidget {
  final Widget child;
  final String title;
  final String message;

  const ExitConfirmScope({
    super.key,
    required this.child,
    this.title = '앱 종료',
    this.message = '정말 종료할까요?',
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final ok =
            await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('취소'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('종료'),
                  ),
                ],
              ),
            ) ??
            false;
        return false;
      },
      child: child,
    );
  }
}
