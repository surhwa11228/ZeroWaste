import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/board_service.dart';
import '../models/board_models.dart';

class BoardWriteScreen extends StatefulWidget {
  final String boardName;
  const BoardWriteScreen({super.key, required this.boardName});

  @override
  State<BoardWriteScreen> createState() => _BoardWriteScreenState();
}

class _BoardWriteScreenState extends State<BoardWriteScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _svc = BoardService.instance;

  String _category = '질문';
  File? _image;

  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  // ----- 이미지 선택 (단일) -----

  Future<void> _pickFromGallery() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (x == null) return;
      if (!mounted) return;
      setState(() => _image = File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('사진 선택 실패: $e')));
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (x == null) return;
      if (!mounted) return;
      setState(() => _image = File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('카메라 촬영 실패: $e')));
    }
  }

  Future<void> _showImageSheet() async {
    if (_saving) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('앨범에서 선택'),
              onTap: () async {
                Navigator.pop(context);
                await _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('카메라로 촬영'),
              onTap: () async {
                Navigator.pop(context);
                await _pickFromCamera();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('닫기'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // ----- 전송 -----

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final draft = PostRequest(
        title: _title.text.trim(),
        content: _content.text.trim(),
        category: _category,
      );

      final result = await _svc.create(
        boardName: widget.boardName,
        draft: draft,
        images: _image != null ? <File>[_image!] : null,
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('게시글이 작성되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('게시글 작성에 실패하였습니다. 에러코드: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _saving = false);
    }
  }

  // ----- UI -----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('글쓰기')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    items: const [
                      DropdownMenuItem(value: '제보', child: Text('제보')),
                      DropdownMenuItem(value: '질문', child: Text('질문')),
                      DropdownMenuItem(value: '기타', child: Text('기타')),
                    ],
                    onChanged: (v) => setState(() => _category = v ?? '질문'),
                    decoration: const InputDecoration(
                      labelText: '카테고리',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('등록'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 제목
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
            ),
            const SizedBox(height: 12),

            _BodyWithToolbar(
              controller: _content,
              onTapAddPhoto: _showImageSheet,
              enabled: !_saving,
            ),
            const SizedBox(height: 12),

            // 선택된 이미지 미리보기
            if (_image != null) ...[
              Row(
                children: [
                  Text(
                    '첨부 사진 (1/1)',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _image = null),
                    icon: const Icon(Icons.clear),
                    label: const Text('지우기'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _BodyWithToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTapAddPhoto;
  final bool enabled;
  const _BodyWithToolbar({
    required this.controller,
    required this.onTapAddPhoto,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 툴바
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 44,
          child: Row(
            children: [
              IconButton(
                tooltip: '사진 추가 (1장)',
                onPressed: enabled ? onTapAddPhoto : null,
                icon: const Icon(Icons.add_a_photo_outlined),
              ),
              const VerticalDivider(width: 8),
              const Text('본문'),
              const Spacer(),
            ],
          ),
        ),
        // 본문 입력
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            minLines: 8,
            maxLines: 16,
            decoration: const InputDecoration(
              hintText: '내용을 입력하세요',
              contentPadding: EdgeInsets.all(12),
              border: InputBorder.none,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? '내용을 입력하세요' : null,
          ),
        ),
      ],
    );
  }
}
