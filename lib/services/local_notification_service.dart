import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../core/routes/app_router.dart';
import '../core/utils/notification_navigation_helper.dart';

/// 로컬 알림 서비스
///
/// Foreground에서 FCM 메시지를 받았을 때 로컬 알림으로 표시
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 로컬 알림 초기화
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('[LocalNotificationService] Initializing...');

      // Android 초기화 설정
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS 초기화 설정
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 초기화
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Android 알림 채널 생성
      await _createNotificationChannel();

      _initialized = true;
      print('[LocalNotificationService] Initialized successfully');
    } catch (e) {
      print('[LocalNotificationService] Failed to initialize: $e');
    }
  }

  /// Android 알림 채널 생성
  Future<void> _createNotificationChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    const channel = AndroidNotificationChannel(
      'default_channel', // 채널 ID
      '기본 알림', // 채널 이름
      description: '요즘티켓의 기본 알림입니다', // 채널 설명
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print('[LocalNotificationService] Notification channel created');
  }

  /// 알림 표시
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // Android 알림 설정
      const androidDetails = AndroidNotificationDetails(
        'default_channel',
        '기본 알림',
        channelDescription: '요즘티켓의 기본 알림입니다',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      // iOS 알림 설정
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // payload로 데이터 전달 (JSON 문자열)
      String? payload;
      if (data != null) {
        // 간단한 key-value 쌍을 '|'로 구분하여 전달
        final entries = data.entries.map((e) => '${e.key}=${e.value}').toList();
        payload = entries.join('|');
      }

      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );

      print('[LocalNotificationService] Notification shown: $title');
    } catch (e) {
      print('[LocalNotificationService] Failed to show notification: $e');
    }
  }

  /// 알림 클릭 시 호출되는 콜백
  void _onNotificationTapped(NotificationResponse response) {
    print('[LocalNotificationService] Notification tapped');
    print('Payload: ${response.payload}');

    if (response.payload != null) {
      // payload 파싱
      final data = _parsePayload(response.payload!);
      print('Parsed data: $data');

      // TODO: 네비게이션 처리
      // 현재는 로그만 출력
      // 실제로는 GoRouter를 사용하여 적절한 화면으로 이동
      _handleNotificationNavigation(data);
    }
  }

  /// payload 문자열을 Map으로 파싱
  Map<String, String> _parsePayload(String payload) {
    final result = <String, String>{};
    final entries = payload.split('|');

    for (final entry in entries) {
      final parts = entry.split('=');
      if (parts.length == 2) {
        result[parts[0]] = parts[1];
      }
    }

    return result;
  }

  /// 알림 클릭 시 네비게이션 처리
  void _handleNotificationNavigation(Map<String, String> data) {
    print('[LocalNotificationService] Handling notification navigation');

    // GoRouter를 사용하여 네비게이션
    NotificationNavigationHelper.navigate(
      router,
      data.map((key, value) => MapEntry(key, value as dynamic)),
    );
  }

  /// 모든 알림 취소
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('[LocalNotificationService] All notifications cancelled');
  }

  /// 특정 알림 취소
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
    print('[LocalNotificationService] Notification $id cancelled');
  }

  /// 배지 카운트 초기화 (iOS)
  Future<void> resetBadge() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS에서 배지 제거
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }
}
