# 광고 시스템 사용 가이드

## 개요

요즘티켓 앱의 Google AdMob 광고 시스템입니다. 무료 사용자에게 배너 광고와 리워드 광고를 표시하여 수익을 창출합니다.

### 광고 유형
- **배너 광고**: 게시물 목록에 7개당 1개씩 자동 삽입
- **리워드 광고**: 사용자가 시청하고 보상을 받는 전면 광고 (일일 3회 제한)

## 파일 구조

```
lib/
├── core/constants/
│   └── ad_config.dart                 # 광고 설정 (광고 ID, 간격 등)
├── services/
│   ├── ad_service.dart                # AdMob SDK 초기화
│   └── rewarded_ad_manager.dart       # 리워드 광고 관리자
└── widgets/ads/
    ├── banner_ad_widget.dart          # 배너 광고 위젯
    ├── ad_banner_card.dart            # 게시물 목록용 광고 카드
    ├── rewarded_ad_button.dart        # 리워드 광고 버튼
    └── README.md                      # 이 문서
```

## 사용 방법

### 1. 배너 광고 표시

#### 단순 배너 광고

```dart
import 'package:yozumticket/widgets/ads/banner_ad_widget.dart';

// 위젯 트리에 추가
BannerAdWidget(
  placement: 'my_screen',  // 로깅용 위치 식별자
)
```

#### 게시물 목록용 광고 카드

```dart
import 'package:yozumticket/widgets/ads/ad_banner_card.dart';

// 게시물 카드 스타일의 광고
AdBannerCard(
  position: 0,           // 광고 번호
  isPremium: false,      // 프리미엄 사용자 여부
)
```

### 2. ListView에 광고 삽입 (7개당 1개)

```dart
import 'package:yozumticket/core/constants/ad_config.dart';
import 'package:yozumticket/widgets/ads/ad_banner_card.dart';

ListView.builder(
  itemCount: _calculateItemCount(posts.length),
  itemBuilder: (context, index) {
    // 광고 위치인지 확인
    if (_isAdPosition(index)) {
      return AdBannerCard(
        position: _getAdPosition(index),
        isPremium: userIsPremium,
      );
    }

    // 일반 게시물
    final postIndex = _getPostIndex(index);
    return PostCard(post: posts[postIndex]);
  },
)

// 헬퍼 메서드
int _calculateItemCount(int postCount) {
  final adCount = (postCount / AdConfig.bannerAdInterval).floor();
  return postCount + adCount;
}

bool _isAdPosition(int index) {
  return (index + 1) % (AdConfig.bannerAdInterval + 1) == 0;
}

int _getAdPosition(int index) {
  return (index / (AdConfig.bannerAdInterval + 1)).floor();
}

int _getPostIndex(int index) {
  final adCount = (index / (AdConfig.bannerAdInterval + 1)).floor();
  return index - adCount;
}
```

## 광고 설정

### AdConfig (lib/core/constants/ad_config.dart)

```dart
class AdConfig {
  // 테스트 모드 플래그
  static const bool isTestMode = true;  // 배포 시 false로 변경

  // 광고 간격
  static const int bannerAdInterval = 7;  // 7개당 1개

  // 광고 단위 ID (자동으로 플랫폼 선택)
  static String get bannerAdUnitId { ... }
  static String get rewardedAdUnitId { ... }
}
```

### 테스트 모드

- `isTestMode = true`: Google 제공 테스트 광고 ID 사용
- 실제 광고가 아닌 샘플 광고 표시
- 수익 발생 없음

### 프로덕션 모드

1. AdMob 콘솔에서 앱 등록
2. 광고 단위 생성 (Android/iOS 각각)
3. `ad_config.dart`의 `_production*AdUnitId` 상수에 실제 ID 입력
4. `isTestMode = false`로 변경
5. `AndroidManifest.xml`과 `Info.plist`의 App ID도 변경

### 3. 리워드 광고 표시

#### 리워드 광고 버튼 사용

```dart
import 'package:yozumticket/widgets/ads/rewarded_ad_button.dart';
import 'package:yozumticket/services/rewarded_ad_manager.dart';

// 설정 화면이나 프로필 화면에 추가
RewardedAdButton(
  rewardType: RewardType.premiumTheme,  // 또는 RewardType.extraPhoto
  onRewardGranted: () {
    // 보상 지급 완료 후 콜백
    print('보상이 지급되었습니다!');
  },
)
```

#### 리워드 광고 직접 제어

```dart
import 'package:yozumticket/services/rewarded_ad_manager.dart';

final adManager = RewardedAdManager();

// 광고 로드
await adManager.loadAd();

// 시청 가능 여부 확인
final canWatch = await adManager.canWatchRewardedAd(userId);

// 남은 횟수 조회
final remaining = await adManager.getRemainingWatchCount(userId);

// 광고 표시
final success = await adManager.showRewardedAd(
  context: context,
  userId: userId,
  rewardType: RewardType.premiumTheme,
);
```

#### 리워드 타입

```dart
enum RewardType {
  premiumTheme,  // 프리미엄 테마 1일 체험
  extraPhoto,    // 추가 사진 1회 (20장)
}
```

## 프리미엄 사용자 광고 제어

### UserModel 필드

```dart
class UserModel {
  final bool isPremium;          // 프리미엄 사용자 여부
  final bool showBannerAds;      // 배너 광고 표시 여부
  // ...
}
```

### 광고 표시 로직

```dart
// AuthProvider에서 사용자 정보 가져오기
final user = context.watch<AuthProvider>().currentUser;
final isPremium = user?.isPremium ?? false;
final showAds = user?.showBannerAds ?? true;

// 프리미엄 사용자는 광고 숨김
if (!isPremium && showAds) {
  // 광고 표시
  BannerAdWidget(placement: 'feed')
}
```

## 광고 이벤트 로깅

### BannerAdWidget 이벤트

광고 위젯은 자동으로 다음 이벤트를 로깅합니다:

- `onAdLoaded`: 광고 로딩 성공
- `onAdFailedToLoad`: 광고 로딩 실패
- `onAdOpened`: 광고 클릭 (외부 브라우저 열림)
- `onAdClosed`: 광고 닫힘
- `onAdImpression`: 광고 노출 (과금 기준)

### 로그 확인

```bash
# Flutter 로그에서 광고 관련 메시지 확인
flutter logs | grep "BannerAdWidget\|AdService"
```

## 배포 전 체크리스트

- [ ] AdMob 계정 생성 및 앱 등록
- [ ] Android 광고 단위 생성 (배너, 리워드)
- [ ] iOS 광고 단위 생성 (배너, 리워드)
- [ ] `ad_config.dart`의 실제 광고 ID 입력
- [ ] `isTestMode = false`로 변경
- [ ] `AndroidManifest.xml` AdMob App ID 변경
- [ ] `Info.plist` GADApplicationIdentifier 변경
- [ ] 실기기에서 광고 로딩 테스트
- [ ] 광고 클릭 및 수익 발생 확인

## 문제 해결

### 광고가 표시되지 않음

1. **AdMob SDK 초기화 확인**
   ```dart
   // main.dart에 AdService 초기화 코드가 있는지 확인
   await AdService().initialize();
   ```

2. **광고 ID 확인**
   - 테스트 모드에서는 Google 제공 테스트 ID 사용
   - 프로덕션 모드에서는 실제 발급받은 ID 사용

3. **네트워크 연결 확인**
   - 광고는 인터넷 연결이 필요합니다

4. **로그 확인**
   - `onAdFailedToLoad` 이벤트의 에러 메시지 확인

### 테스트 기기에서 실제 광고 테스트

1. 앱 실행 후 광고 로딩 시도
2. 로그에서 "Use RequestConfiguration.Builder().setTestDeviceIds(...)" 메시지 찾기
3. 표시된 기기 ID를 `AdService`의 `testDeviceIds`에 추가
4. 앱 재시작

## 참고 자료

- [Google Mobile Ads SDK 문서](https://developers.google.com/admob/flutter)
- [AdMob 정책](https://support.google.com/admob/answer/6128543)
- [광고 게재 위치 가이드](https://support.google.com/admob/answer/6128877)
