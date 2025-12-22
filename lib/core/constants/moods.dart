/// 경기 관람 후 기분 이모지 상수
class Moods {
  // 기분 값 상수
  static const String excited = 'excited'; // 🤩 (대승, 역전승)
  static const String happy = 'happy'; // 😊 (승리)
  static const String normal = 'normal'; // 😐 (무승부, 접전)
  static const String sad = 'sad'; // 😢 (패배)
  static const String angry = 'angry'; // 😡 (대패)

  // 이모지 매핑
  static const Map<String, String> emojis = {
    excited: '🤩',
    happy: '😊',
    normal: '😐',
    sad: '😢',
    angry: '😡',
  };

  // 레이블 매핑
  static const Map<String, String> labels = {
    excited: '최고!',
    happy: '좋았어',
    normal: '그냥 그래',
    sad: '아쉬워',
    angry: '화나',
  };

  // 기분 리스트 (순서대로)
  static const List<String> all = [
    excited,
    happy,
    normal,
    sad,
    angry,
  ];

  // 별점을 기분으로 변환 (마이그레이션용)
  static String fromRating(double rating) {
    if (rating >= 4.5) return excited;
    if (rating >= 3.5) return happy;
    if (rating >= 2.5) return normal;
    if (rating >= 1.5) return sad;
    return angry;
  }

  // 기분을 별점으로 변환 (역호환성용)
  static double toRating(String mood) {
    switch (mood) {
      case excited:
        return 5.0;
      case happy:
        return 4.0;
      case normal:
        return 3.0;
      case sad:
        return 2.0;
      case angry:
        return 1.0;
      default:
        return 3.0; // 기본값
    }
  }

  // 이모지 가져오기
  static String getEmoji(String mood) {
    return emojis[mood] ?? '😐';
  }

  // 레이블 가져오기
  static String getLabel(String mood) {
    return labels[mood] ?? '그냥 그래';
  }

  // 유효성 검증
  static bool isValid(String mood) {
    return all.contains(mood);
  }
}
