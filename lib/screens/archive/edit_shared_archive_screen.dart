/// 공유 아카이브 수정 화면
///
/// 생성자가 아카이브의 이름과 설명을 수정할 수 있는 화면입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/sizes.dart';
import '../../models/shared_archive_model.dart';
import '../../providers/shared_archives_provider.dart';

class EditSharedArchiveScreen extends StatefulWidget {
  final SharedArchive archive;

  const EditSharedArchiveScreen({
    super.key,
    required this.archive,
  });

  @override
  State<EditSharedArchiveScreen> createState() =>
      _EditSharedArchiveScreenState();
}

class _EditSharedArchiveScreenState extends State<EditSharedArchiveScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isSubmitting = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.archive.name);
    _descriptionController =
        TextEditingController(text: widget.archive.description);

    // 변경사항 추적
    _nameController.addListener(_checkChanges);
    _descriptionController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 변경사항 확인
  void _checkChanges() {
    final hasChanges = _nameController.text != widget.archive.name ||
        _descriptionController.text != widget.archive.description;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  /// 수정 내용 저장
  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final archivesProvider = context.read<SharedArchivesProvider>();
      final success = await archivesProvider.updateArchive(
        archiveId: widget.archive.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아카이브 정보가 수정되었습니다')),
        );
        Navigator.of(context).pop(true);
      } else {
        final error = archivesProvider.errorMessage ?? '알 수 없는 오류';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('아카이브 수정'),
        centerTitle: true,
        actions: [
          if (_isSubmitting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _hasChanges ? _handleUpdate : null,
              child: const Text(
                '저장',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            // 이름 입력
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '아카이브 이름',
                hintText: '예: 2024 시즌 관람 기록',
                prefixIcon: Icon(Icons.folder_shared),
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '아카이브 이름을 입력해주세요';
                }
                if (value.trim().length < 2) {
                  return '이름은 2자 이상이어야 합니다';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSizes.lg),

            // 설명 입력
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명 (선택사항)',
                hintText: '이 아카이브에 대한 설명을 입력하세요',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              maxLength: 200,
              validator: (value) {
                if (value != null && value.trim().length > 200) {
                  return '설명은 200자 이하여야 합니다';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSizes.xxl),

            // 안내 메시지
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '아카이브 정보를 수정하면 모든 멤버에게 반영됩니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // 저장 버튼 (하단)
            if (!_isSubmitting)
              ElevatedButton(
                onPressed: _hasChanges ? _handleUpdate : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
