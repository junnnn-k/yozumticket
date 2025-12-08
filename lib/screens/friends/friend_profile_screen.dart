import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../services/friend_service.dart';
import '../../providers/auth_provider.dart';

/// 친구 프로필 화면
class FriendProfileScreen extends StatefulWidget {
  final UserModel friend;

  const FriendProfileScreen({
    super.key,
    required this.friend,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final PostService _postService = PostService();
  final FriendService _friendService = FriendService();

  List<Post> _friendPosts = [];
  int _postCount = 0;
  int _friendCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendData();
  }

  /// 친구 데이터 로드
  Future<void> _loadFriendData() async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _postService.getFriendPosts(widget.friend.uid, currentUser.uid),
        _postService.getFriendPostCount(widget.friend.uid),
        _friendService.getFriendCount(widget.friend.uid),
      ]);

      setState(() {
        _friendPosts = results[0] as List<Post>;
        _postCount = results[1] as int;
        _friendCount = results[2] as int;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 친구 삭제
  Future<void> _removeFriend() async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('${widget.friend.username}님을 친구 목록에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final friendship = await _friendService.checkFriendship(
        currentUser.uid,
        widget.friend.uid,
      );

      if (friendship != null) {
        await _friendService.removeFriend(friendship.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('친구를 삭제했습니다.'),
              backgroundColor: Colors.orange,
            ),
          );
          // 이전 화면으로 돌아가기
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // AppBar with profile header
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primaryContainer,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // 프로필 이미지
                            CircleAvatar(
                              radius: 50,
                              backgroundImage:
                                  widget.friend.profileImageUrl.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          widget.friend.profileImageUrl,
                                        )
                                      : null,
                              child: widget.friend.profileImageUrl.isEmpty
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            // 사용자 이름
                            Text(
                              widget.friend.username,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'remove') {
                          _removeFriend();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.person_remove, color: Colors.red),
                              SizedBox(width: 8),
                              Text('친구 삭제',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Profile info
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 통계
                        _buildStatsRow(),
                        const SizedBox(height: 16),

                        // 응원팀
                        if (widget.friend.favoriteTeams.isNotEmpty) ...[
                          _buildInfoSection(
                            '응원팀',
                            widget.friend.favoriteTeams.join(', '),
                            Icons.sports_baseball,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 자기소개
                        if (widget.friend.bio.isNotEmpty) ...[
                          _buildInfoSection(
                            '자기소개',
                            widget.friend.bio,
                            Icons.info_outline,
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          const SizedBox(height: 12),
                        ],

                        // 공유 아카이브 버튼 (향후 구현)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('공유 아카이브 기능은 추후 구현 예정입니다.'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.folder_shared),
                            label: const Text('공유 아카이브 만들기'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // 게시글 섹션 헤더
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '최근 게시글',
                              style: theme.textTheme.titleLarge,
                            ),
                            if (_postCount > 0)
                              Text(
                                '$_postCount개',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // 게시글 목록
                _friendPosts.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '공개된 게시글이 없습니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final post = _friendPosts[index];
                              return _PostCard(post: post);
                            },
                            childCount: _friendPosts.length,
                          ),
                        ),
                      ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            ),
    );
  }

  /// 통계 행 위젯
  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('게시글', _postCount),
        Container(
          width: 1,
          height: 40,
          color: Colors.grey[300],
        ),
        _buildStatItem('친구', _friendCount),
      ],
    );
  }

  /// 통계 아이템 위젯
  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 정보 섹션 위젯
  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 게시글 카드 위젯
class _PostCard extends StatelessWidget {
  final Post post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/post-detail/${post.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 티켓 이미지
            if (post.ticketImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
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
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // 경기 정보
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        post.gameInfo.date != null
                            ? DateFormat('yyyy-MM-dd').format(post.gameInfo.date!)
                            : '날짜 미정',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.stadium, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.gameInfo.stadium ?? '구장 정보 없음',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  if (post.gameInfo.homeTeam != null &&
                      post.gameInfo.awayTeam != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${post.gameInfo.homeTeam} vs ${post.gameInfo.awayTeam}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],

                  // 별점
                  if (post.rating > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < post.rating
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
