/// 광고 분석 서비스
///
/// 광고 노출, 클릭, 리워드 지급 등의 이벤트를 Firestore에 기록합니다.
/// 수익 분석 및 사용자 행동 분석에 사용됩니다.

import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ad_interaction_model.dart';

class AdAnalyticsService {
  static final AdAnalyticsService _instance = AdAnalyticsService._internal();
  factory AdAnalyticsService() => _instance;
  AdAnalyticsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'adInteractions';

  /// 광고 이벤트 기록
  Future<void> logAdEvent({
    required String userId,
    required AdType adType,
    required AdEventType eventType,
    required String adUnitId,
    String? placement,
    String? rewardType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final interaction = AdInteraction(
        id: '', // Firestore가 자동 생성
        userId: userId,
        adType: adType,
        eventType: eventType,
        adUnitId: adUnitId,
        placement: placement,
        rewardType: rewardType,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _firestore.collection(_collectionName).add(interaction.toMap());

      dev.log(
        'Ad event logged: ${eventType.name} - ${adType.name} - $placement',
        name: 'AdAnalyticsService',
      );
    } catch (e, stackTrace) {
      dev.log(
        'Failed to log ad event: $e',
        name: 'AdAnalyticsService',
        error: e,
        stackTrace: stackTrace,
      );
      // 로깅 실패는 앱 기능에 영향을 주지 않으므로 에러를 던지지 않음
    }
  }

  /// 배너 광고 노출 기록
  Future<void> logBannerImpression({
    required String userId,
    required String adUnitId,
    String? placement,
  }) async {
    await logAdEvent(
      userId: userId,
      adType: AdType.banner,
      eventType: AdEventType.impression,
      adUnitId: adUnitId,
      placement: placement,
    );
  }

  /// 배너 광고 클릭 기록
  Future<void> logBannerClick({
    required String userId,
    required String adUnitId,
    String? placement,
  }) async {
    await logAdEvent(
      userId: userId,
      adType: AdType.banner,
      eventType: AdEventType.click,
      adUnitId: adUnitId,
      placement: placement,
    );
  }

  /// 리워드 광고 노출 기록
  Future<void> logRewardedImpression({
    required String userId,
    required String adUnitId,
    String? rewardType,
  }) async {
    await logAdEvent(
      userId: userId,
      adType: AdType.rewarded,
      eventType: AdEventType.impression,
      adUnitId: adUnitId,
      rewardType: rewardType,
    );
  }

  /// 리워드 광고 보상 지급 기록
  Future<void> logRewardGranted({
    required String userId,
    required String adUnitId,
    required String rewardType,
    Map<String, dynamic>? metadata,
  }) async {
    await logAdEvent(
      userId: userId,
      adType: AdType.rewarded,
      eventType: AdEventType.rewarded,
      adUnitId: adUnitId,
      rewardType: rewardType,
      metadata: metadata,
    );
  }

  /// 광고 로딩 실패 기록
  Future<void> logAdFailed({
    required String userId,
    required AdType adType,
    required String adUnitId,
    String? placement,
    String? errorMessage,
  }) async {
    await logAdEvent(
      userId: userId,
      adType: adType,
      eventType: AdEventType.failed,
      adUnitId: adUnitId,
      placement: placement,
      metadata: errorMessage != null ? {'error': errorMessage} : null,
    );
  }

  /// 사용자별 광고 상호작용 조회
  Future<List<AdInteraction>> getUserAdInteractions(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AdInteraction.fromFirestore(doc))
          .toList();
    } catch (e) {
      dev.log(
        'Failed to get user ad interactions: $e',
        name: 'AdAnalyticsService',
        error: e,
      );
      return [];
    }
  }

  /// 기간별 광고 통계 조회
  Future<Map<String, int>> getAdStatsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    AdType? adType,
    AdEventType? eventType,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      if (adType != null) {
        query = query.where('adType', isEqualTo: adType.name);
      }

      if (eventType != null) {
        query = query.where('eventType', isEqualTo: eventType.name);
      }

      final snapshot = await query.get();

      // 날짜별 집계
      final stats = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final dateKey =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

        stats[dateKey] = (stats[dateKey] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      dev.log(
        'Failed to get ad stats: $e',
        name: 'AdAnalyticsService',
        error: e,
      );
      return {};
    }
  }

  /// 사용자별 일일 광고 노출 횟수 조회
  Future<int> getDailyImpressionCount(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('eventType', isEqualTo: AdEventType.impression.name)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      dev.log(
        'Failed to get daily impression count: $e',
        name: 'AdAnalyticsService',
        error: e,
      );
      return 0;
    }
  }

  /// 수익 추정 (eCPM 기반)
  ///
  /// [impressionCount] 노출 횟수
  /// [ecpm] eCPM (1000회 노출당 수익, 원 단위)
  double estimateRevenue(int impressionCount, {double ecpm = 500}) {
    return (impressionCount / 1000) * ecpm;
  }

  /// 배치 삭제 (90일 이상 된 데이터 정리)
  Future<void> cleanupOldData({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(500) // 배치 크기 제한
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      dev.log(
        'Cleaned up ${snapshot.docs.length} old ad interaction records',
        name: 'AdAnalyticsService',
      );
    } catch (e) {
      dev.log(
        'Failed to cleanup old data: $e',
        name: 'AdAnalyticsService',
        error: e,
      );
    }
  }
}
