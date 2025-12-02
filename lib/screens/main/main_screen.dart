import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/sizes.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../providers/auth_provider.dart' as auth;
import '../archive/archive_screen.dart';

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

  // 탭 화면 리스트
  late final List<Widget> _screens = [
    _HomeTab(key: _homeTabKey),
    const ArchiveScreen(),
    const _FriendsTab(),
    const _ProfileTab(),
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
                // 돌아왔을 때 홈 탭 새로고침
                _homeTabKey.currentState?._loadRecentPosts();
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// 홈 탭
class _HomeTab extends StatefulWidget {
  const _HomeTab({super.key});

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('테마 설정 (추후 구현)')),
              );
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
                    onPostDeleted: _loadRecentPosts,
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
class _FriendsTab extends StatelessWidget {
  const _FriendsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('친구'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '친구 화면',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '(추후 구현)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// 프로필 탭
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  /// 로그아웃 처리
  Future<void> _handleLogout(BuildContext context) async {
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

    if (confirmed == true && context.mounted) {
      final authProvider = context.read<auth.AuthProvider>();
      await authProvider.signOut();

      if (context.mounted) {
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

          // 메뉴 리스트
          if (user != null) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('프로필 수정'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // TODO: 프로필 수정 화면으로 이동 (22일차 구현 예정)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('프로필 수정 (추후 구현)')),
                );
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
            leading: const Icon(Icons.notifications),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('알림 설정 (추후 구현)')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('앱 정보'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('앱 정보 (추후 구현)')),
              );
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
              onTap: () => _handleLogout(context),
            ),
          ],
        ],
      ),
    );
  }
}
