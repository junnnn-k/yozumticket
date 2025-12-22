/// 티켓에서 추출한 경기 정보를 담는 모델 클래스
class GameInfo {
  final DateTime? date; // 경기 날짜
  final String? homeTeam; // 홈 팀
  final String? awayTeam; // 원정 팀
  final String? stadium; // 구장명
  final String? seatGrade; // 좌석 등급 (예: 블루석, 프리미엄석)
  final String? seat; // 좌석 번호 (예: 114블럭 24열 14번)
  final int? price; // 가격
  final double confidence; // 전체 신뢰도 (0.0 ~ 1.0)

  GameInfo({
    this.date,
    this.homeTeam,
    this.awayTeam,
    this.stadium,
    this.seatGrade,
    this.seat,
    this.price,
    this.confidence = 0.0,
  });

  /// 필수 정보가 모두 채워졌는지 확인
  bool get isComplete {
    return date != null &&
        homeTeam != null &&
        awayTeam != null &&
        stadium != null;
  }

  /// 신뢰도가 높은지 확인 (70% 이상)
  bool get isHighConfidence => confidence >= 0.7;

  /// 복사본 생성 (일부 필드만 업데이트)
  GameInfo copyWith({
    DateTime? date,
    String? homeTeam,
    String? awayTeam,
    String? stadium,
    String? seatGrade,
    String? seat,
    int? price,
    double? confidence,
  }) {
    return GameInfo(
      date: date ?? this.date,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      stadium: stadium ?? this.stadium,
      seatGrade: seatGrade ?? this.seatGrade,
      seat: seat ?? this.seat,
      price: price ?? this.price,
      confidence: confidence ?? this.confidence,
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'date': date?.toIso8601String(),
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'stadium': stadium,
      'seatGrade': seatGrade,
      'seat': seat,
      'price': price,
      'confidence': confidence,
    };
  }

  /// JSON 역직렬화
  factory GameInfo.fromJson(Map<String, dynamic> json) {
    return GameInfo(
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      homeTeam: json['homeTeam'],
      awayTeam: json['awayTeam'],
      stadium: json['stadium'],
      seatGrade: json['seatGrade'],
      seat: json['seat'],
      price: json['price'],
      confidence: json['confidence'] ?? 0.0,
    );
  }

  /// 디버깅용 문자열 표현
  @override
  String toString() {
    return 'GameInfo(date: $date, homeTeam: $homeTeam, awayTeam: $awayTeam, '
        'stadium: $stadium, seat: $seat, price: $price, confidence: $confidence)';
  }
}
