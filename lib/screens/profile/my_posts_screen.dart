import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/ad_config.dart';
import '../../core/constants/moods.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../providers/auth_provider.dart' as auth;
import '../../widgets/ads/ad_banner_card.dart';

/// 내 게시글 목록 화면
class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  /// 게시글 목록 로드
  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final posts = await _postService.getMyPosts(user.uid, limit: 50);
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '로그인이 필요합니다';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '게시글을 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 총 아이템 개수 계산 (게시물 + 광고)
  int _calculateItemCount(int postCount,
      {required bool isPremium, required bool showAds}) {
    if (isPremium || !showAds) {
      return postCount;
    }
    // 7개당 1개 광고 삽입
    final adCount = (postCount / AdConfig.bannerAdInterval).floor();
    return postCount + adCount;
  }

  /// 해당 인덱스가 광고 위치인지 확인
  bool _isAdPosition(int index) {
    // 7, 15, 23, 31, ... 위치에 광고 표시 (7개마다)
    return (index + 1) % (AdConfig.bannerAdInterval + 1) == 0;
  }

  /// 광고 번호 계산
  int _getAdPosition(int index) {
    return (index / (AdConfig.bannerAdInterval + 1)).floor();
  }

  /// 실제 게시물 인덱스 계산
  int _getPostIndex(int index) {
    // 광고를 제외한 실제 게시물 인덱스
    final adCount = (index / (AdConfig.bannerAdInterval + 1)).floor();
    return index - adCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 게시글'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPosts,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : _posts.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '아직 작성한 게시글이 없습니다',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '첫 경기 관람을 기록해보세요!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: Consumer<auth.AuthProvider>(
                        builder: (context, authProvider, _) {
                          final isPremium =
                              authProvider.currentUser?.isPremium ?? false;
                          final showAds =
                              authProvider.currentUser?.showBannerAds ?? true;

                          return ListView.builder(
                            padding: const EdgeInsets.all(AppSizes.md),
                            itemCount: _calculateItemCount(_posts.length,
                                isPremium: isPremium, showAds: showAds),
                            itemBuilder: (context, index) {
                              // 광고 표시 여부 및 위치 계산
                              if (!isPremium &&
                                  showAds &&
                                  _isAdPosition(index)) {
                                final adPosition = _getAdPosition(index);
                                return AdBannerCard(
                                  position: adPosition,
                                  isPremium: isPremium,
                                );
                              }

                              // 실제 게시물 인덱스 계산
                              final postIndex = !isPremium && showAds
                                  ? _getPostIndex(index)
                                  : index;

                              if (postIndex >= _posts.length) {
                                return const SizedBox.shrink();
                              }

                              final post = _posts[postIndex];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSizes.md),
                                child: _PostCard(
                                  post: post,
                                  onDeleted: _loadPosts,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

/// 게시글 카드
class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onDeleted;

  const _PostCard({
    required this.post,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy.MM.dd');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: InkWell(
        onTap: () async {
          await context.push('/post-detail/${post.id}');
          // 상세 화면에서 돌아온 후 목록 새로고침
          onDeleted();
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 티켓 이미지
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusMd),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: post.ticketImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, size: 48),
                  ),
                ),
              ),
            ),

            // 내용
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // 경기 정보
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.gameInfo.date != null
                            ? dateFormat.format(post.gameInfo.date!)
                            : '날짜 없음',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.sports_baseball,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${post.gameInfo.homeTeam} vs ${post.gameInfo.awayTeam}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // 구장 정보
                  Row(
                    children: [
                      Icon(
                        Icons.stadium,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.gameInfo.stadium ?? '구장 정보 없음',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      // 무드
                      Row(
                        children: [
                          Icon(
                            Moods.getIcon(post.mood),
                            size: 16,
                            color: Moods.getColor(post.mood),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            Moods.labels[post.mood] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Moods.getColor(post.mood),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
