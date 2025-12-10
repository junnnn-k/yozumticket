import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/ad_service.dart';
import 'services/rewarded_ad_manager.dart';
import 'services/fcm_service.dart';

/// Background 메시지 핸들러
///
/// 앱이 완전히 종료된 상태에서도 메시지를 받을 수 있도록
/// top-level 함수로 정의
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase 초기화가 필요한 경우
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('[FCM Background] Message received');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');

  // TODO: Background에서 필요한 처리 수행
  // 예: 로컬 데이터베이스 업데이트, 배지 카운트 업데이트 등
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM Background 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FCM 초기화
  await FCMService().initialize();

  // AdMob SDK 초기화
  await AdService().initialize();

  // 리워드 광고 미리 로드
  RewardedAdManager().loadAd();

  runApp(const YozumTicketApp());
}
