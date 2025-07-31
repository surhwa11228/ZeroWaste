import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _region = TextEditingController();
  final TextEditingController _birthDate = TextEditingController();

  bool _codeSent = false;
  bool _codeVerified = false;

  void _sendVerificationCode() async {
    bool result = await AuthService.sendVerificationCode(_phone.text);
    if (!mounted) return;

    if (result) {
      setState(() {
        _codeSent = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('인증번호가 전송되었습니다. (mock: 123456)')));
    }
  }

  void _verifyCode() async {
    bool result = await AuthService.verifyCode(_code.text);
    if (!mounted) return;

    if (result) {
      setState(() {
        _codeVerified = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('인증되었습니다.')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('인증번호가 일치하지 않습니다.')));
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _codeVerified) {
      final user = User(
        email: _email.text,
        password: _password.text,
        name: _name.text,
        phoneNumber: _phone.text,
        verificationCode: _code.text,
        region: _region.text,
        birthDate: _birthDate.text,
      );

      bool registered = await AuthService.registerUser(user);
      if (!mounted) return;

      if (registered) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('회원가입 완료')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: '이메일'),
                validator: (v) => v!.isEmpty ? '이메일을 입력해주세요' : null,
              ),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (v) => v!.length < 8 ? '비밀번호는 8자 이상 입력하세요' : null,
              ),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: '이름'),
                validator: (v) => v!.isEmpty ? '이름을 입력해주세요' : null,
              ),
              TextFormField(
                controller: _phone,
                decoration: InputDecoration(labelText: '전화번호'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? '전화번호를 입력해주세요' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _code,
                      decoration: InputDecoration(labelText: '인증번호'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _codeSent ? _verifyCode : _sendVerificationCode,
                    child: Text(_codeSent ? '인증하기' : '인증번호 전송'),
                  ),
                ],
              ),
              TextFormField(
                controller: _region,
                decoration: InputDecoration(labelText: '지역'),
                validator: (v) => v!.isEmpty ? '지역을 입력해주세요' : null,
              ),
              TextFormField(
                controller: _birthDate,
                decoration: InputDecoration(labelText: '생년월일 (YYYY-MM-DD)'),
                validator: (v) => v!.isEmpty ? '생년월일을 입력해주세요' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: Text('회원가입')),
            ],
          ),
        ),
      ),
    );
  }
}
