/// AdMob 광고 설정
///
/// 테스트 광고 단위 ID와 실제 광고 단위 ID를 관리합니다.
/// 개발/테스트 단계에서는 테스트 ID를 사용하고,
/// 실제 배포 시에는 AdMob 콘솔에서 발급받은 실제 ID로 교체해야 합니다.

import 'dart:io';

class AdConfig {
  // 테스트 모드 플래그 (배포 시 false로 변경)
  static const bool isTestMode = true;

  // ========================================
  // Android 광고 단위 ID
  // ========================================

  // Android 배너 광고 ID
  static const String _androidBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // 테스트 ID

  // Android 리워드 광고 ID
  static const String _androidRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // 테스트 ID

  // ========================================
  // iOS 광고 단위 ID
  // ========================================

  // iOS 배너 광고 ID
  static const String _iosBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716'; // 테스트 ID

  // iOS 리워드 광고 ID
  static const String _iosRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313'; // 테스트 ID

  // ========================================
  // 실제 배포용 광고 단위 ID (TODO: AdMob 콘솔에서 발급받은 ID로 교체)
  // ========================================

  // 실제 Android 배너 광고 ID
  static const String _productionAndroidBannerAdUnitId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  // 실제 Android 리워드 광고 ID
  static const String _productionAndroidRewardedAdUnitId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  // 실제 iOS 배너 광고 ID
  static const String _productionIosBannerAdUnitId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  // 실제 iOS 리워드 광고 ID
  static const String _productionIosRewardedAdUnitId =
      'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';

  // ========================================
  // 플랫폼별 광고 단위 ID 반환
  // ========================================

  /// 배너 광고 단위 ID
  static String get bannerAdUnitId {
    if (isTestMode) {
      return Platform.isAndroid
          ? _androidBannerAdUnitId
          : _iosBannerAdUnitId;
    } else {
      return Platform.isAndroid
          ? _productionAndroidBannerAdUnitId
          : _productionIosBannerAdUnitId;
    }
  }

  /// 리워드 광고 단위 ID
  static String get rewardedAdUnitId {
    if (isTestMode) {
      return Platform.isAndroid
          ? _androidRewardedAdUnitId
          : _iosRewardedAdUnitId;
    } else {
      return Platform.isAndroid
          ? _productionAndroidRewardedAdUnitId
          : _productionIosRewardedAdUnitId;
    }
  }

  // ========================================
  // 광고 설정값
  // ========================================

  /// 게시물 목록에서 배너 광고 표시 간격 (7개당 1개)
  static const int bannerAdInterval = 7;

  /// 일일 리워드 광고 시청 제한 (3회)
  static const int maxDailyRewardedAds = 3;

  /// 리워드 광고 보상 (프리미엄 테마 1일 무료 체험)
  static const int rewardedAdPremiumDays = 1;

  // ========================================
  // 배포 전 체크리스트
  // ========================================
  //
  // [ ] 1. AdMob 계정에서 앱 등록
  // [ ] 2. Android/iOS 광고 단위 생성
  // [ ] 3. 실제 광고 단위 ID로 _production* 상수 업데이트
  // [ ] 4. isTestMode를 false로 변경
  // [ ] 5. AndroidManifest.xml의 AdMob App ID 업데이트
  // [ ] 6. Info.plist의 GADApplicationIdentifier 업데이트
  // [ ] 7. 실기기 테스트 (광고 로딩 확인)
  //
}
