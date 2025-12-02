import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/post_model.dart';
import '../../services/image_service.dart';
import '../../services/storage_service.dart';
import '../../services/post_service.dart';

/// 게시글 수정 화면
class PostEditScreen extends StatefulWidget {
  final Post post;

  const PostEditScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostEditScreen> createState() => _PostEditScreenState();
}

class _PostEditScreenState extends State<PostEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _tagController = TextEditingController();

  final ImageService _imageService = ImageService();
  final StorageService _storageService = StorageService();
  final PostService _postService = PostService();

  // 기존 추가 사진 URL (수정하지 않음)
  List<String> _existingPhotoUrls = [];
  // 새로 추가할 사진 파일
  List<File> _newAdditionalPhotos = [];
  // 삭제할 사진 URL
  List<String> _deletedPhotoUrls = [];

  late List<String> _tags;
  late double _rating;
  late String _privacy;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 기존 데이터 불러오기
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _tags = List.from(widget.post.tags);
    _rating = widget.post.rating;
    _privacy = widget.post.privacy;
    _existingPhotoUrls = List.from(widget.post.additionalPhotoUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  /// 새 추가 사진 선택
  Future<void> _pickAdditionalPhotos() async {
    try {
      final files = await _imageService.pickMultipleImages();

      if (files.isEmpty) return;

      // 최대 10장 제한
      final totalPhotos = _existingPhotoUrls.length + _newAdditionalPhotos.length + files.length;
      if (totalPhotos > 10) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('추가 사진은 최대 10장까지 가능합니다 (현재: ${_existingPhotoUrls.length + _newAdditionalPhotos.length}장)'),
          ),
        );
        return;
      }

      setState(() {
        _newAdditionalPhotos.addAll(files);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 선택 실패: $e')),
      );
    }
  }

  /// 기존 사진 삭제 (URL)
  void _removeExistingPhoto(int index) {
    setState(() {
      final url = _existingPhotoUrls[index];
      _deletedPhotoUrls.add(url);
      _existingPhotoUrls.removeAt(index);
    });
  }

  /// 새 사진 삭제 (File)
  void _removeNewPhoto(int index) {
    setState(() {
      _newAdditionalPhotos.removeAt(index);
    });
  }

  /// 태그 추가
  void _addTag() {
    final tag = _tagController.text.trim();

    if (tag.isEmpty) return;

    // # 자동 추가
    final formattedTag = tag.startsWith('#') ? tag : '#$tag';

    // 중복 체크
    if (_tags.contains(formattedTag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 추가된 태그입니다')),
      );
      return;
    }

    setState(() {
      _tags.add(formattedTag);
      _tagController.clear();
    });
  }

  /// 태그 삭제
  void _removeTag(int index) {
    setState(() {
      _tags.removeAt(index);
    });
  }

  /// 게시글 수정
  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 로그인 확인
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    // 본인 게시글 확인
    if (user.uid != widget.post.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('본인의 게시글만 수정할 수 있습니다')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 삭제된 사진 Storage에서 삭제
      for (final url in _deletedPhotoUrls) {
        try {
          await _storageService.deleteImage(url);
        } catch (e) {
          debugPrint('사진 삭제 실패: $url - $e');
        }
      }

      // 2. 새 추가 사진 업로드
      List<String> newPhotoUrls = [];
      if (_newAdditionalPhotos.isNotEmpty) {
        newPhotoUrls = await _storageService.uploadAdditionalPhotos(
          imageFiles: _newAdditionalPhotos,
          userId: user.uid,
          postId: widget.post.id,
          onProgress: (progress) {
            // TODO: 진행률 표시 (선택 사항)
          },
        );
      }

      // 3. 최종 additionalPhotoUrls 합치기
      final updatedPhotoUrls = [..._existingPhotoUrls, ...newPhotoUrls];

      // 4. Post 객체 업데이트
      final updatedPost = widget.post.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags,
        rating: _rating,
        privacy: _privacy,
        additionalPhotoUrls: updatedPhotoUrls,
        updatedAt: DateTime.now(),
      );

      // 5. Firestore에 저장
      await _postService.updatePost(updatedPost);

      if (!mounted) return;

      // 6. 성공 메시지 및 화면 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 수정되었습니다')),
      );

      Navigator.of(context).pop(true); // true = 수정됨
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 수정 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 수정'),
        backgroundColor: colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 티켓 이미지 (수정 불가)
                      _buildTicketImagePreview(colorScheme),
                      const SizedBox(height: 16),

                      // 제목 입력
                      _buildTitleField(),
                      const SizedBox(height: 16),

                      // 본문 입력
                      _buildContentField(),
                      const SizedBox(height: 16),

                      // 추가 사진
                      _buildAdditionalPhotos(colorScheme),
                      const SizedBox(height: 16),

                      // 별점 선택
                      _buildRatingSelector(colorScheme),
                      const SizedBox(height: 16),

                      // 해시태그
                      _buildTagInput(colorScheme),
                      const SizedBox(height: 16),

                      // 프라이버시 설정
                      _buildPrivacySelector(colorScheme),
                      const SizedBox(height: 32),

                      // 저장 버튼
                      _buildSubmitButton(colorScheme),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// 티켓 이미지 미리보기 (수정 불가)
  Widget _buildTicketImagePreview(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '티켓 이미지',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(수정 불가)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: widget.post.ticketImageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      ],
    );
  }

  /// 제목 입력 필드
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: '제목',
        hintText: '오늘의 경기 제목을 입력하세요',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '제목을 입력해주세요';
        }
        return null;
      },
      maxLength: 50,
    );
  }

  /// 본문 입력 필드
  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      decoration: const InputDecoration(
        labelText: '본문 (선택)',
        hintText: '경기 관람 후기를 작성해보세요',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
      maxLength: 500,
    );
  }

  /// 추가 사진
  Widget _buildAdditionalPhotos(ColorScheme colorScheme) {
    final totalPhotos = _existingPhotoUrls.length + _newAdditionalPhotos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '추가 사진 ($totalPhotos/10)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: totalPhotos >= 10 ? null : _pickAdditionalPhotos,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('사진 추가'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (totalPhotos > 0)
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // 기존 사진 (URL)
                ..._existingPhotoUrls.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  return _buildPhotoItem(
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                    onDelete: () => _removeExistingPhoto(index),
                    colorScheme: colorScheme,
                  );
                }),
                // 새 사진 (File)
                ..._newAdditionalPhotos.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return _buildPhotoItem(
                    child: Image.file(file, fit: BoxFit.cover),
                    onDelete: () => _removeNewPhoto(index),
                    colorScheme: colorScheme,
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoItem({
    required Widget child,
    required VoidCallback onDelete,
    required ColorScheme colorScheme,
  }) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: child,
          ),
        ),
        Positioned(
          top: 4,
          right: 12,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 별점 선택
  Widget _buildRatingSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '별점',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 8,
                label: _rating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 해시태그 입력
  Widget _buildTagInput(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '해시태그',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: '태그 입력 후 추가 버튼 클릭',
                  border: OutlineInputBorder(),
                  prefixText: '#',
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addTag,
              child: const Text('추가'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.asMap().entries.map((entry) {
              final index = entry.key;
              final tag = entry.value;
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeTag(index),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// 프라이버시 설정
  Widget _buildPrivacySelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '공개 범위',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ...Privacy.labels.entries.map((entry) {
          final value = entry.key;
          final label = entry.value;
          final description = Privacy.descriptions[value] ?? '';

          return RadioListTile<String>(
            value: value,
            groupValue: _privacy,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _privacy = newValue;
                });
              }
            },
            title: Text(label),
            subtitle: Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            contentPadding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }

  /// 저장 버튼
  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updatePost,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '수정 완료',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
