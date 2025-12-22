import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_themes.dart';
import '../core/constants/sizes.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

/// 테마 미리보기 및 선택 화면
class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key});

  /// 프리미엄 안내 다이얼로그 표시
  void _showPremiumDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('프리미엄 전용'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '프리미엄 혜택',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• 모든 테마 사용 가능\n'
                    '• 사진 20장까지 추가\n'
                    '• 광고 제거\n'
                    '• 공유 아카이브 무제한',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // 프리미엄 구독 화면으로 이동
              context.push('/premium-subscription');
            },
            child: const Text('프리미엄 보기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('테마 선택'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.md),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '원하는 테마를 선택하세요',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (authProvider.currentUser != null && !authProvider.currentUser!.isPremium)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Tooltip(
                    message: '프리미엄 테마는 구독이 필요합니다',
                    child: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          // 테마 1: 다이어리 (무료)
          _ThemeCard(
            themeType: AppThemeType.diary,
            isSelected: themeProvider.currentTheme == AppThemeType.diary,
            onTap: () {
              themeProvider.setTheme(
                AppThemeType.diary,
                onPremiumRequired: (message) => _showPremiumDialog(context, message),
              );
            },
          ),
          const SizedBox(height: AppSizes.md),

          // 테마 2: 앨범 (프리미엄)
          _ThemeCard(
            themeType: AppThemeType.album,
            isSelected: themeProvider.currentTheme == AppThemeType.album,
            onTap: () {
              themeProvider.setTheme(
                AppThemeType.album,
                onPremiumRequired: (message) => _showPremiumDialog(context, message),
              );
            },
          ),
          const SizedBox(height: AppSizes.md),

          // 테마 3: 야구장 (프리미엄)
          _ThemeCard(
            themeType: AppThemeType.stadium,
            isSelected: themeProvider.currentTheme == AppThemeType.stadium,
            onTap: () {
              themeProvider.setTheme(
                AppThemeType.stadium,
                onPremiumRequired: (message) => _showPremiumDialog(context, message),
              );
            },
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
    final isPremium = AppThemes.isPremiumTheme(themeType);

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
                        Row(
                          children: [
                            Text(
                              themeName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            if (isPremium) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'PREMIUM',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
                  ? Border.fromBorderSide(
                      (theme.cardTheme.shape as RoundedRectangleBorder).side)
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
