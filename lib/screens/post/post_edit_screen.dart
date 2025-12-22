import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../services/image_service.dart';
import '../../services/storage_service.dart';
import '../../services/post_service.dart';
import '../../core/constants/moods.dart';
import '../../providers/auth_provider.dart' as app_auth;

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
  final _titleFieldKey = GlobalKey(); // 제목 필드 스크롤용

  final ImageService _imageService = ImageService();
  final StorageService _storageService = StorageService();
  final PostService _postService = PostService();

  // 썸네일
  String? _existingThumbnailUrl; // 기존 썸네일 URL
  File? _newThumbnail; // 새로 선택한 썸네일
  bool _thumbnailDeleted = false; // 썸네일 삭제 여부

  // 기존 추가 사진 URL (수정하지 않음)
  List<String> _existingPhotoUrls = [];
  // 새로 추가할 사진 파일
  List<File> _newAdditionalPhotos = [];
  // 삭제할 사진 URL
  List<String> _deletedPhotoUrls = [];

  late List<String> _tags;
  late String _mood; // 기분 이모지
  late String _privacy;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 기존 데이터 불러오기
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _mood = widget.post.mood;
    _privacy = widget.post.privacy;
    _existingThumbnailUrl = widget.post.thumbnailUrl;
    _existingPhotoUrls = List.from(widget.post.additionalPhotoUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 새 추가 사진 선택
  Future<void> _pickAdditionalPhotos() async {
    try {
      // 현재 사용자 정보 가져오기
      final authProvider = context.read<app_auth.AuthProvider>();
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자 정보를 불러올 수 없습니다')),
        );
        return;
      }

      // 사용자별 사진 제한 (무료: 3장, 프리미엄: 20장)
      final maxPhotos = currentUser.maxPhotosPerPost;
      final currentPhotoCount = _existingPhotoUrls.length + _newAdditionalPhotos.length;

      // 제한 초과 체크
      if (currentPhotoCount >= maxPhotos) {
        if (!mounted) return;
        _showPhotoLimitDialog(currentUser.isPremium, maxPhotos);
        return;
      }

      final files = await _imageService.pickMultipleImages(context: context);

      if (files.isEmpty) return;

      // 추가 후 총 개수 체크
      final totalPhotos = currentPhotoCount + files.length;
      if (totalPhotos > maxPhotos) {
        if (!mounted) return;

        // 일부만 추가 가능한 경우
        final availableSlots = maxPhotos - currentPhotoCount;
        if (availableSlots > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$availableSlots장만 추가할 수 있습니다 (최대: $maxPhotos장)'),
              action: SnackBarAction(
                label: '일부 추가',
                onPressed: () {
                  setState(() {
                    _newAdditionalPhotos.addAll(files.take(availableSlots));
                  });
                },
              ),
            ),
          );
        } else {
          _showPhotoLimitDialog(currentUser.isPremium, maxPhotos);
        }
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

  /// 썸네일 선택
  Future<void> _pickThumbnail() async {
    try {
      final file = await _imageService.showImageSourceDialog(context);

      if (file == null) return;

      setState(() {
        _newThumbnail = file;
        _thumbnailDeleted = false; // 새 썸네일 선택 시 삭제 플래그 해제
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('썸네일 선택 실패: $e')),
      );
    }
  }

  /// 썸네일 삭제
  void _removeThumbnail() {
    setState(() {
      _newThumbnail = null;
      _thumbnailDeleted = true;
    });
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

  /// 사진 제한 다이얼로그 표시
  void _showPhotoLimitDialog(bool isPremium, int maxPhotos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사진 제한'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPremium
                  ? '사진은 최대 $maxPhotos장까지 추가할 수 있습니다.'
                  : '무료 사용자는 사진을 최대 $maxPhotos장까지 추가할 수 있습니다.',
              style: const TextStyle(fontSize: 16),
            ),
            if (!isPremium) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '프리미엄 혜택',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '프리미엄 구독 시 최대 20장까지 사진을 추가할 수 있습니다.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
          if (!isPremium)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: 프리미엄 구독 화면으로 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('프리미엄 구독 화면 (준비 중)')),
                );
              },
              child: const Text('프리미엄 보기'),
            ),
        ],
      ),
    );
  }

  /// 필드로 스크롤
  void _scrollToField(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.2, // 화면 상단에서 20% 위치
      );
    }
  }

  /// 게시글 수정
  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) {
      // 필수 항목 미입력 시 제목 필드로 스크롤
      _scrollToField(_titleFieldKey);
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
      // 1. 기존 썸네일 삭제 (삭제 플래그가 설정되었거나 새 썸네일로 교체하는 경우)
      if (_existingThumbnailUrl != null &&
          (_thumbnailDeleted || _newThumbnail != null)) {
        try {
          await _storageService.deleteImage(_existingThumbnailUrl!);
        } catch (e) {
          debugPrint('썸네일 삭제 실패: $_existingThumbnailUrl - $e');
        }
      }

      // 2. 삭제된 추가 사진 Storage에서 삭제
      for (final url in _deletedPhotoUrls) {
        try {
          await _storageService.deleteImage(url);
        } catch (e) {
          debugPrint('사진 삭제 실패: $url - $e');
        }
      }

      // 3. 새 썸네일 업로드
      String? updatedThumbnailUrl;
      if (_newThumbnail != null) {
        updatedThumbnailUrl = await _storageService.uploadThumbnail(
          userId: user.uid,
          postId: widget.post.id,
          imageFile: _newThumbnail!,
        );
      } else if (!_thumbnailDeleted && _existingThumbnailUrl != null) {
        // 기존 썸네일 유지
        updatedThumbnailUrl = _existingThumbnailUrl;
      }
      // _thumbnailDeleted == true 이고 _newThumbnail == null 이면 updatedThumbnailUrl은 null

      // 4. 새 추가 사진 업로드
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

      // 5. 최종 additionalPhotoUrls 합치기
      final updatedPhotoUrls = [..._existingPhotoUrls, ...newPhotoUrls];

      // 6. Post 객체 업데이트
      final updatedPost = widget.post.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        // tags는 기존 값 유지 (태그 기능 제거)
        mood: _mood,
        privacy: _privacy,
        thumbnailUrl: updatedThumbnailUrl,
        additionalPhotoUrls: updatedPhotoUrls,
        updatedAt: DateTime.now(),
      );

      // 7. Firestore에 저장
      await _postService.updatePost(updatedPost);

      if (!mounted) return;

      // 8. 성공 메시지 및 화면 닫기
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

                      // 썸네일 선택
                      _buildThumbnailSelector(colorScheme),
                      const SizedBox(height: 16),

                      // 추가 사진
                      _buildAdditionalPhotos(colorScheme),
                      const SizedBox(height: 16),

                      // 기분 선택
                      _buildMoodSelector(colorScheme),
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
    return Container(
      key: _titleFieldKey, // 스크롤용 키 추가
      child: TextFormField(
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
      ),
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

  /// 썸네일 선택
  Widget _buildThumbnailSelector(ColorScheme colorScheme) {
    // 표시할 썸네일 결정
    final bool hasThumbnail = _newThumbnail != null ||
        (_existingThumbnailUrl != null && !_thumbnailDeleted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  '썸네일 선택 (선택사항)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '선택하지 않으면 티켓 사진이 썸네일로 사용됩니다',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        if (hasThumbnail)
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _newThumbnail != null
                      ? Image.file(
                          _newThumbnail!,
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: _existingThumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _removeThumbnail,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: _pickThumbnail,
            icon: const Icon(Icons.image),
            label: const Text('썸네일 선택'),
          ),
      ],
    );
  }

  /// 추가 사진
  Widget _buildAdditionalPhotos(ColorScheme colorScheme) {
    final totalPhotos = _existingPhotoUrls.length + _newAdditionalPhotos.length;

    // 사용자별 사진 제한 가져오기
    final authProvider = context.read<app_auth.AuthProvider>();
    final currentUser = authProvider.currentUser;
    final maxPhotos = currentUser?.maxPhotosPerPost ?? 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '추가 사진 ($totalPhotos/$maxPhotos)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: totalPhotos >= maxPhotos ? null : _pickAdditionalPhotos,
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

  /// 기분 이모지 선택
  Widget _buildMoodSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '경기 어떠셨나요?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: Moods.all.map((mood) {
            final isSelected = _mood == mood;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _mood = mood;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      Moods.getEmoji(mood),
                      style: TextStyle(
                        fontSize: isSelected ? 36 : 32,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Moods.getLabel(mood),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
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
