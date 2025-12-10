import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/sizes.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../models/badge_model.dart' as badge_model;
import '../../services/post_service.dart';
import '../../services/friend_service.dart';
import '../../providers/auth_provider.dart' as auth;
import '../../providers/shared_archives_provider.dart';
import '../archive/archive_screen.dart';
import '../archive/shared_archives_list_screen.dart';

/// 메인 화면 (하단 탭 네비게이션)
/// 4개 탭: 홈, 기록, 친구, MY
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 홈 탭에 접근하기 위한 GlobalKey
  final GlobalKey<_HomeTabState> _homeTabKey = GlobalKey<_HomeTabState>();

  // 프로필 탭에 접근하기 위한 GlobalKey
  final GlobalKey<_ProfileTabState> _profileTabKey = GlobalKey<_ProfileTabState>();

  // 탭 화면 리스트
  late final List<Widget> _screens = [
    _HomeTab(
      key: _homeTabKey,
      onStatsNeedRefresh: () {
        // 게시글 삭제 시 프로필 탭 통계도 새로고침
        _profileTabKey.currentState?._loadStats();
      },
    ),
    const ArchiveScreen(),
    const _FriendsTab(),
    _ProfileTab(key: _profileTabKey),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.4),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: '기록',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: '친구',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'MY',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                // 티켓 업로드 화면으로 이동 (결과 대기)
                await context.push('/ticket-upload');
                // 돌아왔을 때 홈 탭 및 프로필 탭 새로고침
                _homeTabKey.currentState?._loadRecentPosts();
                _profileTabKey.currentState?._loadStats();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// 홈 탭
class _HomeTab extends StatefulWidget {
  final VoidCallback? onStatsNeedRefresh;

  const _HomeTab({super.key, this.onStatsNeedRefresh});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final PostService _postService = PostService();
  List<Post> _recentPosts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecentPosts();
  }

  /// 최근 게시글 불러오기
  Future<void> _loadRecentPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // 로그인하지 않은 경우 빈 리스트
        setState(() {
          _recentPosts = [];
          _isLoading = false;
        });
        return;
      }

      // 내 게시글 최대 5개
      final posts = await _postService.getMyPosts(user.uid, limit: 5);

      if (!mounted) return;

      setState(() {
        _recentPosts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '게시글을 불러오는데 실패했습니다';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('요즘티켓'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () {
              context.push('/theme-preview');
            },
            tooltip: '테마 변경',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 알림 화면으로 이동
            },
            tooltip: '알림',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecentPosts,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            // 환영 메시지
            _WelcomeCard(),
            const SizedBox(height: AppSizes.lg),

            // 빠른 추가 버튼
            _QuickAddCard(),
            const SizedBox(height: AppSizes.lg),

            // 최근 기록 섹션
            _SectionHeader(title: '최근 관람한 경기'),
            const SizedBox(height: AppSizes.md),

            // 최근 게시글 리스트
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRecentPosts,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_recentPosts.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '아직 기록한 경기가 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '티켓을 추가해서 첫 기록을 남겨보세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._recentPosts.map((post) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: _TicketCard(
                    post: post,
                    onPostDeleted: () {
                      _loadRecentPosts();
                      widget.onStatsNeedRefresh?.call();
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// 환영 카드
class _WelcomeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '안녕하세요! 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            '오늘도 좋은 경기 되세요!',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// 빠른 추가 카드
class _QuickAddCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        context.push('/ticket-upload');
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: theme.colorScheme.secondary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '새 경기 기록하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '티켓 사진을 추가해보세요',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSecondaryContainer
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: theme.colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 섹션 헤더
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

/// 티켓 카드
class _TicketCard extends StatelessWidget {
  final Post post;
  final VoidCallback onPostDeleted;

  const _TicketCard({
    required this.post,
    required this.onPostDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy.MM.dd');

    return Card(
      child: InkWell(
        onTap: () async {
          // 게시글 상세 화면으로 이동 (삭제 결과 대기)
          final result = await context.push('/post-detail/${post.id}');
          // 게시글이 삭제된 경우 새로고침
          if (result == true) {
            onPostDeleted();
          }
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 티켓 이미지
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  child: CachedNetworkImage(
                    imageUrl: post.ticketImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(
                        Icons.confirmation_number,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // 제목
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // 경기 정보
              Text(
                '${post.gameInfo.homeTeam ?? '-'} vs ${post.gameInfo.awayTeam ?? '-'}',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSizes.sm),

              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.gameInfo.date != null
                        ? dateFormat.format(post.gameInfo.date!)
                        : '-',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Icon(
                    Icons.stadium,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${post.gameInfo.stadium ?? '-'}${post.gameInfo.seat != null ? ' · ${post.gameInfo.seat}' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),

              // 별점
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < post.rating.floor() ? Icons.star : Icons.star_border,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 친구 탭
class _FriendsTab extends StatefulWidget {
  const _FriendsTab();

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendService _friendService = FriendService();
  List<UserModel> _friends = [];
  int _pendingRequestCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriends();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 친구 목록 로드
  Future<void> _loadFriends() async {
    final currentUser = context.read<auth.AuthProvider>().userModel;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _friendService.getFriends(currentUser.uid),
        _friendService.getPendingRequestCount(currentUser.uid),
      ]);

      setState(() {
        _friends = results[0] as List<UserModel>;
        _pendingRequestCount = results[1] as int;
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
  Future<void> _removeFriend(UserModel friend) async {
    final currentUser = context.read<auth.AuthProvider>().userModel;
    if (currentUser == null) return;

    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('${friend.username}님을 친구 목록에서 삭제하시겠습니까?'),
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
      // 친구 관계 찾기
      final friendship = await _friendService.checkFriendship(
        currentUser.uid,
        friend.uid,
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
          // 목록 새로고침
          _loadFriends();
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
      appBar: AppBar(
        title: const Text('친구'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '친구 목록'),
            Tab(text: '공유 아카이브'),
          ],
        ),
        actions: [
          // 친구 요청 버튼 (배지 포함) - 첫번째 탭에서만 보임
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              return _tabController.index == 0
                  ? Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          onPressed: () async {
                            await context.push('/friend-requests');
                            _loadFriends();
                          },
                        ),
                        if (_pendingRequestCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$_pendingRequestCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    )
                  : const SizedBox.shrink();
            },
          ),
          // 친구 검색 버튼 (첫번째 탭) 또는 아카이브 생성 버튼 (두번째 탭)
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              return _tabController.index == 0
                  ? IconButton(
                      icon: const Icon(Icons.person_add),
                      onPressed: () async {
                        await context.push('/search-friends');
                        _loadFriends();
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        context.push('/create-shared-archive');
                      },
                    );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 친구 목록 탭
          RefreshIndicator(
            onRefresh: _loadFriends,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _friends.isEmpty
                    ? _buildEmptyState()
                    : _buildFriendsList(),
          ),
          // 공유 아카이브 탭
          const SharedArchivesListScreen(),
        ],
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  '친구 목록이 비어있습니다',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.push('/search-friends');
                    _loadFriends();
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('친구 검색'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 친구 목록 위젯
  Widget _buildFriendsList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _friends.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return _FriendCard(
          friend: friend,
          onTap: () {
            context.push('/friend-profile', extra: friend);
          },
          onRemove: () => _removeFriend(friend),
        );
      },
    );
  }
}

/// 친구 카드 위젯
class _FriendCard extends StatelessWidget {
  final UserModel friend;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FriendCard({
    required this.friend,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 프로필 이미지
              CircleAvatar(
                radius: 30,
                backgroundImage: friend.profileImageUrl.isNotEmpty
                    ? NetworkImage(friend.profileImageUrl)
                    : null,
                child: friend.profileImageUrl.isEmpty
                    ? const Icon(Icons.person, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),

              // 사용자 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (friend.favoriteTeams.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        friend.favoriteTeams.join(', '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    if (friend.bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        friend.bio,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // 더보기 메뉴
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'remove') {
                    onRemove();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove, color: Colors.red),
                        SizedBox(width: 8),
                        Text('친구 삭제', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 프로필 탭
class _ProfileTab extends StatefulWidget {
  const _ProfileTab({super.key});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final PostService _postService = PostService();
  Map<String, dynamic>? _stats;
  List<badge_model.Badge> _unlockedBadges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  /// 통계 데이터 로드
  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final stats = await _postService.getUserStats(user.uid);
        final badges = badge_model.BadgeChecker.checkBadges(stats);

        setState(() {
          _stats = stats;
          _unlockedBadges = badges;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('통계 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 로그아웃 처리
  Future<void> _handleLogout() async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<auth.AuthProvider>();
      await authProvider.signOut();

      if (mounted) {
        // 로그인 화면으로 이동
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<auth.AuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MY'),
      ),
      body: ListView(
        children: [
          // 프로필 헤더
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            color: theme.colorScheme.primary,
            child: Column(
              children: [
                // 프로필 이미지
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.onPrimary,
                  backgroundImage: user?.profileImageUrl.isNotEmpty == true
                      ? NetworkImage(user!.profileImageUrl)
                      : null,
                  child: user?.profileImageUrl.isEmpty ?? true
                      ? Icon(
                          Icons.person,
                          size: 48,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                const SizedBox(height: AppSizes.md),
                // 사용자 이름
                Text(
                  user?.username ?? '게스트',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // 이메일 또는 응원팀
                Text(
                  user?.email ?? '로그인이 필요합니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                if (user?.favoriteTeams.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: user!.favoriteTeams.map((team) {
                      return Chip(
                        label: Text(
                          team,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: theme.colorScheme.secondary,
                        labelStyle: TextStyle(
                          color: theme.colorScheme.onSecondary,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // 통계 섹션
          if (user != null && !_isLoading && _stats != null) ...[
            const SizedBox(height: AppSizes.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: _StatisticsCard(stats: _stats!),
            ),
          ],

          // 배지 섹션
          if (user != null && !_isLoading && _unlockedBadges.isNotEmpty) ...[
            const SizedBox(height: AppSizes.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: _BadgeSection(badges: _unlockedBadges),
            ),
          ],

          // 내 게시글 버튼
          if (user != null) ...[
            const SizedBox(height: AppSizes.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: OutlinedButton.icon(
                onPressed: () {
                  context.push('/my-posts');
                },
                icon: const Icon(Icons.list),
                label: const Text('내 게시글 보기'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(AppSizes.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSizes.lg),
          const Divider(height: 1),

          // 메뉴 리스트
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('프로필 수정'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/profile-edit');
              },
            ),
            const Divider(height: 1),
          ],
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('테마 설정'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/theme-preview');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('설정'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/settings');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.orange),
            title: const Text('Firestore 테스트 (디버그)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/firestore-test');
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_upload, color: Colors.blue),
            title: const Text('Storage 테스트 (디버그)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              context.push('/storage-test');
            },
          ),
          if (user != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                '로그아웃',
                style: TextStyle(color: Colors.red),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _handleLogout,
            ),
          ],
        ],
      ),
    );
  }
}

/// 통계 카드
class _StatisticsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatisticsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount = stats['totalCount'] as int;
    final mostVisitedStadium = stats['mostVisitedStadium'] as String;
    final stadiumVisits = stats['stadiumVisits'] as int;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '나의 야구 통계',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            const Divider(),
            const SizedBox(height: AppSizes.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.sports_baseball,
                  label: '총 관람',
                  value: '$totalCount회',
                  color: Colors.blue,
                ),
                _StatItem(
                  icon: Icons.stadium,
                  label: '애정 구장',
                  value: mostVisitedStadium.isNotEmpty
                      ? '$mostVisitedStadium\n($stadiumVisits회)'
                      : '없음',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 통계 아이템
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// 배지 섹션
class _BadgeSection extends StatelessWidget {
  final List<badge_model.Badge> badges;

  const _BadgeSection({required this.badges});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '획득한 배지 (${badges.length}개)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            const Divider(),
            const SizedBox(height: AppSizes.md),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: badges.map<Widget>((badge) {
                return _BadgeItem(badge: badge);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 배지 아이템
class _BadgeItem extends StatelessWidget {
  final badge_model.Badge badge;

  const _BadgeItem({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.description,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: badge.color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: badge.color,
                width: 2,
              ),
            ),
            child: Icon(
              badge.icon,
              color: badge.color,
              size: 32,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
