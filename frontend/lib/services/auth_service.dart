import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Firebase Auth ↔ 백엔드 토큰 교환/저장/리프레시 + 이메일 회원가입/구글 로그인 유지
class AuthService {
  // 서버 베이스 URL (network.dart와 동일하게 맞춰 주세요)
  static const String _base = 'https://2f89e3a134ea.ngrok-free.app/api';

  // SecureStorage 키 (프로젝트 기존 키 유지)
  static const String _kAccess = 'accessToken';
  static const String _kRefresh = 'refreshToken';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleSignIn _google = GoogleSignIn(scopes: ['email']);

  // ───────────────────────── 회원가입 / 로그인 ─────────────────────────

  /// 이메일/비번 로그인 → Firebase 성공 후 서버 교환
  Future<void> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final idToken = await cred.user?.getIdToken();
    if (idToken == null) throw Exception('ID 토큰 없음');
    await _authenticateWithServer(idToken); // 서버 교환 → access/refresh 저장
  }

  /// 이메일 회원가입 + 인증메일 발송
  /// ※ 가입 시점에는 서버 교환을 하지 않고, 사용자 이메일 인증 후 로그인 과정에서 교환
  Future<void> signUpWithEmail(String email, String password) async {
    // 간단한 선제 검증
    final e = email.trim();
    if (e.isEmpty) throw Exception('이메일을 입력해 주세요.');
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(e);
    if (!emailOk) throw Exception('올바른 이메일 형식이 아닙니다.');
    if (password.length < 8) {
      throw Exception('비밀번호는 8자 이상이어야 합니다.');
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: e,
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw Exception('회원가입에 실패했습니다. 다시 시도해 주세요.');
      }

      // 인증 메일 발송(간단 구성)
      await user.sendEmailVerification(
        ActionCodeSettings(
          url:
              'https://zerowaste-ccae3.firebaseapp.com/__/auth/action?mode=action&oobCode=code/verified',
          handleCodeInApp: false,
        ),
      );

      // 화면에서 "인증 확인" 후 로그인 → 서버 교환 진행
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('이미 사용 중인 이메일입니다.');
        case 'invalid-email':
          throw Exception('올바르지 않은 이메일 주소입니다.');
        case 'operation-not-allowed':
          throw Exception('현재 이메일/비밀번호 가입이 비활성화되어 있습니다.');
        case 'weak-password':
          throw Exception('비밀번호가 안전하지 않습니다. 더 복잡하게 설정해 주세요.');
        case 'network-request-failed':
          throw Exception('네트워크 오류가 발생했습니다. 연결을 확인해 주세요.');
        default:
          throw Exception('회원가입에 실패했습니다. (${e.code})');
      }
    }
  }

  /// 구글 로그인 → Firebase 성공 후 서버 교환
  Future<void> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) throw Exception('Google 로그인 취소됨');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    final idToken = await userCred.user?.getIdToken();
    if (idToken == null) throw Exception('ID 토큰 없음');

    await _authenticateWithServer(idToken); // 서버 교환 → access/refresh 저장
  }

  // ───────────────────────── 서버 토큰 교환/저장 ─────────────────────────

  /// Firebase ID 토큰을 서버로 보내 access/refresh 토큰을 교환/저장
  Future<void> _authenticateWithServer(String idToken) async {
    final resp = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('서버 로그인 실패: ${resp.statusCode}');
    }

    final decoded = _decode(resp.body);
    // ApiResponse 래퍼 대응: { "data": { accessToken, refreshToken, ... } }
    final data = decoded['data'] ?? decoded;
    final access = (data['accessToken'] ?? '').toString();
    final refresh = (data['refreshToken'] ?? '').toString();
    if (access.isEmpty || refresh.isEmpty) {
      throw Exception('토큰 발급 실패: 응답에 토큰이 없습니다.');
    }
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  /// (부트스트랩용) 이미 Firebase 로그인된 상태에서 서버 토큰 재교환
  Future<void> exchangeAndStoreTokens() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Firebase 로그인 상태가 아닙니다.');
    }
    final String? idToken = await user.getIdToken(true);
    if (idToken == null || idToken.isEmpty) {
      throw StateError('ID 토큰을 가져오지 못했습니다.');
    }

    await _authenticateWithServer(idToken);
  }

  // ───────────────────────── 자동 리프레시 ─────────────────────────

  /// 저장된 refreshToken으로 새 accessToken 발급 (성공 시 저장/반환)
  /// 서버가 refreshToken도 갱신해서 줄 수 있으니, 있으면 함께 교체
  Future<String?> refreshAccessToken() async {
    final refresh = await _storage.read(key: _kRefresh);
    if (refresh == null || refresh.isEmpty) return null;

    final resp = await http.post(
      Uri.parse('$_base/auth/refresh'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'refreshToken': refresh}),
    );

    if (resp.statusCode != 200) return null;

    final decoded = _decode(resp.body);
    final data = decoded['data'] ?? decoded;
    final newAccess = (data['accessToken'] ?? '').toString();
    final newRefresh = (data['refreshToken'] ?? '').toString();

    if (newAccess.isEmpty) return null;

    await _storage.write(key: _kAccess, value: newAccess);
    if (newRefresh.isNotEmpty) {
      await _storage.write(key: _kRefresh, value: newRefresh);
    }
    return newAccess;
  }

  // ───────────────────────── 세션/유틸 ─────────────────────────

  Future<String?> getAccessToken() => _storage.read(key: _kAccess);
  Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);

  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
    await _storage.deleteAll();
  }

  User? get currentUser => _auth.currentUser;

  Map<String, dynamic> _decode(String body) {
    try {
      final obj = jsonDecode(body);
      if (obj is Map<String, dynamic>) return obj;
      if (obj is Map) return Map<String, dynamic>.from(obj);
    } catch (_) {}
    return <String, dynamic>{};
  }
}
