import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'report_list_screen.dart';

/// 공통 컬러 토큰 (지도/게시판과 통일)
const _kPrimary = Colors.green; // Kakao map FOOD_WASTE 초록(#43a047)
const _kBorderColor = Color(0xFFE0E0E0);
const _kRadius = 12.0;
const _kPadding = 16.0;

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromRGBO(56, 142, 60, 1), // ▶ 상단 헤더 초록색으로 통일
        elevation: 0,
        centerTitle: true,
        title: const Text('마이페이지', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(_kPadding, 12, _kPadding, 24),
        children: [
          // 프로필 헤더
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFF5F5F5),
                child: Text(
                  'JW',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ZeroWaste 사용자',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'user@example.com',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              // 프로필 편집(초록 포커스)
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: _kPrimary,
                ),
                label: const Text('편집', style: TextStyle(color: _kPrimary)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: const StadiumBorder(
                    side: BorderSide(color: _kBorderColor, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 포인트 카드 (보더형, 타이틀에 초록 강조점)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_kRadius),
              border: Border.all(color: _kBorderColor),
            ),
            padding: const EdgeInsets.all(_kPadding),
            child: Row(
              children: [
                const Expanded(child: _PointBlock()),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF5F5F5),
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    size: 22,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          // 섹션 타이틀(초록 라벨로 통일감)
          const _SectionLabel('내 활동'),
          const SizedBox(height: 8),

          _ListTileCard(
            leading: const Icon(Icons.report_outlined, color: _kPrimary),
            title: '제보 내역',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyReportsScreen()),
              );
            },
          ),
          const SizedBox(height: 10),

          _ListTileCard(
            leading: const Icon(Icons.bookmark_outline, color: _kPrimary),
            title: '북마크',
            onTap: () {
              // TODO: 북마크 화면 연결
            },
          ),

          const SizedBox(height: 24),
          const _SectionLabel('앱 설정'),
          const SizedBox(height: 8),

          _ListTileCard(
            leading: const Icon(Icons.settings_outlined, color: _kPrimary),
            title: '설정',
            trailing: const Icon(Icons.chevron_right, color: Colors.black45),
            onTap: () {
              // TODO: 설정 화면 연결
            },
          ),
          const SizedBox(height: 10),

          _ListTileCard(
            leading: const Icon(Icons.logout_outlined, color: Colors.black87),
            title: '로그아웃',
            titleStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            onTap: () async {
              await AuthService().signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('로그아웃 되었습니다.')));
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 위젯들 ─────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 4,
          height: 16,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}

class _PointBlock extends StatelessWidget {
  const _PointBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        // 타이틀에 초록 포인트 도트
        Row(
          children: [
            Icon(Icons.circle, size: 6, color: _kPrimary),
            SizedBox(width: 6),
            Text('내 포인트', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 4),
        Text(
          '1,240 pt',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// 보더형 리스트 타일(라운드/보더/아이콘 컬러를 초록 톤으로 통일)
class _ListTileCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final TextStyle? titleStyle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ListTileCard({
    required this.leading,
    required this.title,
    this.titleStyle,
    this.trailing = const Icon(Icons.chevron_right, color: Colors.black45),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_kRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_kRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kRadius),
            border: Border.all(color: _kBorderColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            minLeadingWidth: 0,
            dense: true,
            leading: leading,
            title: Text(
              title,
              style: titleStyle ?? const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: trailing,
          ),
        ),
      ),
    );
  }
}
