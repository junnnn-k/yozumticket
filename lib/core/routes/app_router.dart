import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/main/main_screen.dart';
import '../../screens/theme_preview_screen.dart';
import '../../screens/post/ticket_upload_screen.dart';
import '../../screens/post/ocr_result_screen.dart';
import '../../screens/post/post_create_screen.dart';
import '../../screens/post/post_detail_screen.dart';
import '../../screens/post/post_edit_screen.dart';
import '../../screens/profile/profile_edit_screen.dart';
import '../../screens/profile/my_posts_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/friends/search_friends_screen.dart';
import '../../screens/friends/friend_requests_screen.dart';
import '../../screens/friends/friend_profile_screen.dart';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
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

    // 로그인 화면
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
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

    // 게시글 상세 화면
    GoRoute(
      path: '/post-detail/:postId',
      builder: (context, state) {
        final postId = state.pathParameters['postId']!;
        return PostDetailScreen(postId: postId);
      },
    ),

    // 게시글 수정 화면
    GoRoute(
      path: '/post-edit',
      builder: (context, state) {
        final post = state.extra as Post;
        return PostEditScreen(post: post);
      },
    ),

    // 프로필 수정 화면
    GoRoute(
      path: '/profile-edit',
      builder: (context, state) => const ProfileEditScreen(),
    ),

    // 내 게시글 목록 화면
    GoRoute(
      path: '/my-posts',
      builder: (context, state) => const MyPostsScreen(),
    ),

    // 설정 화면
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    // 친구 검색 화면
    GoRoute(
      path: '/search-friends',
      builder: (context, state) => const SearchFriendsScreen(),
    ),

    // 친구 요청 화면
    GoRoute(
      path: '/friend-requests',
      builder: (context, state) => const FriendRequestsScreen(),
    ),

    // 친구 프로필 화면
    GoRoute(
      path: '/friend-profile',
      builder: (context, state) {
        final friend = state.extra as UserModel;
        return FriendProfileScreen(friend: friend);
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
