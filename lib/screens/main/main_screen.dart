import 'package:flutter/material.dart';
import '../../core/constants/sizes.dart';
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

  // 탭 화면 리스트
  final List<Widget> _screens = [
    const _HomeTab(),
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
              onPressed: () {
                // TODO: 티켓 추가 화면으로 이동
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('티켓 추가 기능 (추후 구현)')),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

/// 홈 탭
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('요즘티켓'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () {
              // TODO: 테마 미리보기 화면으로 이동
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
      body: ListView(
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

          // 샘플 티켓 카드
          _TicketCard(
            homeTeam: '두산',
            awayTeam: 'LG',
            date: '2025.11.25',
            stadium: '잠실야구장',
            seat: '1루 블루석',
            rating: 5,
          ),
          const SizedBox(height: AppSizes.md),

          _TicketCard(
            homeTeam: '키움',
            awayTeam: '삼성',
            date: '2025.11.20',
            stadium: '고척 스카이돔',
            seat: '외야석',
            rating: 4,
          ),
        ],
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
        // TODO: 티켓 추가 화면으로 이동
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('티켓 추가 기능 (추후 구현)')),
        );
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
  final String homeTeam;
  final String awayTeam;
  final String date;
  final String stadium;
  final String seat;
  final int rating;

  const _TicketCard({
    required this.homeTeam,
    required this.awayTeam,
    required this.date,
    required this.stadium,
    required this.seat,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () {
          // TODO: 티켓 상세 화면으로 이동
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 티켓 이미지 (플레이스홀더)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Center(
                  child: Icon(
                    Icons.confirmation_number,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // 경기 정보
              Text(
                '$homeTeam vs $awayTeam',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSizes.sm),

              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Icon(
                    Icons.stadium,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$stadium · $seat',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                    index < rating ? Icons.star : Icons.star_border,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.onPrimary,
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  '게스트',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '로그인이 필요합니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // 메뉴 리스트
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('테마 설정'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: 테마 미리보기 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('테마 설정 (추후 구현)')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('앱 정보'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
