import 'dart:convert';
import 'package:flutter_project/utils/api_enveloper.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _storage = const FlutterSecureStorage();
  final _google = GoogleSignIn(scopes: ['email']);

  //이메일 로그인
  Future<void> signInWithEmail(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) throw Exception('ID 토큰 없음');

    await _authenticateWithServer(idToken);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      // 선제 형식 검증(간단)
      if (email.trim().isEmpty) {
        throw Exception('이메일을 입력해 주세요.');
      }
      final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.trim());
      if (!emailOk) {
        throw Exception('올바른 이메일 형식이 아닙니다.');
      }
      if (password.length < 8) {
        throw Exception('비밀번호는 8자 이상이어야 합니다.');
      }

      // Firebase 계정 생성
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('회원가입에 실패했습니다. 다시 시도해 주세요.');
      }

      // 인증 메일 발송 (인앱 딥링크 미사용; 브라우저로 열림)
      await user.sendEmailVerification(
        ActionCodeSettings(
          url:
              'https://zerowaste-ccae3.firebaseapp.com/__/auth/action?mode=action&oobCode=code/verified', // 랜딩 페이지(공지용이면 충분)
          handleCodeInApp: false, // 딥링크 미사용 (간단/안정)
        ),
      );

      // ✅ 여기서 서버 인증 호출하지 않음.
      //    화면 쪽에서 /verify-email 로 라우팅하여
      //    "다시 확인" 버튼에서 emailVerified 체크 후 로그인 진행.
    } on FirebaseAuthException catch (e) {
      // Firebase 에러코드 → 사용자 친화 메시지
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('이미 사용 중인 이메일입니다.');
        case 'invalid-email':
          throw Exception('올바르지 않은 이메일 주소입니다.');
        case 'operation-not-allowed':
          throw Exception('현재 이메일/비밀번호 가입이 비활성화되어 있습니다.');
        case 'weak-password': // Firebase 기본 기준(6자)이나, 우리는 선제 검증으로 8자 요구
          throw Exception('비밀번호가 안전하지 않습니다. 더 복잡하게 설정해 주세요.');
        case 'network-request-failed':
          throw Exception('네트워크 오류가 발생했습니다. 연결을 확인해 주세요.');
        default:
          throw Exception('회원가입에 실패했습니다. (${e.code})');
      }
    } catch (e) {
      // 기타 예외
      throw Exception(e.toString());
    }
  }

  //Google 로그인
  Future<void> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) throw Exception('Google 로그인 취소됨');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) throw Exception('ID 토큰 없음');

    await _authenticateWithServer(idToken);
  }

  //서버에 ID 토큰 전송 → accessToken / refreshToken 저장
  Future<void> _authenticateWithServer(String idToken) async {
    final response = await http.post(
      Uri.parse('http://192.168.45.98:8080/api/auth/login'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      final data = res['data'];

      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      await _storage.write(key: 'accessToken', value: accessToken);
      await _storage.write(key: 'refreshToken', value: refreshToken);
    } else {
      throw Exception('서버 로그인 실패: ${response.statusCode}');
    }
  }

  //저장된 accessToken 가져오기
  Future<String?> getAccessToken() async {
    Fluttertoast.showToast(
      msg: "로그인이 필요합니다. ${await _storage.read(key: 'accessToken')}",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    return await _storage.read(key: 'accessToken');
  }

  Future<String?> refreshAccessToken() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken == null) return null;

    final response = await http.post(
      Uri.parse('http://192.168.45.98:8080/api/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newAccessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String? ?? refreshToken;

      if (newAccessToken != null) {
        await _storage.write(key: 'accessToken', value: newAccessToken);
      }
      await _storage.write(key: 'refreshToken', value: newRefreshToken);
      return newAccessToken;
    } else {
      return null; // 갱신 실패
    }
  }

  //로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
    await _storage.deleteAll();
  }

  //현재 Firebase 유저 (null일 수 있음)
  User? get currentUser => _auth.currentUser;
}
