import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.email});
  final String? email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isSending = false;
  bool _isChecking = false;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 5);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown -= 1);
      }
    });
  }

  // ▼ 재전송 에러 메시지 실서비스화
  String _mapResendError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'network-request-failed':
          return '네트워크 연결에 문제가 있어요. 잠시 후 다시 시도해 주세요.';
        case 'too-many-requests':
          return '요청이 너무 많아요. 잠시 후 다시 시도해 주세요.';
        case 'requires-recent-login':
          return '보안을 위해 다시 로그인 후 시도해 주세요.';
        default:
          return '메일 재전송에 실패했어요. 잠시 후 다시 시도해 주세요. (코드: ${e.code})';
      }
    }
    final msg = e.toString();
    if (msg.contains('timeout')) {
      return '요청이 지연되고 있어요. 네트워크 상태를 확인해 주세요.';
    }
    return '메일 재전송에 실패했어요. 잠시 후 다시 시도해 주세요.';
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    setState(() => _isSending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다.');

      await user.sendEmailVerification(
        ActionCodeSettings(
          url:
              'https://zerowaste-ccae3.firebaseapp.com/__/auth/action?mode=action&oobCode=code/verified',
          handleCodeInApp: false,
        ),
      );

      if (!mounted) return;
      // 성공 메시지 + “메일 앱 열기” 액션 통일
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('인증 메일을 다시 보냈어요. 메일함을 확인해 주세요.'),
          action: SnackBarAction(label: '메일 앱 열기', onPressed: _openMailApp),
        ),
      );
      _startCooldown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mapResendError(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _check() async {
    setState(() => _isChecking = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final verified =
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      if (!mounted) return;
      if (verified) {
        Navigator.pushReplacementNamed(context, '/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 인증이 완료되었습니다. 로그인해 주세요.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아직 인증되지 않았어요. 메일의 링크를 눌러 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _openMailApp() async {
    final candidates = [
      Uri.parse('mailto:'), // 기본 메일 작성
      Uri.parse('message://'), // iOS Mail
      Uri.parse('googlegmail://'), // Gmail
    ];
    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('메일 앱을 열 수 없어요. 브라우저에서 메일을 확인해 주세요.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email =
        widget.email ?? FirebaseAuth.instance.currentUser?.email ?? '';
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('이메일 인증')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 긴 제목도 안전
              Text(
                '인증 메일을 보냈어요',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // 이메일은 복사하기 편하게
              SelectableText(
                '아래 주소로 전송된 메일의 링크를 눌러 인증을 완료해 주세요.\n$email',
                style: tt.bodyMedium,
              ),

              const SizedBox(height: 24),

              // ▼ 버튼 가로폭 좁을 때 자동 줄바꿈(텍스트 오버플로우 해결)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSending || _cooldown > 0 ? null : _resend,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _cooldown > 0 ? '재전송 (${_cooldown}s)' : '인증 메일 재전송',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openMailApp,
                    icon: const Icon(Icons.mail),
                    label: const Text('메일 앱 열기'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _check,
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('인증 완료'),
                ),
              ),

              const Spacer(),
              Text(
                'TIP) 스팸함/프로모션함도 확인해 보세요. 링크는 일정 시간이 지나면 만료될 수 있습니다.',
                style: tt.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
