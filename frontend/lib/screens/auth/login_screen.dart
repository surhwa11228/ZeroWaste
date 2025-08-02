import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    bool result = await AuthService.login(_email.text, _password.text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그인 성공!')));
      print('로그인 성공. 홈 화면으로 이동');
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이메일 또는 비밀번호가 잘못되었습니다.')));
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: '이메일'),
                validator: (v) => v!.isEmpty ? '이메일을 입력해주세요' : null,
              ),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (v) => v!.isEmpty ? '비밀번호를 입력해주세요' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(onPressed: _login, child: const Text('로그인')),
              TextButton(onPressed: _goToRegister, child: const Text('회원가입')),
            ],
          ),
        ),
      ),
    );
  }
}
