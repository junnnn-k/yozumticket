/// 배너 광고 위젯
///
/// Google AdMob 배너 광고를 표시하는 재사용 가능한 위젯입니다.
/// 게시물 목록 등에서 7개당 1개씩 표시됩니다.

import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/constants/ad_config.dart';
import '../../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  /// 광고 표시 위치 식별자 (로깅용)
  final String placement;

  const BannerAdWidget({
    super.key,
    this.placement = 'default',
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdFailed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  /// 배너 광고 로드
  void _loadAd() {
    // AdMob SDK 초기화 확인
    if (!AdService().isInitialized) {
      dev.log(
        'AdMob SDK not initialized, skipping ad load',
        name: 'BannerAdWidget',
      );
      setState(() => _isAdFailed = true);
      return;
    }

    dev.log(
      'Loading banner ad for placement: ${widget.placement}',
      name: 'BannerAdWidget',
    );

    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: AdSize.banner, // 320x50
      request: AdService().createAdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          dev.log(
            'Banner ad loaded successfully (${widget.placement})',
            name: 'BannerAdWidget',
          );
          if (mounted) {
            setState(() => _isAdLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          dev.log(
            'Banner ad failed to load (${widget.placement}): $error',
            name: 'BannerAdWidget',
            error: error,
          );
          ad.dispose();
          if (mounted) {
            setState(() => _isAdFailed = true);
          }
        },
        onAdOpened: (ad) {
          dev.log(
            'Banner ad opened (${widget.placement})',
            name: 'BannerAdWidget',
          );
        },
        onAdClosed: (ad) {
          dev.log(
            'Banner ad closed (${widget.placement})',
            name: 'BannerAdWidget',
          );
        },
        onAdImpression: (ad) {
          dev.log(
            'Banner ad impression (${widget.placement})',
            name: 'BannerAdWidget',
          );
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 광고 로딩 실패 시 빈 컨테이너
    if (_isAdFailed) {
      return const SizedBox.shrink();
    }

    // 광고 로딩 중
    if (!_isAdLoaded || _bannerAd == null) {
      return Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // 광고 표시
    return Container(
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
