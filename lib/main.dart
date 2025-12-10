import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/ad_service.dart';
import 'services/rewarded_ad_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // AdMob SDK 초기화
  await AdService().initialize();

  // 리워드 광고 미리 로드
  RewardedAdManager().loadAd();

  runApp(const YozumTicketApp());
}
