import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/baseball_data.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';

/// 기록(Archive) 화면
/// - 4가지 뷰 모드: 그리드, 리스트, 캘린더, 구장별
/// - 필터 기능 (구단, 구장, 별점)
/// - 게시글 목록 표시
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final PostService _postService = PostService();

  // 뷰 모드
  ViewMode _viewMode = ViewMode.grid;

  // 데이터
  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  bool _isLoading = true;
  String? _error;

  // 필터 상태
  Set<String> _selectedTeams = {};
  Set<String> _selectedStadiums = {};
  int? _minRating;

  // 캘린더 상태
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Post>> _eventsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  /// 게시글 로드
  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final posts = await _postService.getMyPosts(user.uid, limit: 100);
        setState(() {
          _allPosts = posts;
          _applyFilters();
          _buildEventsByDate();
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

  /// 필터 적용
  void _applyFilters() {
    _filteredPosts = _allPosts.where((post) {
      // 팀 필터
      if (_selectedTeams.isNotEmpty) {
        final hasTeam = _selectedTeams.contains(post.gameInfo.homeTeam) ||
            _selectedTeams.contains(post.gameInfo.awayTeam);
        if (!hasTeam) return false;
      }

      // 구장 필터
      if (_selectedStadiums.isNotEmpty) {
        if (!_selectedStadiums.contains(post.gameInfo.stadium)) return false;
      }

      // 별점 필터
      if (_minRating != null) {
        if (post.rating < _minRating!) return false;
      }

      return true;
    }).toList();

    // 날짜순 정렬 (최신순)
    _filteredPosts.sort((a, b) {
      final aDate = a.gameInfo.date ?? a.createdAt;
      final bDate = b.gameInfo.date ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
  }

  /// 날짜별 이벤트 구성 (캘린더용)
  void _buildEventsByDate() {
    _eventsByDate = {};
    for (final post in _filteredPosts) {
      final date = post.gameInfo.date;
      if (date != null) {
        final key = DateTime(date.year, date.month, date.day);
        if (_eventsByDate[key] == null) {
          _eventsByDate[key] = [];
        }
        _eventsByDate[key]!.add(post);
      }
    }
  }

  /// 필터 다이얼로그 표시
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusLg)),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedTeams: _selectedTeams,
        selectedStadiums: _selectedStadiums,
        minRating: _minRating,
        onApply: (teams, stadiums, rating) {
          setState(() {
            _selectedTeams = teams;
            _selectedStadiums = stadiums;
            _minRating = rating;
            _applyFilters();
            _buildEventsByDate();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('기록 (${_filteredPosts.length})'),
        actions: [
          // 필터 버튼
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
                tooltip: '필터',
              ),
              if (_selectedTeams.isNotEmpty ||
                  _selectedStadiums.isNotEmpty ||
                  _minRating != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // 뷰 모드 전환 버튼
          PopupMenuButton<ViewMode>(
            icon: Icon(_getViewIcon(_viewMode)),
            onSelected: (ViewMode mode) {
              setState(() => _viewMode = mode);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ViewMode.grid,
                child: Row(
                  children: [
                    Icon(Icons.grid_view),
                    SizedBox(width: 8),
                    Text('그리드 뷰'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ViewMode.list,
                child: Row(
                  children: [
                    Icon(Icons.view_list),
                    SizedBox(width: 8),
                    Text('리스트 뷰'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ViewMode.calendar,
                child: Row(
                  children: [
                    Icon(Icons.calendar_month),
                    SizedBox(width: 8),
                    Text('캘린더 뷰'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ViewMode.stadium,
                child: Row(
                  children: [
                    Icon(Icons.stadium),
                    SizedBox(width: 8),
                    Text('구장별 뷰'),
                  ],
                ),
              ),
            ],
            tooltip: '뷰 모드',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: _error != null
                  ? _buildErrorState()
                  : _filteredPosts.isEmpty
                      ? _buildEmptyState()
                      : _buildBody(),
            ),
    );
  }

  /// 뷰 모드 아이콘
  IconData _getViewIcon(ViewMode mode) {
    switch (mode) {
      case ViewMode.grid:
        return Icons.grid_view;
      case ViewMode.list:
        return Icons.view_list;
      case ViewMode.calendar:
        return Icons.calendar_month;
      case ViewMode.stadium:
        return Icons.stadium;
    }
  }

  /// 본문 위젯
  Widget _buildBody() {
    switch (_viewMode) {
      case ViewMode.grid:
        return _buildGridView();
      case ViewMode.list:
        return _buildListView();
      case ViewMode.calendar:
        return _buildCalendarView();
      case ViewMode.stadium:
        return _buildStadiumView();
    }
  }

  /// 에러 상태
  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPosts,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 빈 상태
  Widget _buildEmptyState() {
    final hasFilters = _selectedTeams.isNotEmpty ||
        _selectedStadiums.isNotEmpty ||
        _minRating != null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasFilters ? Icons.search_off : Icons.book_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  hasFilters ? '필터 조건에 맞는 기록이 없습니다' : '아직 기록이 없습니다',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  hasFilters ? '필터를 변경해보세요' : '첫 경기를 기록해보세요!',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                if (hasFilters) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTeams.clear();
                        _selectedStadiums.clear();
                        _minRating = null;
                        _applyFilters();
                        _buildEventsByDate();
                      });
                    },
                    child: const Text('필터 초기화'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 그리드 뷰
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSizes.md,
        mainAxisSpacing: AppSizes.md,
        childAspectRatio: 0.7,
      ),
      itemCount: _filteredPosts.length,
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];
        return _PostCard(post: post);
      },
    );
  }

  /// 리스트 뷰
  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: _filteredPosts.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final post = _filteredPosts[index];
        return _PostCard(post: post, isListView: true);
      },
    );
  }

  /// 캘린더 뷰
  Widget _buildCalendarView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2030),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: (day) => _eventsByDate[DateTime(day.year, day.month, day.day)] ?? [],
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const Divider(),
        Expanded(
          child: _buildSelectedDayPosts(),
        ),
      ],
    );
  }

  /// 선택된 날짜의 게시글 목록
  Widget _buildSelectedDayPosts() {
    if (_selectedDay == null) {
      return const Center(
        child: Text('날짜를 선택하세요'),
      );
    }

    final key = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final posts = _eventsByDate[key] ?? [];

    if (posts.isEmpty) {
      return const Center(
        child: Text('해당 날짜에 기록이 없습니다'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        return _PostCard(post: posts[index], isListView: true);
      },
    );
  }

  /// 구장별 뷰
  Widget _buildStadiumView() {
    // 구장별로 그룹화
    final postsByStadium = <String, List<Post>>{};
    for (final post in _filteredPosts) {
      final stadium = post.gameInfo.stadium;
      if (stadium != null && stadium.isNotEmpty) {
        if (postsByStadium[stadium] == null) {
          postsByStadium[stadium] = [];
        }
        postsByStadium[stadium]!.add(post);
      }
    }

    // 구장별 방문 횟수로 정렬
    final sortedStadiums = postsByStadium.keys.toList()
      ..sort((a, b) => postsByStadium[b]!.length.compareTo(postsByStadium[a]!.length));

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: sortedStadiums.length,
      itemBuilder: (context, index) {
        final stadium = sortedStadiums[index];
        final posts = postsByStadium[stadium]!;

        return Card(
          margin: const EdgeInsets.only(bottom: AppSizes.md),
          child: ExpansionTile(
            leading: const Icon(Icons.stadium),
            title: Text(stadium),
            subtitle: Text('${posts.length}회 방문'),
            children: posts.map((post) {
              return ListTile(
                title: Text(post.title),
                subtitle: Text(
                  '${post.gameInfo.homeTeam} vs ${post.gameInfo.awayTeam}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(post.rating.toStringAsFixed(1)),
                  ],
                ),
                onTap: () => context.push('/post-detail/${post.id}'),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// 게시글 카드
class _PostCard extends StatelessWidget {
  final Post post;
  final bool isListView;

  const _PostCard({
    required this.post,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/post-detail/${post.id}'),
        child: isListView ? _buildListLayout() : _buildGridLayout(),
      ),
    );
  }

  Widget _buildGridLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 티켓 이미지
        Expanded(
          child: Image.network(
            post.ticketImageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${post.gameInfo.homeTeam} vs ${post.gameInfo.awayTeam}',
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    post.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListLayout() {
    return Row(
      children: [
        // 티켓 이미지
        SizedBox(
          width: 100,
          height: 100,
          child: Image.network(
            post.ticketImageUrl,
            fit: BoxFit.cover,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${post.gameInfo.homeTeam} vs ${post.gameInfo.awayTeam}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  post.gameInfo.stadium ?? '구장 정보 없음',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      post.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 필터 바텀시트
class _FilterBottomSheet extends StatefulWidget {
  final Set<String> selectedTeams;
  final Set<String> selectedStadiums;
  final int? minRating;
  final Function(Set<String>, Set<String>, int?) onApply;

  const _FilterBottomSheet({
    required this.selectedTeams,
    required this.selectedStadiums,
    required this.minRating,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Set<String> _teams;
  late Set<String> _stadiums;
  late int? _rating;

  @override
  void initState() {
    super.initState();
    _teams = Set.from(widget.selectedTeams);
    _stadiums = Set.from(widget.selectedStadiums);
    _rating = widget.minRating;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  const Text(
                    '필터',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _teams.clear();
                        _stadiums.clear();
                        _rating = null;
                      });
                    },
                    child: const Text('초기화'),
                  ),
                ],
              ),
            ),

            // 필터 내용
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // 구단 필터
                  const Text(
                    '구단',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BaseballData.teams.keys.map((team) {
                      final isSelected = _teams.contains(team);
                      return FilterChip(
                        label: Text(team),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _teams.add(team);
                            } else {
                              _teams.remove(team);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 구장 필터
                  const Text(
                    '구장',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: BaseballData.stadiums.keys.map((stadium) {
                      final isSelected = _stadiums.contains(stadium);
                      return FilterChip(
                        label: Text(stadium, style: const TextStyle(fontSize: 12)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _stadiums.add(stadium);
                            } else {
                              _stadiums.remove(stadium);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 별점 필터
                  const Text(
                    '최소 별점',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [1, 2, 3, 4, 5].map((rating) {
                      final isSelected = _rating == rating;
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text('$rating'),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _rating = selected ? rating : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // 적용 버튼
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_teams, _stadiums, _rating);
                    Navigator.of(context).pop();
                  },
                  child: const Text('적용'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 뷰 모드
enum ViewMode {
  grid,
  list,
  calendar,
  stadium,
}
