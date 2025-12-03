import 'package:flutter/material.dart';

/// 배지 타입
enum BadgeType {
  firstVisit, // 첫 관람
  visit10, // 10회 관람
  visit50, // 50회 관람
  visit100, // 100회 관람
  allStars, // 올스타전 참여
  allStadiums, // 모든 구장 방문
  loyalFan, // 특정 팀 10회 응원
}

/// 배지 모델
class Badge {
  final BadgeType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  const Badge({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });

  Badge copyWith({
    BadgeType? type,
    String? title,
    String? description,
    IconData? icon,
    Color? color,
    bool? isUnlocked,
  }) {
    return Badge(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}

/// 배지 상수
class Badges {
  static const firstVisit = Badge(
    type: BadgeType.firstVisit,
    title: '첫 관람',
    description: '첫 경기 관람을 기록했습니다',
    icon: Icons.celebration,
    color: Colors.amber,
    isUnlocked: false,
  );

  static const visit10 = Badge(
    type: BadgeType.visit10,
    title: '야구 팬',
    description: '10경기 관람 달성',
    icon: Icons.sports_baseball,
    color: Colors.blue,
    isUnlocked: false,
  );

  static const visit50 = Badge(
    type: BadgeType.visit50,
    title: '열혈 팬',
    description: '50경기 관람 달성',
    icon: Icons.local_fire_department,
    color: Colors.orange,
    isUnlocked: false,
  );

  static const visit100 = Badge(
    type: BadgeType.visit100,
    title: '야구 광',
    description: '100경기 관람 달성',
    icon: Icons.emoji_events,
    color: Colors.purple,
    isUnlocked: false,
  );

  static const allStars = Badge(
    type: BadgeType.allStars,
    title: '올스타',
    description: '올스타전 참여',
    icon: Icons.stars,
    color: Colors.yellow,
    isUnlocked: false,
  );

  static const allStadiums = Badge(
    type: BadgeType.allStadiums,
    title: '구장 정복',
    description: '모든 구장 방문 완료',
    icon: Icons.stadium,
    color: Colors.green,
    isUnlocked: false,
  );

  static const loyalFan = Badge(
    type: BadgeType.loyalFan,
    title: '충성 팬',
    description: '특정 팀 10회 응원',
    icon: Icons.favorite,
    color: Colors.red,
    isUnlocked: false,
  );

  /// 모든 배지 목록
  static List<Badge> getAllBadges() {
    return [
      firstVisit,
      visit10,
      visit50,
      visit100,
      allStars,
      allStadiums,
      loyalFan,
    ];
  }
}

/// 배지 획득 조건 체크
class BadgeChecker {
  /// 획득한 배지 목록 반환
  static List<Badge> checkBadges(Map<String, dynamic> stats) {
    final unlockedBadges = <Badge>[];
    final totalCount = stats['totalCount'] as int;
    final stadiumCounts = stats['stadiumCounts'] as Map<String, int>;
    final teamCounts = stats['teamCounts'] as Map<String, int>;

    // 첫 관람
    if (totalCount >= 1) {
      unlockedBadges.add(Badges.firstVisit.copyWith(isUnlocked: true));
    }

    // 10회 관람
    if (totalCount >= 10) {
      unlockedBadges.add(Badges.visit10.copyWith(isUnlocked: true));
    }

    // 50회 관람
    if (totalCount >= 50) {
      unlockedBadges.add(Badges.visit50.copyWith(isUnlocked: true));
    }

    // 100회 관람
    if (totalCount >= 100) {
      unlockedBadges.add(Badges.visit100.copyWith(isUnlocked: true));
    }

    // 모든 구장 방문 (9개 구장)
    if (stadiumCounts.length >= 9) {
      unlockedBadges.add(Badges.allStadiums.copyWith(isUnlocked: true));
    }

    // 충성 팬 (특정 팀 10회 이상)
    final hasLoyalTeam = teamCounts.values.any((count) => count >= 10);
    if (hasLoyalTeam) {
      unlockedBadges.add(Badges.loyalFan.copyWith(isUnlocked: true));
    }

    // TODO: 올스타전 배지는 게시글의 태그나 경기 데이터로 판단 필요

    return unlockedBadges;
  }

  /// 잠긴 배지 목록 반환
  static List<Badge> getLockedBadges(List<Badge> unlockedBadges) {
    final allBadges = Badges.getAllBadges();
    final unlockedTypes = unlockedBadges.map((b) => b.type).toSet();

    return allBadges
        .where((badge) => !unlockedTypes.contains(badge.type))
        .toList();
  }
}
