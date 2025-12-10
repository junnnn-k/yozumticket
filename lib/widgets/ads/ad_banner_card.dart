/// 게시물 목록용 광고 배너 카드
///
/// 게시물 카드와 유사한 디자인으로 광고를 표시합니다.
/// 무료 사용자에게만 표시되며, 프리미엄 사용자는 광고가 숨겨집니다.

import 'package:flutter/material.dart';
import 'banner_ad_widget.dart';

class AdBannerCard extends StatelessWidget {
  /// 광고 표시 위치 인덱스 (로깅용)
  final int position;

  /// 프리미엄 사용자 여부
  final bool isPremium;

  const AdBannerCard({
    super.key,
    required this.position,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    // 프리미엄 사용자는 광고 표시 안 함
    if (isPremium) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "광고" 라벨
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              '광고',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 배너 광고
          BannerAdWidget(
            placement: 'feed_position_$position',
          ),

          // 하단 여백
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
