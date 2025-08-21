import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // 메일앱 열기(미인증 안내용)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();

  bool _isLoading = false;
  bool _obscurePw = true;

  // ───────────────────────── Helpers ─────────────────────────
  void _showSnack(String message, {Color? bg}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: bg));
  }

  String _mapLoginError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return '올바르지 않은 이메일 주소입니다.';
        case 'user-disabled':
          return '해당 계정은 비활성화되어 있습니다. 관리자에게 문의해 주세요.';
        case 'user-not-found':
          return '등록되지 않은 이메일입니다. 회원가입 후 이용해 주세요.';
        case 'wrong-password':
          return '이메일 또는 비밀번호가 올바르지 않습니다.';
        case 'too-many-requests':
          return '로그인 시도가 많습니다. 잠시 후 다시 시도해 주세요.';
        case 'network-request-failed':
          return '네트워크 오류입니다. 연결을 확인한 뒤 다시 시도해 주세요.';
        default:
          return '등록되지 않은 이메일입니다. 회원가입 후 이용해 주세요.';
      }
    }
    final msg = e.toString();
    if (msg.contains('timeout')) {
      return '요청이 지연되고 있습니다. 네트워크 상태를 확인해 주세요.';
    }
    return '로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.';
  }

  Future<void> _openMailApp() async {
    final candidates = [
      Uri.parse('mailto:'), // 기본 메일 작성
      Uri.parse('message://'), // iOS Mail
      Uri.parse('googlegmail://'), // Gmail
    ];
    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    _showSnack('메일 앱을 열 수 없습니다. 브라우저에서 메일을 확인해 주세요.');
  }

  Future<void> _sendPasswordReset() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('먼저 이메일을 입력해 주세요.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnack('비밀번호 재설정 메일을 보냈습니다. 메일함을 확인해 주세요.');
    } on FirebaseAuthException catch (e) {
      _showSnack(_mapLoginError(e), bg: Colors.red);
    } catch (e) {
      _showSnack('재설정 요청에 실패했습니다. 잠시 후 다시 시도해 주세요.', bg: Colors.red);
    }
  }

  // ───────────────────────── Actions ─────────────────────────
  Future<void> _handleEmailLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('이메일과 비밀번호를 모두 입력해 주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await authService.signInWithEmail(email, password);

      // 이메일 미인증 사용자 안내 (필요 시 켜두면 좋아요)
      final user = FirebaseAuth.instance.currentUser;
      final verified = user?.emailVerified ?? true;
      if (!verified) {
        await user!.sendEmailVerification();
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('이메일 인증이 필요합니다. 메일의 링크로 인증을 완료해 주세요.'),
            action: SnackBarAction(label: '메일 앱 열기', onPressed: _openMailApp),
          ),
        );
        return;
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showSnack(_mapLoginError(e), bg: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await authService.signInWithGoogle();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      _showSnack('Google 로그인에 실패했습니다. 잠시 후 다시 시도해 주세요.', bg: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ───────────────────────── UI ─────────────────────────
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ZeroWaste 로그인',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // 이메일
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 비밀번호
              TextField(
                controller: passwordController,
                obscureText: _obscurePw,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isLoading ? null : _handleEmailLogin(),
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePw ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscurePw = !_obscurePw),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 비밀번호 재설정
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _sendPasswordReset,
                  child: const Text('비밀번호를 잊으셨나요?'),
                ),
              ),
              const SizedBox(height: 8),

              // 이메일 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleEmailLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('이메일로 로그인'),
                ),
              ),
              const SizedBox(height: 16),

              // 구글 로그인
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Google로 로그인'),
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                ),
              ),
              const SizedBox(height: 16),

              // 회원가입 이동
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('계정이 없으신가요?'),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('회원가입'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
