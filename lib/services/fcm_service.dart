import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'local_notification_service.dart';
import '../core/routes/app_router.dart';
import '../core/utils/notification_navigation_helper.dart';

/// FCM(Firebase Cloud Messaging) 서비스
///
/// 푸시 알림 토큰 관리 및 메시지 처리
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final UserService _userService = UserService();
  final LocalNotificationService _localNotifications =
      LocalNotificationService();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// FCM 초기화
  ///
  /// 1. 로컬 알림 초기화
  /// 2. 알림 권한 요청
  /// 3. FCM 토큰 가져오기
  /// 4. 토큰 갱신 리스너 등록
  /// 5. 메시지 핸들러 등록
  Future<void> initialize() async {
    try {
      print('[FCMService] Initializing FCM...');

      // 1. 로컬 알림 초기화
      await _localNotifications.initialize();

      // 2. 알림 권한 요청
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('[FCMService] Notification permission denied');
        return;
      }

      // 3. FCM 토큰 가져오기
      await _getToken();

      // 4. 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen((newToken) {
        print('[FCMService] Token refreshed: $newToken');
        _fcmToken = newToken;
        _saveTokenToFirestore(newToken);
      });

      // 5. 메시지 핸들러 등록
      _setupMessageHandlers();

      print('[FCMService] FCM initialized successfully');
    } catch (e) {
      print('[FCMService] Failed to initialize: $e');
    }
  }

  /// 알림 권한 요청
  Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('[FCMService] Permission status: ${settings.authorizationStatus}');
    return settings;
  }

  /// FCM 토큰 가져오기
  Future<String?> _getToken() async {
    try {
      // iOS의 경우 APNS 토큰을 먼저 가져와야 함
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          print('[FCMService] APNS token not available yet');
          // 토큰이 준비될 때까지 재시도
          await Future.delayed(const Duration(seconds: 3));
        }
      }

      final token = await _messaging.getToken();
      if (token != null) {
        print('[FCMService] FCM Token: $token');
        _fcmToken = token;
        await _saveTokenToFirestore(token);
      }
      return token;
    } catch (e) {
      print('[FCMService] Failed to get token: $e');
      return null;
    }
  }

  /// FCM 토큰을 Firestore에 저장
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _userService.updateFCMToken(user.uid, token);
        print('[FCMService] Token saved to Firestore');
      }
    } catch (e) {
      print('[FCMService] Failed to save token: $e');
    }
  }

  /// 메시지 핸들러 설정
  void _setupMessageHandlers() {
    // Foreground 메시지 처리
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background 메시지 처리 (앱이 백그라운드에서 실행 중일 때)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Terminated 상태에서 알림 클릭으로 앱 실행
    _checkInitialMessage();
  }

  /// Foreground 메시지 처리
  void _handleForegroundMessage(RemoteMessage message) {
    print('[FCMService] Foreground message received');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // 로컬 알림 표시
    if (message.notification != null) {
      _localNotifications.showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? '요즘티켓',
        body: message.notification!.body ?? '',
        data: message.data,
      );
    }
  }

  /// Background 메시지 처리
  void _handleBackgroundMessage(RemoteMessage message) {
    print('[FCMService] Background message opened');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');

    // TODO: 메시지 타입에 따라 적절한 화면으로 이동
    // 예: 친구 요청 → 친구 요청 화면, 새 게시글 → 게시글 상세
    _handleNotificationNavigation(message.data);
  }

  /// 앱이 종료된 상태에서 알림으로 실행된 경우 확인
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('[FCMService] App opened from terminated state');
      print('Title: ${initialMessage.notification?.title}');
      print('Body: ${initialMessage.notification?.body}');
      print('Data: ${initialMessage.data}');

      _handleNotificationNavigation(initialMessage.data);
    }
  }

  /// 알림 데이터에 따른 네비게이션 처리
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    print('[FCMService] Handling notification navigation');

    // GoRouter를 사용하여 네비게이션
    NotificationNavigationHelper.navigate(router, data);
  }

  /// FCM 토큰 삭제
  ///
  /// 로그아웃 시 호출
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      print('[FCMService] Token deleted');
    } catch (e) {
      print('[FCMService] Failed to delete token: $e');
    }
  }

  /// 토큰 수동 갱신
  ///
  /// 필요한 경우 토큰을 강제로 갱신
  Future<String?> refreshToken() async {
    try {
      await _messaging.deleteToken();
      return await _getToken();
    } catch (e) {
      print('[FCMService] Failed to refresh token: $e');
      return null;
    }
  }
}

/// Background 메시지 핸들러
///
/// 앱이 완전히 종료된 상태에서도 메시지를 받을 수 있도록
/// top-level 함수로 정의 (main.dart에서 등록)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[FCM Background] Message received');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');

  // TODO: Background에서 필요한 처리 수행
  // 예: 로컬 데이터베이스 업데이트, 배지 카운트 업데이트 등
}
