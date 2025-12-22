import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/image_viewer.dart';
import '../../core/constants/moods.dart';

/// 게시글 상세 보기 화면
class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final PostService _postService = PostService();
  final StorageService _storageService = StorageService();

  Post? _post;
  bool _isLoading = true;
  String? _error;
  bool _wasModified = false; // 수정 여부 추적

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  /// 게시글 불러오기
  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final post = await _postService.getPost(widget.postId);

      if (!mounted) return;

      if (post == null) {
        setState(() {
          _error = '게시글을 찾을 수 없습니다';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '게시글을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 게시글 삭제
  Future<void> _deletePost() async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말 이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      debugPrint('🗑️ 게시글 삭제 시작: postId=${_post!.id}, userId=${_post!.userId}');

      // Storage에서 이미지 삭제
      debugPrint('📦 Storage 이미지 삭제 시도...');
      await _storageService.deletePostImages(
        userId: _post!.userId,
        postId: _post!.id,
      );
      debugPrint('✅ Storage 이미지 삭제 완료');

      // Firestore에서 게시글 삭제
      debugPrint('📄 Firestore 게시글 삭제 시도...');
      await _postService.deletePost(_post!.id);
      debugPrint('✅ Firestore 게시글 삭제 완료');

      if (!mounted) return;

      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      // 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다')),
      );

      // 이전 화면으로 이동
      Navigator.pop(context, true); // true = 삭제됨
    } catch (e) {
      if (!mounted) return;

      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  /// 본인 게시글 여부 확인
  bool get _isMyPost {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && _post != null && user.uid == _post!.userId;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false, // 뒤로가기를 직접 제어
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // 뒤로가기 버튼이나 제스처로 나갈 때 수정 여부 전달
          Navigator.pop(context, _wasModified);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('게시글'),
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // 수정되었으면 true 반환
              Navigator.pop(context, _wasModified);
            },
          ),
          actions: _isMyPost
            ? [
                // 수정 버튼
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await context.push('/post-edit', extra: _post);
                    // 수정 완료 시 게시글 새로고침 및 플래그 설정
                    if (result == true && mounted) {
                      _wasModified = true;
                      _loadPost();
                    }
                  },
                ),
                // 삭제 버튼
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deletePost,
                ),
              ]
            : null,
      ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorView()
                : _post == null
                    ? const Center(child: Text('게시글을 찾을 수 없습니다'))
                    : _buildPostDetail(colorScheme),
      ),
    );
  }

  /// 에러 뷰
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? '오류가 발생했습니다'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPost,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  /// 게시글 상세 뷰
  Widget _buildPostDetail(ColorScheme colorScheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 티켓 이미지
          _buildTicketImage(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                _buildTitle(colorScheme),
                const SizedBox(height: 8),

                // 작성일, 별점
                _buildMetadata(colorScheme),
                const SizedBox(height: 16),

                // 경기 정보
                _buildGameInfo(colorScheme),
                const SizedBox(height: 16),

                // 본문
                if (_post!.content.isNotEmpty) ...[
                  _buildContent(colorScheme),
                  const SizedBox(height: 16),
                ],

                // 추가 사진
                if (_post!.additionalPhotoUrls.isNotEmpty) ...[
                  _buildAdditionalPhotos(colorScheme),
                  const SizedBox(height: 16),
                ],

                // 해시태그
                if (_post!.tags.isNotEmpty) ...[
                  _buildTags(colorScheme),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 티켓 이미지
  Widget _buildTicketImage() {
    return GestureDetector(
      onTap: () {
        // 모든 이미지 URL 리스트 (티켓 이미지 + 추가 사진)
        final allImages = [
          _post!.ticketImageUrl,
          ..._post!.additionalPhotoUrls,
        ];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewer(
              imageUrls: allImages,
              initialIndex: 0, // 티켓 이미지부터 시작
            ),
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: _post!.ticketImageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error, size: 48),
          ),
        ),
      ),
    );
  }

  /// 제목
  Widget _buildTitle(ColorScheme colorScheme) {
    return Text(
      _post!.title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  /// 메타데이터 (작성일, 별점)
  Widget _buildMetadata(ColorScheme colorScheme) {
    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');

    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          dateFormat.format(_post!.createdAt),
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        Text(
          Moods.getEmoji(_post!.mood),
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 4),
        Text(
          Moods.getLabel(_post!.mood),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        // 공개 범위
        _buildPrivacyBadge(colorScheme),
      ],
    );
  }

  /// 공개 범위 뱃지
  Widget _buildPrivacyBadge(ColorScheme colorScheme) {
    final label = Privacy.labels[_post!.privacy] ?? '';
    IconData icon;
    Color color;

    switch (_post!.privacy) {
      case Privacy.private:
        icon = Icons.lock;
        color = Colors.grey;
        break;
      case Privacy.friends:
        icon = Icons.people;
        color = Colors.blue;
        break;
      default:
        icon = Icons.lock;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// 경기 정보
  Widget _buildGameInfo(ColorScheme colorScheme) {
    return Container(
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
          _buildInfoRow('날짜', _post!.gameInfo.date?.toString().split(' ')[0] ?? '-'),
          _buildInfoRow('경기', '${_post!.gameInfo.homeTeam ?? '-'} vs ${_post!.gameInfo.awayTeam ?? '-'}'),
          _buildInfoRow('구장', _post!.gameInfo.stadium ?? '-'),
          if (_post!.gameInfo.seatGrade != null || _post!.gameInfo.seat != null)
            _buildInfoRow(
              '좌석',
              '${_post!.gameInfo.seatGrade ?? ''} ${_post!.gameInfo.seat ?? ''}'.trim(),
            ),
          if (_post!.gameInfo.price != null)
            _buildInfoRow('가격', '${NumberFormat('#,###').format(_post!.gameInfo.price)}원'),
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

  /// 본문
  Widget _buildContent(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '관람 후기',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _post!.content,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  /// 추가 사진
  Widget _buildAdditionalPhotos(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '추가 사진 (${_post!.additionalPhotoUrls.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _post!.additionalPhotoUrls.length,
          itemBuilder: (context, index) {
            final url = _post!.additionalPhotoUrls[index];
            return GestureDetector(
              onTap: () {
                // 모든 이미지 URL 리스트 (티켓 이미지 + 추가 사진)
                final allImages = [
                  _post!.ticketImageUrl,
                  ..._post!.additionalPhotoUrls,
                ];

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageViewer(
                      imageUrls: allImages,
                      initialIndex: index + 1, // 클릭한 추가 사진부터 시작 (티켓 이미지 다음)
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 해시태그
  Widget _buildTags(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '태그',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _post!.tags.map((tag) {
            return Chip(
              label: Text(tag),
              backgroundColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
