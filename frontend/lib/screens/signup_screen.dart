import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool agreed = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.recycling, size: 72, color: Colors.green),
              const SizedBox(height: 12),
              Text(
                '회원가입',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // 이름(선택)
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '이름 (선택)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 이메일
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
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
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 비밀번호 확인
              TextField(
                controller: confirmController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
                    icon: Icon(
                      obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 약관 동의
              Row(
                children: [
                  Checkbox(
                    value: agreed,
                    onChanged: (v) => setState(() => agreed = v ?? false),
                  ),
                  const Expanded(child: Text('이용약관 및 개인정보 처리방침에 동의합니다.')),
                ],
              ),
              const SizedBox(height: 8),

              // 가입 버튼
              ElevatedButton(
                onPressed: () {
                  // TODO: Firebase Auth로 회원가입 연동 예정
                  // 유효성 예: 이메일/비밀번호 체크, 비밀번호 일치 여부, 약관 동의 등
                  if (!agreed) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('약관에 동의해 주세요.')),
                    );
                    return;
                  }
                },
                child: const Text('가입하기'),
              ),
              const SizedBox(height: 12),

              // 구글로 가입
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Google Sign-In 연동 예정
                },
                icon: const Icon(Icons.account_circle),
                label: const Text('Google로 가입'),
              ),
              const SizedBox(height: 16),

              // 로그인으로 이동
              TextButton(
                onPressed: () {
                  // 보통 회원가입에서 뒤로가면 로그인 화면으로 돌아갑니다.
                  Navigator.maybePop(context);
                },
                child: const Text('이미 계정이 있으신가요? 로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
