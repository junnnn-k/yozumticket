import 'package:flutter/material.dart';
import '../../core/constants/sizes.dart';

/// 필터 바텀시트
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // 선택된 구단
  String? _selectedTeam;

  // 선택된 구장
  String? _selectedStadium;

  // 선택된 기간
  DateTimeRange? _selectedDateRange;

  // 최소 별점
  int _minRating = 0;

  // 구단 목록
  final List<String> _teams = [
    '전체',
    '두산',
    'LG',
    '키움',
    'KT',
    'SSG',
    '삼성',
    '롯데',
    'NC',
    '한화',
    'KIA',
  ];

  // 구장 목록
  final List<String> _stadiums = [
    '전체',
    '잠실야구장',
    '고척 스카이돔',
    '수원KT위즈파크',
    '인천SSG랜더스필드',
    '대구삼성라이온즈파크',
    '사직야구장',
    '창원NC파크',
    '대전한화생명이글스파크',
    '광주-기아 챔피언스필드',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '필터',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTeam = null;
                    _selectedStadium = null;
                    _selectedDateRange = null;
                    _minRating = 0;
                  });
                },
                child: const Text('초기화'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          // 구단 필터
          Text(
            '구단',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _teams.map((team) {
              final isSelected = _selectedTeam == team;
              return FilterChip(
                label: Text(team),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTeam = selected ? team : null;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.lg),

          // 구장 필터
          Text(
            '구장',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          DropdownButtonFormField<String>(
            value: _selectedStadium,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
            ),
            hint: const Text('구장 선택'),
            items: _stadiums.map((stadium) {
              return DropdownMenuItem(
                value: stadium,
                child: Text(stadium),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedStadium = value;
              });
            },
          ),
          const SizedBox(height: AppSizes.lg),

          // 최소 별점
          Text(
            '최소 별점: ${_minRating == 0 ? '전체' : _minRating}점',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Slider(
            value: _minRating.toDouble(),
            min: 0,
            max: 5,
            divisions: 5,
            label: _minRating == 0 ? '전체' : '$_minRating점',
            onChanged: (value) {
              setState(() {
                _minRating = value.toInt();
              });
            },
          ),
          const SizedBox(height: AppSizes.lg),

          // 적용 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: 필터 적용 로직
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('필터가 적용되었습니다 (추후 구현)')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              ),
              child: const Text('적용'),
            ),
          ),
        ],
      ),
    );
  }
}
