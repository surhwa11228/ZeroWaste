import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  //이메일 회원가입
  Future<void> signUpWithEmail(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final idToken = await userCredential.user?.getIdToken();
    if (idToken == null) throw Exception('ID 토큰 없음');

    await _authenticateWithServer(idToken);
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
      Uri.parse('http://192.168.45.141:8080/api/auth/login'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
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
    return await _storage.read(key: 'accessToken');
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
