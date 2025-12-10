/// 리워드 광고 관리자
///
/// 리워드 광고 로딩, 표시, 보상 처리를 담당합니다.
/// 일일 3회 시청 제한을 포함합니다.

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/constants/ad_config.dart';
import '../services/ad_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

/// 리워드 타입
enum RewardType {
  premiumTheme,  // 프리미엄 테마 1일 체험
  extraPhoto,    // 추가 사진 1회 (20장)
}

class RewardedAdManager {
  static final RewardedAdManager _instance = RewardedAdManager._internal();
  factory RewardedAdManager() => _instance;
  RewardedAdManager._internal();

  final UserService _userService = UserService();

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isAdReady = false;

  /// 광고 준비 상태
  bool get isAdReady => _isAdReady;

  /// 광고 로딩 중 상태
  bool get isAdLoading => _isAdLoading;

  /// 리워드 광고 로드
  Future<void> loadAd() async {
    if (_isAdLoading || _isAdReady) {
      dev.log('Ad already loading or ready', name: 'RewardedAdManager');
      return;
    }

    if (!AdService().isInitialized) {
      dev.log('AdMob SDK not initialized', name: 'RewardedAdManager');
      return;
    }

    _isAdLoading = true;

    dev.log('Loading rewarded ad...', name: 'RewardedAdManager');

    await RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: AdService().createAdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          dev.log('Rewarded ad loaded successfully', name: 'RewardedAdManager');
          _rewardedAd = ad;
          _isAdReady = true;
          _isAdLoading = false;

          // 광고 이벤트 리스너 설정
          _setupAdCallbacks();
        },
        onAdFailedToLoad: (error) {
          dev.log(
            'Rewarded ad failed to load: $error',
            name: 'RewardedAdManager',
            error: error,
          );
          _isAdLoading = false;
          _isAdReady = false;
          _rewardedAd = null;
        },
      ),
    );
  }

  /// 광고 이벤트 콜백 설정
  void _setupAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        dev.log('Rewarded ad showed full screen', name: 'RewardedAdManager');
      },
      onAdDismissedFullScreenContent: (ad) {
        dev.log('Rewarded ad dismissed', name: 'RewardedAdManager');
        ad.dispose();
        _rewardedAd = null;
        _isAdReady = false;
        // 자동으로 다음 광고 로드
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        dev.log(
          'Rewarded ad failed to show: $error',
          name: 'RewardedAdManager',
          error: error,
        );
        ad.dispose();
        _rewardedAd = null;
        _isAdReady = false;
        // 재시도
        loadAd();
      },
      onAdImpression: (ad) {
        dev.log('Rewarded ad impression', name: 'RewardedAdManager');
      },
    );
  }

  /// 일일 리워드 광고 시청 가능 여부 확인
  Future<bool> canWatchRewardedAd(String userId) async {
    try {
      final user = await _userService.getUser(userId);
      if (user == null) return false;

      // 일일 제한 확인
      final today = DateTime.now();
      final lastAdDate = user.lastRewardedAdDate;

      // 날짜가 다르면 카운터 리셋
      if (lastAdDate == null ||
          !_isSameDay(today, lastAdDate)) {
        return true;
      }

      // 오늘 시청 횟수 확인
      return user.dailyRewardedAdCount < AdConfig.maxDailyRewardedAds;
    } catch (e) {
      dev.log('Error checking rewarded ad availability: $e',
          name: 'RewardedAdManager', error: e);
      return false;
    }
  }

  /// 남은 리워드 광고 시청 횟수 조회
  Future<int> getRemainingWatchCount(String userId) async {
    try {
      final user = await _userService.getUser(userId);
      if (user == null) return 0;

      final today = DateTime.now();
      final lastAdDate = user.lastRewardedAdDate;

      // 날짜가 다르면 전체 횟수 반환
      if (lastAdDate == null || !_isSameDay(today, lastAdDate)) {
        return AdConfig.maxDailyRewardedAds;
      }

      // 남은 횟수 계산
      final remaining = AdConfig.maxDailyRewardedAds - user.dailyRewardedAdCount;
      return (remaining > 0 ? remaining : 0).toInt();
    } catch (e) {
      dev.log('Error getting remaining watch count: $e',
          name: 'RewardedAdManager', error: e);
      return 0;
    }
  }

  /// 리워드 광고 표시 및 보상 처리
  Future<bool> showRewardedAd({
    required BuildContext context,
    required String userId,
    required RewardType rewardType,
  }) async {
    // 시청 가능 여부 확인
    final canWatch = await canWatchRewardedAd(userId);
    if (!canWatch) {
      _showDailyLimitDialog(context);
      return false;
    }

    // 광고 준비 확인
    if (!_isAdReady || _rewardedAd == null) {
      _showAdNotReadyDialog(context);
      return false;
    }

    bool rewardGranted = false;

    // 광고 표시
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) async {
        dev.log(
          'User earned reward: ${reward.amount} ${reward.type}',
          name: 'RewardedAdManager',
        );

        // 보상 지급
        rewardGranted = await _grantReward(userId, rewardType);

        // 일일 카운터 증가
        await _userService.incrementRewardedAdCount(userId);

        if (context.mounted) {
          _showRewardSuccessDialog(context, rewardType);
        }
      },
    );

    return rewardGranted;
  }

  /// 보상 지급
  Future<bool> _grantReward(String userId, RewardType rewardType) async {
    try {
      switch (rewardType) {
        case RewardType.premiumTheme:
          // TODO: 프리미엄 테마 1일 임시 활성화
          dev.log('Granting premium theme access for 1 day',
              name: 'RewardedAdManager');
          // 향후 구현: 임시 프리미엄 기능 추가
          return true;

        case RewardType.extraPhoto:
          // TODO: 추가 사진 1회 권한 부여
          dev.log('Granting extra photo slot (20 photos)',
              name: 'RewardedAdManager');
          // 향후 구현: 임시 사진 제한 상승
          return true;
      }
    } catch (e) {
      dev.log('Error granting reward: $e',
          name: 'RewardedAdManager', error: e);
      return false;
    }
  }

  /// 일일 제한 도달 다이얼로그
  void _showDailyLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일일 시청 제한'),
        content: Text(
          '오늘 리워드 광고 시청 횟수를 모두 사용했습니다.\n'
          '내일 다시 시도해주세요!\n\n'
          '일일 제한: ${AdConfig.maxDailyRewardedAds}회',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 광고 준비 안 됨 다이얼로그
  void _showAdNotReadyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('광고 준비 중'),
        content: const Text(
          '광고를 불러오는 중입니다.\n'
          '잠시 후 다시 시도해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 보상 성공 다이얼로그
  void _showRewardSuccessDialog(BuildContext context, RewardType rewardType) {
    String message;
    switch (rewardType) {
      case RewardType.premiumTheme:
        message = '프리미엄 테마를 1일 동안 사용할 수 있습니다!';
        break;
      case RewardType.extraPhoto:
        message = '다음 게시물에서 사진을 20장까지 추가할 수 있습니다!';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.amber),
            SizedBox(width: 8),
            Text('보상 획득!'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 같은 날인지 확인
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 리소스 정리
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdReady = false;
    _isAdLoading = false;
  }
}
