import '../models/user.dart';

class AuthService {
  static Future<bool> sendVerificationCode(String phoneNumber) async {
    //임시 인증번호
    await Future.delayed(Duration(seconds: 1));
    print('인증번호: 123456');
    return true;
  }

  static Future<bool> verifyCode(String inputCode) async {
    //인증번호 비교
    await Future.delayed(Duration(milliseconds: 500));
    return inputCode == '123456';
  }

  static Future<bool> registerUser(User user) async {
    //가입 성공 시 유저 정보 저장
    await Future.delayed(Duration(seconds: 1));
    print('회원가입 완료 (Mock): ${user.toJson()}');
    return true;
  }

  static Future<bool> login(String email, String password) async {
    await Future.delayed(Duration(milliseconds: 800));
    return email == 'test@example.com' && password == '1234';
  }
}
