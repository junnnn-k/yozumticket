/// 리워드 광고 버튼 위젯
///
/// 사용자가 광고를 시청하고 보상을 받을 수 있는 버튼입니다.
/// 일일 시청 횟수를 표시하고, 제한을 초과하면 비활성화됩니다.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/rewarded_ad_manager.dart';
import '../../core/constants/ad_config.dart';

class RewardedAdButton extends StatefulWidget {
  /// 보상 타입
  final RewardType rewardType;

  /// 버튼 텍스트
  final String? buttonText;

  /// 보상 설명
  final String? rewardDescription;

  /// 보상 획득 후 콜백
  final VoidCallback? onRewardGranted;

  const RewardedAdButton({
    super.key,
    required this.rewardType,
    this.buttonText,
    this.rewardDescription,
    this.onRewardGranted,
  });

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  final RewardedAdManager _adManager = RewardedAdManager();
  int _remainingCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRemainingCount();
    // 광고 미리 로드
    _adManager.loadAd();
  }

  /// 남은 시청 횟수 로드 (보상 타입별)
  Future<void> _loadRemainingCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _remainingCount = 0;
        _isLoading = false;
      });
      return;
    }

    final count = await _adManager.getRemainingWatchCount(user.uid, widget.rewardType);
    if (mounted) {
      setState(() {
        _remainingCount = count;
        _isLoading = false;
      });
    }
  }

  /// 광고 시청
  Future<void> _watchAd() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() => _isLoading = true);

    final success = await _adManager.showRewardedAd(
      context: context,
      userId: user.uid,
      rewardType: widget.rewardType,
    );

    if (success) {
      widget.onRewardGranted?.call();
      await _loadRemainingCount();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 로그인 필요 다이얼로그
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그인 필요'),
        content: const Text('리워드 광고 시청은 로그인이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 기본 텍스트 설정
    final buttonText = widget.buttonText ?? _getDefaultButtonText();
    final rewardDesc = widget.rewardDescription ?? _getDefaultRewardDescription();

    // 버튼 활성화 여부
    final isEnabled = _remainingCount > 0 && !_isLoading;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isEnabled ? _watchAd : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 아이콘 + 제목
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isEnabled
                            ? [Colors.amber.shade400, Colors.orange.shade400]
                            : [Colors.grey.shade300, Colors.grey.shade400],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buttonText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isEnabled
                                ? theme.colorScheme.onSurface
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rewardDesc,
                          style: TextStyle(
                            fontSize: 13,
                            color: isEnabled
                                ? theme.colorScheme.onSurface.withOpacity(0.7)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 광고 준비 상태 표시
                  if (_adManager.isAdLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (!_adManager.isAdReady)
                    Icon(
                      Icons.error_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // 남은 횟수 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? theme.colorScheme.primaryContainer
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isEnabled
                          ? theme.colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLoading
                          ? '확인 중...'
                          : '오늘 $_remainingCount/${_getMaxCount()}회 남음',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isEnabled
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // 비활성화 시 안내 메시지
              if (_remainingCount == 0 && !_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '내일 다시 시청할 수 있습니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 보상 타입별 기본 버튼 텍스트
  String _getDefaultButtonText() {
    switch (widget.rewardType) {
      case RewardType.premiumTheme:
        return '광고 보고 프리미엄 테마 체험하기';
      case RewardType.extraPhoto:
        return '광고 보고 사진 추가 슬롯 받기';
    }
  }

  /// 보상 타입별 기본 설명
  String _getDefaultRewardDescription() {
    switch (widget.rewardType) {
      case RewardType.premiumTheme:
        return '프리미엄 테마를 1일 동안 무료로 사용해보세요';
      case RewardType.extraPhoto:
        return '다음 게시물에서 사진 20장 업로드 가능';
    }
  }

  /// 보상 타입별 최대 횟수
  int _getMaxCount() {
    switch (widget.rewardType) {
      case RewardType.premiumTheme:
        return AdConfig.maxDailyPremiumThemeAds;
      case RewardType.extraPhoto:
        return AdConfig.maxDailyExtraPhotoAds;
    }
  }
}
