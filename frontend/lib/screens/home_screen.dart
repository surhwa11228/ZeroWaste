import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'map_screen.dart';
import 'report_list_screen.dart';
import 'mypage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [MapScreen(), ReportListScreen(), MyPageScreen()];

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_selectedIndex) {
          0 => '지도',
          1 => '제보내역',
          _ => '마이페이지',
        }),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              tooltip: '필터',
              onPressed: () => _openFilterSheet(context),
              icon: const Icon(Icons.filter_alt_outlined),
            ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: '지도'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: '제보내역'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: '마이페이지',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/report'),
              icon: const Icon(Icons.add_location_alt),
              label: const Text('제보하기'),
            )
          : null,
    );
  }

  // 필터 바텀시트
  Future<void> _openFilterSheet(BuildContext context) async {
    String status = '전체'; // 전체, 대기중, 승인됨, 거절됨
    String period = '전체 기간'; // 오늘, 이번 주, 이번 달, 전체 기간

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final viewInsets = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + viewInsets),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined),
                      const SizedBox(width: 8),
                      Text(
                        '필터',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            status = '전체';
                            period = '전체 기간';
                          });
                        },
                        child: const Text('초기화'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('상태', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in ['전체', '대기중', '승인됨', '거절됨'])
                        ChoiceChip(
                          label: Text(s),
                          selected: status == s,
                          onSelected: (_) => setModalState(() => status = s),
                          selectedColor: AppColors.greenLight,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: status == s ? Colors.black : Colors.black87,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('기간', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in ['오늘', '이번 주', '이번 달', '전체 기간'])
                        ChoiceChip(
                          label: Text(p),
                          selected: period == p,
                          onSelected: (_) => setModalState(() => period = p),
                          selectedColor: AppColors.greenLight,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            color: period == p ? Colors.black : Colors.black87,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('적용됨 • 상태: $status, 기간: $period'),
                              ),
                            );
                          },
                          child: const Text('적용'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
