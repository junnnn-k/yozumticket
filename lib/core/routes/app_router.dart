import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/main/main_screen.dart';
import '../../screens/theme_preview_screen.dart';
import '../../screens/post/ticket_upload_screen.dart';
import '../../screens/post/ocr_result_screen.dart';
import '../../screens/post/post_create_screen.dart';
import '../../screens/debug/firestore_test_screen.dart';
import '../../screens/debug/storage_test_screen.dart';

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

    // OCR 결과 확인 화면
    GoRoute(
      path: '/ocr-result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return OcrResultScreen(
          ticketImage: extra['ticketImage'],
          gameInfo: extra['gameInfo'],
        );
      },
    ),

    // 게시글 작성 화면
    GoRoute(
      path: '/post-create',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return PostCreateScreen(
          ticketImage: extra['ticketImage'],
          gameInfo: extra['gameInfo'],
        );
      },
    ),

    // Firestore 테스트 화면 (디버그용)
    GoRoute(
      path: '/firestore-test',
      builder: (context, state) => const FirestoreTestScreen(),
    ),

    // Storage 테스트 화면 (디버그용)
    GoRoute(
      path: '/storage-test',
      builder: (context, state) => const StorageTestScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('페이지를 찾을 수 없습니다: ${state.uri}'),
    ),
  ),
);
