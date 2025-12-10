/// 광고 노출 및 상호작용 모델
///
/// 광고 표시, 클릭, 보상 지급 등의 이벤트를 추적합니다.
/// 분석 및 수익 추정에 사용됩니다.

import 'package:cloud_firestore/cloud_firestore.dart';

/// 광고 타입
enum AdType {
  banner,   // 배너 광고
  rewarded, // 리워드 광고
}

/// 광고 이벤트 타입
enum AdEventType {
  impression, // 노출 (과금 기준)
  click,      // 클릭
  rewarded,   // 리워드 지급
  failed,     // 로딩 실패
}

class AdInteraction {
  final String id;
  final String userId;           // 사용자 ID
  final AdType adType;           // 광고 타입
  final AdEventType eventType;   // 이벤트 타입
  final String adUnitId;         // 광고 단위 ID
  final String? placement;       // 광고 위치 (예: "feed_position_0")
  final String? rewardType;      // 리워드 타입 (리워드 광고만)
  final DateTime timestamp;      // 이벤트 발생 시각
  final Map<String, dynamic>? metadata; // 추가 메타데이터

  AdInteraction({
    required this.id,
    required this.userId,
    required this.adType,
    required this.eventType,
    required this.adUnitId,
    this.placement,
    this.rewardType,
    required this.timestamp,
    this.metadata,
  });

  /// Firestore 문서로 변환
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'adType': adType.name,
      'eventType': eventType.name,
      'adUnitId': adUnitId,
      'placement': placement,
      'rewardType': rewardType,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  /// Firestore 문서에서 생성
  factory AdInteraction.fromMap(String id, Map<String, dynamic> map) {
    return AdInteraction(
      id: id,
      userId: map['userId'] as String,
      adType: AdType.values.firstWhere(
        (e) => e.name == map['adType'],
        orElse: () => AdType.banner,
      ),
      eventType: AdEventType.values.firstWhere(
        (e) => e.name == map['eventType'],
        orElse: () => AdEventType.impression,
      ),
      adUnitId: map['adUnitId'] as String,
      placement: map['placement'] as String?,
      rewardType: map['rewardType'] as String?,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Firestore 문서 스냅샷에서 생성
  factory AdInteraction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdInteraction.fromMap(doc.id, data);
  }

  /// 복사본 생성
  AdInteraction copyWith({
    String? id,
    String? userId,
    AdType? adType,
    AdEventType? eventType,
    String? adUnitId,
    String? placement,
    String? rewardType,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AdInteraction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      adType: adType ?? this.adType,
      eventType: eventType ?? this.eventType,
      adUnitId: adUnitId ?? this.adUnitId,
      placement: placement ?? this.placement,
      rewardType: rewardType ?? this.rewardType,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'AdInteraction(id: $id, userId: $userId, adType: $adType, '
        'eventType: $eventType, placement: $placement, timestamp: $timestamp)';
  }
}
