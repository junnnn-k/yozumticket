import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/main/main_screen.dart';
import '../../screens/theme_preview_screen.dart';
import '../../screens/post/ticket_upload_screen.dart';

/// 앱의 라우팅 설정
final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    // Splash 화면
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // 메인 화면 (하단 탭 네비게이션)
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainScreen(),
    ),

    // 테마 미리보기 화면
    GoRoute(
      path: '/theme-preview',
      builder: (context, state) => const ThemePreviewScreen(),
    ),

    // 티켓 업로드 화면
    GoRoute(
      path: '/ticket-upload',
      builder: (context, state) => const TicketUploadScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('페이지를 찾을 수 없습니다: ${state.uri}'),
    ),
  ),
);
