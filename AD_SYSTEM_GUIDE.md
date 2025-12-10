# 광고 시스템 완전 가이드

## 목차
1. [개요](#개요)
2. [시스템 아키텍처](#시스템-아키텍처)
3. [테스트 가이드](#테스트-가이드)
4. [배포 체크리스트](#배포-체크리스트)
5. [수익 분석](#수익-분석)
6. [문제 해결](#문제-해결)

---

## 개요

요즘티켓의 광고 시스템은 Google AdMob을 기반으로 배너 광고와 리워드 광고를 지원합니다.

### 주요 기능

| 기능 | 설명 | 구현 상태 |
|------|------|-----------|
| 배너 광고 | 게시물 목록 7개당 1개 자동 삽입 | ✅ 완료 |
| 리워드 광고 | 일일 3회 시청 제한 | ✅ 완료 |
| 프리미엄 필터링 | 유료 사용자는 광고 숨김 | ✅ 완료 |
| 이벤트 로깅 | Firestore에 노출/클릭/보상 기록 | ✅ 완료 |
| 분석 대시보드 | 수익 추정 및 통계 | ⏳ 향후 구현 |

### 수익 모델

**MAU 10,000 기준 월 수익: ₩604만원**

- **배너 광고**: ₩285만원 (CPM ₩500, 월 570만 노출)
- **리워드 광고**: ₩319만원 (CPM ₩4,000, 월 7.98만 노출)

---

## 시스템 아키텍처

### 컴포넌트 구조

```
┌─────────────────────────────────────────────┐
│           User Interface Layer              │
├─────────────────────────────────────────────┤
│  BannerAdWidget  │  RewardedAdButton        │
│  AdBannerCard    │  MyPostsScreen           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│          Service Layer                      │
├─────────────────────────────────────────────┤
│  AdService         (SDK 초기화)              │
│  RewardedAdManager (리워드 관리)             │
│  AdAnalyticsService (이벤트 로깅)           │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│         Data Layer                          │
├─────────────────────────────────────────────┤
│  AdConfig          (광고 ID, 설정)           │
│  AdInteraction     (로그 모델)               │
│  UserModel         (프리미엄 플래그)         │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│      External Services                      │
├─────────────────────────────────────────────┤
│  Google AdMob      (광고 제공)               │
│  Cloud Firestore   (로그 저장)               │
└─────────────────────────────────────────────┘
```

### 데이터 흐름

#### 배너 광고

```
1. MyPostsScreen 렌더링
2. 7개마다 AdBannerCard 삽입
3. BannerAdWidget 생성
4. AdService.createAdRequest()
5. Google AdMob에서 광고 로드
6. onAdImpression → AdAnalyticsService.logBannerImpression()
7. Firestore에 이벤트 저장
```

#### 리워드 광고

```
1. SettingsScreen > RewardedAdButton 탭
2. RewardedAdManager.showRewardedAd()
3. 일일 제한 확인 (UserModel.dailyRewardedAdCount)
4. 광고 표시
5. 시청 완료 → onUserEarnedReward
6. AdAnalyticsService.logRewardGranted()
7. UserService.incrementRewardedAdCount()
8. Firestore 업데이트
```

---

## 테스트 가이드

### 1. 로컬 테스트 (개발 환경)

#### 1.1 배너 광고 테스트

```bash
# 1. 앱 실행
flutter run

# 2. 로그인 후 "내 게시글" 화면 이동
# 3. 7개 이상 게시물이 있는지 확인 (없으면 추가)
# 4. 스크롤하면서 광고 배너 확인

# 예상 결과:
# - 7, 15, 23... 위치에 "광고" 라벨과 배너 표시
# - 로딩 인디케이터 → 광고 표시 전환
# - 로그: "Banner ad loaded successfully (feed_position_0)"
```

**확인 사항**:
- [ ] 광고가 7개마다 표시되는가?
- [ ] 광고 로딩 실패 시 숨겨지는가?
- [ ] 프리미엄 사용자는 광고가 안 보이는가?
- [ ] 클릭 시 외부 브라우저가 열리는가?

#### 1.2 리워드 광고 테스트

```bash
# 1. 설정 화면 이동
# 2. "무료 혜택" 섹션 확인
# 3. "광고 보고 프리미엄 테마 체험하기" 버튼 탭

# 예상 결과:
# - 전면 광고 표시
# - 30초 시청 후 "보상 획득!" 다이얼로그
# - 남은 횟수 감소 (3/3 → 2/3)
```

**확인 사항**:
- [ ] 일일 3회 제한이 작동하는가?
- [ ] 4번째 시청 시 "일일 시청 제한" 다이얼로그 표시되는가?
- [ ] 보상 지급 후 스낵바 표시되는가?
- [ ] 프리미엄 사용자는 섹션이 숨겨지는가?

#### 1.3 로깅 시스템 테스트

```bash
# Firestore Console에서 확인
# https://console.firebase.google.com/project/[your-project]/firestore/data

# 1. adInteractions 컬렉션 확인
# 2. 최신 문서 열기

# 예상 필드:
{
  userId: "ABC123...",
  adType: "banner" | "rewarded",
  eventType: "impression" | "click" | "rewarded",
  adUnitId: "ca-app-pub-...",
  placement: "feed_position_0",  // 배너만
  rewardType: "premiumTheme",    // 리워드만
  timestamp: Timestamp(...),
  metadata: {...}                // 선택적
}
```

**확인 사항**:
- [ ] 광고 노출 시 Firestore에 기록되는가?
- [ ] userId가 올바른가?
- [ ] timestamp가 정확한가?
- [ ] metadata에 추가 정보가 있는가?

### 2. 실기기 테스트

#### 2.1 Android 테스트

```bash
# 디버그 APK 설치
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk

# 로그 모니터링
adb logcat | grep -E "AdService|BannerAdWidget|RewardedAdManager"
```

**테스트 시나리오**:
1. Wi-Fi 연결 확인
2. 로그인
3. 게시물 7개 이상 작성
4. "내 게시글" 화면에서 배너 광고 확인
5. 설정 > 리워드 광고 3회 시청
6. 네트워크 끊고 광고 로딩 실패 테스트

#### 2.2 iOS 테스트

```bash
# Xcode에서 빌드 및 실행
flutter build ios
open ios/Runner.xcworkspace

# 시뮬레이터에서 실행
flutter run -d ios

# 로그 확인
flutter logs | grep -E "AdService|BannerAdWidget|RewardedAdManager"
```

### 3. 프리미엄 기능 테스트

#### 3.1 프리미엄 전환 테스트

```dart
// Firestore Console에서 사용자 문서 수동 수정
// users/{userId}

{
  isPremium: true,        // false → true로 변경
  showBannerAds: false,   // true → false로 변경
  subscriptionType: "premium",
  subscriptionEndDate: Timestamp(2026, 1, 1),
  maxPhotosPerPost: 20,
  maxSharedArchives: -1
}

// 앱 재시작 후 확인:
// - 배너 광고 숨김
// - 설정 화면 "무료 혜택" 섹션 숨김
```

### 4. 성능 테스트

#### 4.1 광고 로딩 속도

```bash
# 배너 광고 로딩 시간 측정
flutter run --profile
# DevTools > Performance 탭에서 확인

# 목표:
# - 초기 로딩: < 1초
# - 광고 표시: < 2초
```

#### 4.2 메모리 사용량

```bash
# 메모리 프로파일링
flutter run --profile
# DevTools > Memory 탭

# 확인 사항:
# - 광고 위젯 dispose 시 메모리 해제되는가?
# - 메모리 누수가 없는가?
```

---

## 배포 체크리스트

### Phase 1: AdMob 계정 설정

- [ ] AdMob 계정 생성 (https://admob.google.com)
- [ ] 앱 추가 (Android / iOS 각각)
- [ ] 배너 광고 단위 생성
- [ ] 리워드 광고 단위 생성
- [ ] 광고 단위 ID 복사

### Phase 2: 코드 업데이트

```dart
// lib/core/constants/ad_config.dart

// 1. isTestMode를 false로 변경
static const bool isTestMode = false;

// 2. 실제 광고 ID 입력
static const String _productionAndroidBannerAdUnitId =
    'ca-app-pub-1234567890123456/1234567890';  // AdMob에서 복사

static const String _productionAndroidRewardedAdUnitId =
    'ca-app-pub-1234567890123456/0987654321';  // AdMob에서 복사

static const String _productionIosBannerAdUnitId =
    'ca-app-pub-1234567890123456/1122334455';

static const String _productionIosRewardedAdUnitId =
    'ca-app-pub-1234567890123456/5544332211';
```

### Phase 3: 플랫폼 설정 업데이트

#### Android

```xml
<!-- android/app/src/main/AndroidManifest.xml -->

<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-1234567890123456~1234567890"/>
    <!-- 실제 AdMob App ID로 교체 -->
```

#### iOS

```xml
<!-- ios/Runner/Info.plist -->

<key>GADApplicationIdentifier</key>
<string>ca-app-pub-1234567890123456~0987654321</string>
<!-- 실제 AdMob App ID로 교체 -->
```

### Phase 4: Firestore 설정

```bash
# 1. Firestore 보안 규칙 배포
# Firebase Console > Firestore Database > 규칙 탭
# firestore_rules_ads.txt 내용 추가 후 "게시"

# 2. 복합 인덱스 생성 (자동)
# 앱에서 쿼리 실행 시 콘솔에 표시되는 링크 클릭
# 또는 firestore_indexes_ads.txt 참고하여 수동 생성
```

### Phase 5: 빌드 및 테스트

```bash
# 릴리스 빌드
flutter build apk --release
flutter build ios --release

# 실기기에서 테스트
# - 실제 광고 표시 확인
# - 수익 발생 확인 (AdMob 콘솔)
```

### Phase 6: 스토어 제출

- [ ] Google Play Console에 APK/AAB 업로드
- [ ] App Store Connect에 IPA 업로드
- [ ] 개인정보 처리방침에 광고 사용 명시
- [ ] 스토어 리뷰 통과

---

## 수익 분석

### 예상 수익 (MAU 기준)

| MAU | 월 노출 | 월 수익 (배너) | 월 수익 (리워드) | 총 월 수익 | 연 수익 |
|-----|---------|---------------|-----------------|-----------|---------|
| 1,000 | 57만 | ₩28.5만 | ₩32만 | ₩60.5만 | ₩726만 |
| 5,000 | 285만 | ₩142.5만 | ₩160만 | ₩302.5만 | ₩3,630만 |
| **10,000** | **570만** | **₩285만** | **₩319만** | **₩604만** | **₩7,249만** |
| 50,000 | 2,850만 | ₩1,425만 | ₩1,596만 | ₩3,021만 | ₩3.6억 |
| 100,000 | 5,700만 | ₩2,850만 | ₩3,192만 | ₩6,042만 | ₩7.2억 |

### 수익 추정 방법

```dart
// AdAnalyticsService 사용 예시

final analytics = AdAnalyticsService();

// 1. 기간별 노출 횟수 조회
final stats = await analytics.getAdStatsByDateRange(
  startDate: DateTime(2025, 1, 1),
  endDate: DateTime(2025, 1, 31),
  eventType: AdEventType.impression,
);

int totalImpressions = stats.values.reduce((a, b) => a + b);

// 2. 수익 추정
double revenue = analytics.estimateRevenue(
  totalImpressions,
  ecpm: 500,  // 배너 광고 eCPM
);

print('예상 수익: ₩${revenue.toStringAsFixed(0)}');
```

---

## 문제 해결

### 문제 1: 광고가 표시되지 않음

**증상**: BannerAdWidget이 빈 공간으로 표시됨

**해결 방법**:
1. 네트워크 연결 확인
2. AdMob App ID가 올바른지 확인
3. 로그 확인: `onAdFailedToLoad` 에러 메시지
4. 테스트 모드에서 테스트 ID 사용 확인

```bash
# 로그 확인
flutter logs | grep "BannerAdWidget"

# 예상 출력:
# "Banner ad loaded successfully" ✅
# "Banner ad failed to load: ..." ❌ → 에러 메시지 확인
```

### 문제 2: 리워드 광고가 준비되지 않음

**증상**: "광고 준비 중" 다이얼로그 계속 표시

**해결 방법**:
1. `main.dart`에서 `RewardedAdManager().loadAd()` 호출 확인
2. 네트워크 상태 확인
3. AdMob 계정 상태 확인 (정지되지 않았는지)

```dart
// 광고 준비 상태 디버깅
final adManager = RewardedAdManager();
print('Ad ready: ${adManager.isAdReady}');
print('Ad loading: ${adManager.isAdLoading}');

// 수동 재로드
await adManager.loadAd();
```

### 문제 3: Firestore 로그가 기록되지 않음

**증상**: adInteractions 컬렉션이 비어있음

**해결 방법**:
1. Firestore 보안 규칙 확인
2. 사용자 로그인 상태 확인 (`FirebaseAuth.instance.currentUser`)
3. 네트워크 권한 확인

```bash
# Firestore 규칙 테스트
# Firebase Console > Firestore Database > 규칙 탭 > 시뮬레이터

# 테스트 시나리오:
# Collection: adInteractions
# Document path: testDoc123
# Authenticated: true
# auth.uid: USER_ID_HERE

# Expected: allow create
```

### 문제 4: 일일 제한이 리셋되지 않음

**증상**: 다음 날에도 "일일 시청 제한" 표시

**해결 방법**:
1. `UserModel.lastRewardedAdDate` 날짜 비교 로직 확인
2. 디바이스 시간대 설정 확인

```dart
// 디버깅 코드
final user = await UserService().getUser(userId);
print('Last ad date: ${user?.lastRewardedAdDate}');
print('Today: ${DateTime.now()}');
print('Same day: ${_isSameDay(DateTime.now(), user?.lastRewardedAdDate)}');
```

### 문제 5: 프리미엄 사용자에게 광고 표시됨

**증상**: `isPremium: true`인데 광고가 보임

**해결 방법**:
1. AuthProvider의 currentUser 값 확인
2. Firestore 사용자 문서 동기화 확인

```dart
// 디버깅
final authProvider = context.read<AuthProvider>();
print('Current user: ${authProvider.currentUser}');
print('Is premium: ${authProvider.currentUser?.isPremium}');
print('Show ads: ${authProvider.currentUser?.showBannerAds}');
```

---

## 참고 자료

- [Google Mobile Ads SDK 문서](https://developers.google.com/admob/flutter/quick-start)
- [AdMob 정책 센터](https://support.google.com/admob/answer/6128543)
- [Firestore 보안 규칙](https://firebase.google.com/docs/firestore/security/get-started)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices)

---

**작성일**: 2025-12-10
**버전**: 1.0
**작성자**: Claude Sonnet 4.5
