import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/game_info.dart';
import '../../models/post_model.dart';
import '../../services/image_service.dart';
import '../../services/storage_service.dart';
import '../../services/post_service.dart';
import '../../core/constants/baseball_data.dart';
import '../../providers/auth_provider.dart';

/// 게시글 작성 화면
class PostCreateScreen extends StatefulWidget {
  final File ticketImage;
  final GameInfo gameInfo;

  const PostCreateScreen({
    super.key,
    required this.ticketImage,
    required this.gameInfo,
  });

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();

  final ImageService _imageService = ImageService();
  final StorageService _storageService = StorageService();
  final PostService _postService = PostService();

  List<File> _additionalPhotos = [];
  List<String> _tags = [];
  double _rating = 3.0;
  String _privacy = Privacy.private;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  /// 추가 사진 선택
  Future<void> _pickAdditionalPhotos() async {
    try {
      // 현재 사용자 정보 가져오기
      final authProvider = context.read<AuthProvider>();
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
      final currentPhotoCount = _additionalPhotos.length;

      // 제한 초과 체크
      if (currentPhotoCount >= maxPhotos) {
        if (!mounted) return;
        _showPhotoLimitDialog(currentUser.isPremium, maxPhotos);
        return;
      }

      final files = await _imageService.pickMultipleImages();

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
                    _additionalPhotos.addAll(files.take(availableSlots));
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
        _additionalPhotos.addAll(files);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 선택 실패: $e')),
      );
    }
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

  /// 추가 사진 삭제
  void _removeAdditionalPhoto(int index) {
    setState(() {
      _additionalPhotos.removeAt(index);
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

  /// 게시글 작성
  Future<void> _createPost() async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Firestore Document ID 먼저 생성 (Storage와 Firestore에서 동일 ID 사용)
      final postId = FirebaseFirestore.instance.collection('posts').doc().id;
      debugPrint('📝 생성된 postId: $postId');

      // 2. 티켓 이미지 업로드 (Firestore ID 사용)
      final ticketImageUrl = await _storageService.uploadTicketImage(
        imageFile: widget.ticketImage,
        userId: user.uid,
        postId: postId,
      );

      // 3. 추가 사진 업로드 (있는 경우)
      List<String> additionalPhotoUrls = [];
      if (_additionalPhotos.isNotEmpty) {
        additionalPhotoUrls = await _storageService.uploadAdditionalPhotos(
          imageFiles: _additionalPhotos,
          userId: user.uid,
          postId: postId,
          onProgress: (progress) {
            // TODO: 진행률 표시 (선택 사항)
          },
        );
      }

      // 4. Post 객체 생성
      final post = Post(
        id: postId,
        userId: user.uid,
        ticketImageUrl: ticketImageUrl,
        additionalPhotoUrls: additionalPhotoUrls,
        gameInfo: widget.gameInfo,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags,
        rating: _rating,
        privacy: _privacy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 5. Firestore에 저장
      await _postService.createPost(post);

      if (!mounted) return;

      // 6. 성공 메시지 및 화면 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 작성되었습니다')),
      );

      // 메인 화면으로 돌아가기 (true = 게시글 작성됨)
      // popUntil을 사용하여 /main 경로가 나올 때까지 pop
      Navigator.of(context).popUntil((route) {
        return route.settings.name == '/main' || route.isFirst;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 작성 실패: $e')),
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
        title: const Text('게시글 작성'),
        backgroundColor: colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 티켓 이미지 미리보기
                    _buildTicketPreview(colorScheme),

                    // 경기 정보 요약
                    _buildGameInfoSummary(colorScheme),

                    const Divider(height: 32),

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

                    // 게시 버튼
                    _buildSubmitButton(colorScheme),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  /// 티켓 이미지 미리보기
  Widget _buildTicketPreview(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          widget.ticketImage,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// 경기 정보 요약
  Widget _buildGameInfoSummary(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.stadium, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '경기 정보',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('날짜', widget.gameInfo.date?.toString().split(' ')[0] ?? '-'),
          _buildInfoRow('경기', '${widget.gameInfo.homeTeam ?? '-'} vs ${widget.gameInfo.awayTeam ?? '-'}'),
          _buildInfoRow('구장', widget.gameInfo.stadium ?? '-'),
          if (widget.gameInfo.seat != null)
            _buildInfoRow('좌석', widget.gameInfo.seat!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 제목 입력 필드
  Widget _buildTitleField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: _contentController,
        decoration: const InputDecoration(
          labelText: '본문 (선택)',
          hintText: '경기 관람 후기를 작성해보세요',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: 5,
        maxLength: 500,
      ),
    );
  }

  /// 추가 사진
  Widget _buildAdditionalPhotos(ColorScheme colorScheme) {
    // 현재 사용자의 사진 제한 가져오기
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final maxPhotos = currentUser?.maxPhotosPerPost ?? 3; // 기본값: 무료 사용자
    final isLimitReached = _additionalPhotos.length >= maxPhotos;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '추가 사진 (${_additionalPhotos.length}/$maxPhotos)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (currentUser != null && !currentUser.isPremium && maxPhotos == 3)
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
              TextButton.icon(
                onPressed: isLimitReached ? null : _pickAdditionalPhotos,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('사진 추가'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_additionalPhotos.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _additionalPhotos.length,
                itemBuilder: (context, index) {
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
                          child: Image.file(
                            _additionalPhotos[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () => _removeAdditionalPhoto(index),
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
                },
              ),
            ),
        ],
      ),
    );
  }

  /// 별점 선택
  Widget _buildRatingSelector(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
      ),
    );
  }

  /// 해시태그 입력
  Widget _buildTagInput(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
      ),
    );
  }

  /// 프라이버시 설정
  Widget _buildPrivacySelector(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
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
      ),
    );
  }

  /// 게시 버튼
  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _createPost,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            '게시하기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
