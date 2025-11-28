import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_themes.dart';
import '../core/constants/sizes.dart';
import '../providers/theme_provider.dart';

/// 테마 미리보기 및 선택 화면
class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('테마 선택'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          const Text(
            '원하는 테마를 선택하세요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.lg),

          // 테마 1: 다이어리
          _ThemeCard(
            themeType: AppThemeType.diary,
            isSelected: themeProvider.currentTheme == AppThemeType.diary,
            onTap: () => themeProvider.setTheme(AppThemeType.diary),
          ),
          const SizedBox(height: AppSizes.md),

          // 테마 2: 앨범
          _ThemeCard(
            themeType: AppThemeType.album,
            isSelected: themeProvider.currentTheme == AppThemeType.album,
            onTap: () => themeProvider.setTheme(AppThemeType.album),
          ),
          const SizedBox(height: AppSizes.md),

          // 테마 3: 야구장
          _ThemeCard(
            themeType: AppThemeType.stadium,
            isSelected: themeProvider.currentTheme == AppThemeType.stadium,
            onTap: () => themeProvider.setTheme(AppThemeType.stadium),
          ),
        ],
      ),
    );
  }
}

/// 개별 테마 카드
class _ThemeCard extends StatelessWidget {
  final AppThemeType themeType;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.themeType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemes.getTheme(themeType);
    final themeName = AppThemes.getThemeName(themeType);
    final themeDescription = AppThemes.getThemeDescription(themeType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusMd),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          themeName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          themeDescription,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 미리보기 영역
            Container(
              height: 200,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
              ),
              child: _buildPreview(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 샘플 티켓 카드
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              border: theme.cardTheme.shape is RoundedRectangleBorder
                  ? (theme.cardTheme.shape as RoundedRectangleBorder).side
                  : null,
              boxShadow: [
                BoxShadow(
                  color: theme.cardTheme.shadowColor ?? Colors.black12,
                  blurRadius: theme.cardTheme.elevation ?? 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '두산 vs LG',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '2025.11.25 잠실야구장',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      size: 14,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        // 색상 팔레트
        Row(
          children: [
            _ColorChip(color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            _ColorChip(color: theme.colorScheme.secondary),
            const SizedBox(width: 4),
            _ColorChip(color: theme.colorScheme.surface),
            const SizedBox(width: 4),
            _ColorChip(color: theme.appBarTheme.backgroundColor ?? Colors.grey),
          ],
        ),
      ],
    );
  }
}

/// 색상 칩
class _ColorChip extends StatelessWidget {
  final Color color;

  const _ColorChip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );
  }
}
