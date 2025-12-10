/// AdMob 광고 관리 서비스
///
/// Google Mobile Ads SDK 초기화 및 광고 로딩을 담당합니다.

import 'dart:developer' as dev;
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// AdMob SDK 초기화
  ///
  /// 앱 시작 시 최초 1회 호출되어야 합니다.
  /// Firebase 초기화 후에 호출하는 것을 권장합니다.
  Future<void> initialize() async {
    if (_isInitialized) {
      dev.log('AdMob SDK already initialized', name: 'AdService');
      return;
    }

    try {
      dev.log('Initializing AdMob SDK...', name: 'AdService');

      // AdMob SDK 초기화
      await MobileAds.instance.initialize();

      // 요청 설정 (선택적)
      final requestConfiguration = RequestConfiguration(
        // 테스트 기기 ID 목록 (실제 기기에서 테스트 광고를 보려면 추가)
        testDeviceIds: [
          // 'YOUR_DEVICE_ID', // 실제 기기 ID로 교체
        ],
        // 태그된 아동용 콘텐츠 처리 (COPPA 준수)
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
      );

      MobileAds.instance.updateRequestConfiguration(requestConfiguration);

      _isInitialized = true;
      dev.log('AdMob SDK initialized successfully', name: 'AdService');
    } catch (e, stackTrace) {
      dev.log(
        'Failed to initialize AdMob SDK: $e',
        name: 'AdService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 광고 요청 설정 생성
  ///
  /// 개인화 광고 설정 등을 포함한 AdRequest를 반환합니다.
  AdRequest createAdRequest() {
    return const AdRequest(
      // 키워드 설정 (선택적)
      keywords: ['baseball', 'sports', 'kbo', 'ticket'],
      // 콘텐츠 URL (선택적)
      contentUrl: 'https://yozumticket.com',
    );
  }

  /// 테스트 기기 ID 확인 방법
  ///
  /// 1. 앱을 실제 기기에서 실행
  /// 2. 광고 로딩 시도
  /// 3. 콘솔 로그에서 "Use RequestConfiguration.Builder().setTestDeviceIds(Arrays.asList(...))를 찾음
  /// 4. 해당 ID를 testDeviceIds 리스트에 추가
  void printTestDeviceIdInstructions() {
    dev.log(
      '''
      ========================================
      테스트 기기 ID 확인 방법
      ========================================
      1. 실제 기기에서 앱 실행
      2. 광고 로딩 시도
      3. 콘솔 로그에서 다음 메시지 찾기:
         "Use RequestConfiguration.Builder().setTestDeviceIds(Arrays.asList(...))
      4. 해당 ID를 AdService의 testDeviceIds에 추가
      ========================================
      ''',
      name: 'AdService',
    );
  }
}
