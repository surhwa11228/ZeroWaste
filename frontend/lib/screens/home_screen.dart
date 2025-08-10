import 'package:flutter/material.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final _pages = const [
    MapScreen(),
    Placeholder(), // report_list_screen.dart 연결 예정
    Placeholder(), // mypage_screen.dart 연결 예정
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: '지도'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: '제보내역'),
          NavigationDestination(icon: Icon(Icons.person), label: '마이페이지'),
        ],
      ),
    );
  }
}
