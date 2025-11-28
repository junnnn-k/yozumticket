import 'package:flutter/material.dart';
import '../../core/constants/sizes.dart';
import '../../widgets/archive/post_grid_item.dart';
import '../../widgets/archive/post_list_item.dart';
import '../../widgets/archive/filter_bottom_sheet.dart';

/// 기록(Archive) 화면
/// - 3가지 뷰 모드: 그리드, 리스트, 캘린더
/// - 필터 기능
/// - 게시글 목록 표시
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  // 뷰 모드 (grid, list, calendar)
  ViewMode _viewMode = ViewMode.grid;

  // 더미 데이터
  final List<Map<String, dynamic>> _dummyPosts = [
    {
      'id': '1',
      'homeTeam': '두산',
      'awayTeam': 'LG',
      'date': '2025.11.25',
      'stadium': '잠실야구장',
      'seat': '1루 블루석',
      'rating': 5,
      'memo': '완벽한 경기였어요!',
    },
    {
      'id': '2',
      'homeTeam': '키움',
      'awayTeam': '삼성',
      'date': '2025.11.20',
      'stadium': '고척 스카이돔',
      'seat': '외야석',
      'rating': 4,
      'memo': '날씨가 좋았습니다',
    },
    {
      'id': '3',
      'homeTeam': 'KIA',
      'awayTeam': '롯데',
      'date': '2025.11.15',
      'stadium': '광주-기아 챔피언스필드',
      'seat': '3루 레드석',
      'rating': 5,
      'memo': '역전승! 최고였어요',
    },
    {
      'id': '4',
      'homeTeam': 'SSG',
      'awayTeam': 'KT',
      'date': '2025.11.10',
      'stadium': '인천SSG랜더스필드',
      'seat': '1루석',
      'rating': 3,
      'memo': '비가 와서 아쉬웠어요',
    },
    {
      'id': '5',
      'homeTeam': '삼성',
      'awayTeam': 'NC',
      'date': '2025.11.05',
      'stadium': '대구삼성라이온즈파크',
      'seat': '외야석',
      'rating': 4,
      'memo': '좋은 추억!',
    },
    {
      'id': '6',
      'homeTeam': '한화',
      'awayTeam': '두산',
      'date': '2025.10.30',
      'stadium': '대전한화생명이글스파크',
      'seat': '내야석',
      'rating': 4,
      'memo': '즐거운 야구 관람',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
        actions: [
          // 필터 버튼
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const FilterBottomSheet(),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSizes.radiusLg),
                  ),
                ),
              );
            },
            tooltip: '필터',
          ),
          // 뷰 모드 전환 버튼
          PopupMenuButton<ViewMode>(
            icon: Icon(_getViewIcon(_viewMode)),
            onSelected: (ViewMode mode) {
              setState(() {
                _viewMode = mode;
              });
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
            ],
            tooltip: '뷰 모드',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  /// 뷰 모드에 따른 아이콘 반환
  IconData _getViewIcon(ViewMode mode) {
    switch (mode) {
      case ViewMode.grid:
        return Icons.grid_view;
      case ViewMode.list:
        return Icons.view_list;
      case ViewMode.calendar:
        return Icons.calendar_month;
    }
  }

  /// 뷰 모드에 따른 본문 위젯
  Widget _buildBody() {
    if (_dummyPosts.isEmpty) {
      return _buildEmptyState();
    }

    switch (_viewMode) {
      case ViewMode.grid:
        return _buildGridView();
      case ViewMode.list:
        return _buildListView();
      case ViewMode.calendar:
        return _buildCalendarView();
    }
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            '아직 기록이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            '첫 경기를 기록해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
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
        childAspectRatio: 0.75,
      ),
      itemCount: _dummyPosts.length,
      itemBuilder: (context, index) {
        final post = _dummyPosts[index];
        return PostGridItem(post: post);
      },
    );
  }

  /// 리스트 뷰
  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: _dummyPosts.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSizes.md),
      itemBuilder: (context, index) {
        final post = _dummyPosts[index];
        return PostListItem(post: post);
      },
    );
  }

  /// 캘린더 뷰 (추후 구현)
  Widget _buildCalendarView() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            '캘린더 뷰',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            '추후 구현 예정',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// 뷰 모드 열거형
enum ViewMode {
  grid,
  list,
  calendar,
}
