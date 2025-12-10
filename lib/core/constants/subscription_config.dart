/// 구독 및 인앱 결제 상품 설정
///
/// Google Play Console 및 App Store Connect에 등록된 상품 ID와 일치해야 합니다.

class SubscriptionConfig {
  SubscriptionConfig._();

  /// 테스트 모드 여부
  static const bool isTestMode = true;

  /// 구독 상품 ID
  static const String premiumMonthlyId = isTestMode
      ? 'test_premium_monthly'
      : 'premium_monthly';

  static const String premiumYearlyId = isTestMode
      ? 'test_premium_yearly'
      : 'premium_yearly';

  /// 일회성 상품 ID
  static const String extraPhotoPackId = isTestMode
      ? 'test_extra_photo_pack'
      : 'extra_photo_pack';

  static const String themePackId = isTestMode
      ? 'test_theme_pack'
      : 'theme_pack';

  /// 모든 구독 상품 ID 리스트
  static const List<String> subscriptionIds = [
    premiumMonthlyId,
    premiumYearlyId,
  ];

  /// 모든 일회성 상품 ID 리스트
  static const List<String> consumableIds = [
    extraPhotoPackId,
    themePackId,
  ];

  /// 모든 상품 ID 리스트
  static List<String> get allProductIds => [
    ...subscriptionIds,
    ...consumableIds,
  ];

  /// 구독 상품 정보
  static const Map<String, Map<String, dynamic>> subscriptionInfo = {
    premiumMonthlyId: {
      'name': '프리미엄 월간 구독',
      'description': '광고 제거, 사진 20장, 무제한 공유 아카이브',
      'price': '₩6,900',
      'period': '월',
    },
    premiumYearlyId: {
      'name': '프리미엄 연간 구독',
      'description': '광고 제거, 사진 20장, 무제한 공유 아카이브 (25% 할인)',
      'price': '₩62,000',
      'period': '연',
    },
  };

  /// 일회성 상품 정보
  static const Map<String, Map<String, dynamic>> consumableInfo = {
    extraPhotoPackId: {
      'name': '추가 사진 팩',
      'description': '게시물당 사진 10장 추가 (1회 구매)',
      'price': '₩2,900',
    },
    themePackId: {
      'name': '프리미엄 테마 팩',
      'description': '5가지 프리미엄 테마 잠금 해제',
      'price': '₩3,900',
    },
  };

  /// 프리미엄 혜택 목록
  static const List<String> premiumBenefits = [
    '🚫 광고 완전 제거',
    '📸 게시물당 사진 20장',
    '📁 무제한 공유 아카이브',
    '🎨 프리미엄 테마 5종',
    '📊 고급 통계 분석',
    '⚡ 우선 지원',
  ];

  /// 무료 사용자 제한
  static const Map<String, dynamic> freeLimits = {
    'maxPhotosPerPost': 3,
    'maxSharedArchives': 2,
    'showBannerAds': true,
    'maxDailyRewardedAds': 3,
  };

  /// 프리미엄 사용자 제한
  static const Map<String, dynamic> premiumLimits = {
    'maxPhotosPerPost': 20,
    'maxSharedArchives': -1, // -1 = 무제한
    'showBannerAds': false,
    'maxDailyRewardedAds': 0, // 광고 불필요
  };
}
