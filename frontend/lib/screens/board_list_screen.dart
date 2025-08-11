import 'package:flutter/material.dart';

class BoardListScreen extends StatelessWidget {
  const BoardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시판')),
      body: const Center(child: Text('게시판 목록이 여기에 표시됩니다.')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('글쓰기: 다음 단계에서 연결')));
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
