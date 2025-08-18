import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final authService = AuthService();

  bool _isLoading = false;
  bool _obscurePw = true;
  bool _obscurePw2 = true;

  String? _validateEmail(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return '이메일을 입력해 주세요.';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);
    if (!ok) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? _validatePassword(String? v) {
    final s = (v ?? '');
    if (s.isEmpty) return '비밀번호를 입력해 주세요.';
    if (s.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    final hasLower = RegExp(r'[a-z]').hasMatch(s);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(s);
    final hasDigit = RegExp(r'\d').hasMatch(s);
    final types = [hasLower, hasUpper, hasDigit].where((x) => x).length;
    if (types < 2) return '영문 대/소문자, 숫자 중 2가지 이상을 포함해 주세요.';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v != passwordController.text) return '비밀번호가 일치하지 않습니다.';
    return null;
  }

  Future<void> _handleSignup() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    setState(() => _isLoading = true);
    try {
      await authService.signUpWithEmail(
        emailController.text.trim(),
        passwordController.text,
      );
      if (!mounted) return;
      // 가입 → 인증 메일 발송 → 인증대기 화면
      Navigator.pushReplacementNamed(
        context,
        '/verify-email',
        arguments: {'email': emailController.text.trim()},
      );
    } catch (e) {
      // FirebaseAuthException/기타 에러를 사용자 친화 메시지로 변환
      _showError(_mapSignupError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapSignupError(Object e) {
    final msg = e.toString();
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return '이미 사용 중인 이메일입니다.';
        case 'invalid-email':
          return '올바르지 않은 이메일 주소입니다.';
        case 'operation-not-allowed':
          return '현재 이메일/비밀번호 가입이 비활성화되어 있습니다.';
        case 'weak-password':
          return '비밀번호가 안전하지 않습니다. 더 복잡하게 설정해 주세요.';
        case 'network-request-failed':
          return '네트워크 오류가 발생했습니다. 연결을 확인해 주세요.';
      }
    }
    // 서버/기타 예외
    if (msg.contains('timeout')) return '요청이 지연되고 있습니다. 잠시 후 다시 시도해 주세요.';
    return '회원가입에 실패했습니다. 다시 시도해 주세요.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ZeroWaste 회원가입',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePw,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: const OutlineInputBorder(),
                    helperText: '최소 8자, 특수기호 포함',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePw ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscurePw = !_obscurePw),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: confirmController,
                  obscureText: _obscurePw2,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePw2 ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePw2 = !_obscurePw2),
                    ),
                  ),
                  validator: _validateConfirm,
                  onFieldSubmitted: (_) => _isLoading ? null : _handleSignup(),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignup,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('회원가입'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
