import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = AuthService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZeroWaste 홈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('사용자 정보 없음'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '환영합니다, ${user.name}님!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('지역: ${user.region}'),
                  Text('생년월일: ${user.birthDate}'),
                  const Divider(height: 32),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/report/form');
                    },
                    child: const Text('📸 제보 등록'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/map');
                    },
                    child: const Text('🗺 지도 보기'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/post');
                    },
                    child: const Text('📚 게시판'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/mypage');
                    },
                    child: const Text('👤 마이페이지'),
                  ),
                ],
              ),
            ),
    );
  }
}
