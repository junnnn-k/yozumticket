import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/theme_preview_screen.dart';
import '../../providers/theme_provider.dart';

/// 앱의 라우팅 설정
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => _HomeScreen(),
    ),
    GoRoute(
      path: '/theme-preview',
      builder: (context, state) => const ThemePreviewScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('페이지를 찾을 수 없습니다: ${state.uri}'),
    ),
  ),
);

/// 임시 홈 화면 (테마 미리보기 테스트용)
class _HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('요즘티켓'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: () => context.push('/theme-preview'),
            tooltip: '테마 변경',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_baseball,
              size: 80,
            ),
            const SizedBox(height: 20),
            const Text(
              '요즘티켓',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '프로야구 관람 기록 소셜 아카이브',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => context.push('/theme-preview'),
              icon: const Icon(Icons.palette),
              label: const Text('테마 미리보기'),
            ),
            const SizedBox(height: 20),
            Text(
              '현재 테마: ${_getThemeName(themeProvider.currentTheme)}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeName(AppThemeType type) {
    switch (type) {
      case AppThemeType.diary:
        return '일기장';
      case AppThemeType.album:
        return '앨범';
      case AppThemeType.stadium:
        return '야구장';
    }
  }
}
