import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: const [
            TextField(decoration: InputDecoration(labelText: '이름')),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: '이메일')),
            SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: '비밀번호'),
            ),
            SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: '비밀번호 확인'),
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: null, child: Text('가입하기')),
          ],
        ),
      ),
    );
  }
}
