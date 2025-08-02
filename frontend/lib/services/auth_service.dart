import '../models/user.dart';

class AuthService {
  static User? _registeredUser; // 회원가입한 사용자 임시 저장

  static final List<User> _demoUsers = [
    User(
      email: 'test@email.com',
      password: 'test1234',
      name: '테스터',
      phoneNumber: '01012345678',
      verificationCode: '123456',
      region: '대전',
      birthDate: '2000-01-01',
    ),
  ];

  static Future<bool> sendVerificationCode(String phoneNumber) async {
    await Future.delayed(Duration(seconds: 1));
    print('인증번호 전송됨: 123456 (모의)');
    return true;
  }

  static Future<bool> verifyCode(String inputCode) async {
    await Future.delayed(Duration(milliseconds: 500));
    return inputCode == '123456';
  }

  static Future<bool> registerUser(User user) async {
    await Future.delayed(Duration(seconds: 1));
    _registeredUser = user; // ✅ 가입한 유저 저장
    print('회원가입 완료 (Mock): ${user.toJson()}');
    return true;
  }

  static Future<bool> login(String email, String password) async {
    await Future.delayed(Duration(milliseconds: 800));

    final demoMatch = _demoUsers.firstWhere(
      (u) => u.email == email && u.password == password,
      orElse: () =>
          _registeredUser ??
          User(
            email: '',
            password: '',
            name: '',
            phoneNumber: '',
            verificationCode: '',
            region: '',
            birthDate: '',
          ),
    );

    if (demoMatch.email != '') {
      _registeredUser = demoMatch;
      return true;
    }

    return false;
  }

  // return _registeredUser != null &&
  //     _registeredUser!.email == email &&
  //     _registeredUser!.password == password;
  // }

  static User? get currentUser => _registeredUser;
}
