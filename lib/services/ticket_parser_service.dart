import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/game_info.dart';
import '../core/constants/baseball_data.dart';

/// 티켓 OCR 결과에서 경기 정보를 파싱하는 서비스
class TicketParserService {
  /// 전체 티켓 정보 파싱 (메인 메서드)
  GameInfo parseTicketInfo(RecognizedText recognizedText) {
    // 모든 텍스트를 하나의 문자열로 결합
    final fullText = recognizedText.blocks.map((block) => block.text).join('\n');

    // 각 정보 추출
    final date = extractDate(fullText);
    final teams = extractTeams(fullText);
    final stadium = extractStadium(fullText, teams);
    final seat = extractSeat(fullText);
    final price = extractPrice(fullText);

    // 신뢰도 계산 (추출된 필수 정보 개수 기반)
    double confidence = _calculateConfidence(date, teams, stadium, seat, price);

    return GameInfo(
      date: date,
      homeTeam: teams?['home'],
      awayTeam: teams?['away'],
      stadium: stadium,
      seat: seat,
      price: price,
      confidence: confidence,
    );
  }

  /// 날짜 추출 (여러 패턴 지원)
  DateTime? extractDate(String text) {
    // 패턴 1: YYYY.MM.DD, YYYY-MM-DD, YYYY/MM/DD
    final pattern1 = RegExp(r'(\d{4})[.\-/](\d{1,2})[.\-/](\d{1,2})');
    final match1 = pattern1.firstMatch(text);
    if (match1 != null) {
      try {
        final year = int.parse(match1.group(1)!);
        final month = int.parse(match1.group(2)!);
        final day = int.parse(match1.group(3)!);
        return DateTime(year, month, day);
      } catch (e) {
        // 파싱 실패 시 다음 패턴 시도
      }
    }

    // 패턴 2: MM.DD (현재 연도 또는 다음 연도)
    final pattern2 = RegExp(r'(\d{1,2})[.\-/](\d{1,2})');
    final match2 = pattern2.firstMatch(text);
    if (match2 != null) {
      try {
        final month = int.parse(match2.group(1)!);
        final day = int.parse(match2.group(2)!);
        final now = DateTime.now();

        // 현재 연도로 시도
        var date = DateTime(now.year, month, day);

        // 과거 날짜라면 다음 연도로 설정 (시즌권 등)
        if (date.isBefore(now.subtract(const Duration(days: 30)))) {
          date = DateTime(now.year + 1, month, day);
        }

        return date;
      } catch (e) {
        // 파싱 실패
      }
    }

    // 패턴 3: M월 D일
    final pattern3 = RegExp(r'(\d{1,2})월\s*(\d{1,2})일');
    final match3 = pattern3.firstMatch(text);
    if (match3 != null) {
      try {
        final month = int.parse(match3.group(1)!);
        final day = int.parse(match3.group(2)!);
        final now = DateTime.now();

        var date = DateTime(now.year, month, day);

        if (date.isBefore(now.subtract(const Duration(days: 30)))) {
          date = DateTime(now.year + 1, month, day);
        }

        return date;
      } catch (e) {
        // 파싱 실패
      }
    }

    return null;
  }

  /// 팀명 추출 (홈팀 vs 원정팀)
  Map<String, String?>? extractTeams(String text) {
    final foundTeams = <String>[];

    // 텍스트에서 모든 팀명 찾기
    for (final entry in BaseballData.teamAliases.entries) {
      if (text.contains(entry.key)) {
        final normalizedTeam = entry.value;
        if (!foundTeams.contains(normalizedTeam)) {
          foundTeams.add(normalizedTeam);
        }
      }
    }

    // 2개 팀을 찾은 경우
    if (foundTeams.length >= 2) {
      // vs, VS, 대, : 등의 구분자 찾기
      final vsPattern = RegExp(r'(vs|VS|대|:)');
      final vsMatch = vsPattern.firstMatch(text);

      if (vsMatch != null) {
        // 구분자 위치를 기준으로 홈/원정 구분
        final vsPosition = vsMatch.start;
        final team1Position = text.indexOf(foundTeams[0]);
        final team2Position = text.indexOf(foundTeams[1]);

        if (team1Position < vsPosition && team2Position > vsPosition) {
          return {'home': foundTeams[0], 'away': foundTeams[1]};
        } else if (team2Position < vsPosition && team1Position > vsPosition) {
          return {'home': foundTeams[1], 'away': foundTeams[0]};
        }
      }

      // 구분자가 없으면 순서대로 반환
      return {'home': foundTeams[0], 'away': foundTeams[1]};
    }

    // 1개만 찾은 경우
    if (foundTeams.length == 1) {
      return {'home': foundTeams[0], 'away': null};
    }

    return null;
  }

  /// 구장명 추출
  String? extractStadium(String text, Map<String, String?>? teams) {
    // 텍스트에서 구장 키워드 찾기
    for (final entry in BaseballData.stadiums.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    // 구장을 못 찾았지만 홈팀을 알면 홈 구장 추론
    if (teams != null && teams['home'] != null) {
      return BaseballData.teamHomeStadium[teams['home']];
    }

    return null;
  }

  /// 좌석 정보 추출
  String? extractSeat(String text) {
    // 좌석 정보 패턴 찾기
    final seatPatterns = [
      // 패턴 1: 1루 블루존 203-5
      RegExp(r'([1-3]루|중앙|외야)\s*([가-힣A-Za-z]+존|[가-힣A-Za-z]+석)\s*(\d{1,3}[-\s]*\d{1,3})'),

      // 패턴 2: 블루존 203-5
      RegExp(r'([가-힣A-Za-z]+존|[가-힣A-Za-z]+석)\s*(\d{1,3}[-\s]*\d{1,3})'),

      // 패턴 3: 203구역 5번
      RegExp(r'(\d{1,3})\s*구역\s*(\d{1,3})\s*번'),

      // 패턴 4: 좌석 번호만 (블루존, 레드존 등)
      RegExp(r'(블루존|레드존|오렌지존|그린존|네이비존|스카이존|프리미엄|테이블석|익사이팅존|응원석|지정석|자유석)\s*(\d{1,3}[-\s]*\d{1,3})'),

      // 패턴 5: 연속된 숫자 3개 (블럭 열 번) - 예: "114 24 14"
      RegExp(r'(\d{2,3})\s+(\d{2,3})\s+(\d{1,3})'),
    ];

    for (final pattern in seatPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        // 패턴 5인 경우 "블럭-열-번" 형식으로 재구성
        if (pattern == seatPatterns[4]) {
          return '${match.group(1)}블럭 ${match.group(2)}열 ${match.group(3)}번';
        }
        return match.group(0)?.trim();
      }
    }

    return null;
  }

  /// 가격 정보 추출
  int? extractPrice(String text) {
    // 가격 패턴: 숫자 + 원
    final pricePatterns = [
      // 패턴 1: 15,000원, 15000원
      RegExp(r'(\d{1,3}(?:,\d{3})*)\s*원'),

      // 패턴 2: ₩15,000, KRW 15,000
      RegExp(r'[₩KRW]\s*(\d{1,3}(?:,\d{3})*)'),

      // 패턴 3: 금액: 15000
      RegExp(r'금액[:：]\s*(\d{1,3}(?:,\d{3})*)'),

      // 패턴 4: 콤마 포함 숫자만 (예: "32,000") - OCR에서 "원"이 누락된 경우
      RegExp(r'(\d{1,3}(?:,\d{3})+)(?!\d)'),
    ];

    for (final pattern in pricePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final priceString = match.group(1)?.replaceAll(',', '');
          if (priceString != null) {
            final price = int.parse(priceString);
            // 유효한 가격 범위 체크 (1,000원 ~ 100,000원)
            if (price >= 1000 && price <= 100000) {
              return price;
            }
          }
        } catch (e) {
          // 파싱 실패 시 다음 패턴 시도
        }
      }
    }

    return null;
  }

  /// 신뢰도 계산 (0.0 ~ 1.0)
  double _calculateConfidence(
    DateTime? date,
    Map<String, String?>? teams,
    String? stadium,
    String? seat,
    int? price,
  ) {
    double score = 0.0;

    // 날짜 (25% - 가장 중요)
    if (date != null) score += 0.25;

    // 홈팀 (15%)
    if (teams != null && teams['home'] != null) score += 0.15;

    // 원정팀 (15%)
    if (teams != null && teams['away'] != null) score += 0.15;

    // 구장 (15%)
    if (stadium != null) score += 0.15;

    // 좌석 (15%)
    if (seat != null) score += 0.15;

    // 가격 (15%)
    if (price != null) score += 0.15;

    return score;
  }

  /// 디버깅용: 파싱 과정 상세 로그
  void printParsingDetails(RecognizedText recognizedText, GameInfo gameInfo) {
    print('========== 티켓 파싱 상세 정보 ==========');
    print('원본 텍스트:');
    for (var block in recognizedText.blocks) {
      print('  - ${block.text}');
    }
    print('\n파싱 결과:');
    print('  날짜: ${gameInfo.date}');
    print('  홈팀: ${gameInfo.homeTeam}');
    print('  원정팀: ${gameInfo.awayTeam}');
    print('  구장: ${gameInfo.stadium}');
    print('  좌석: ${gameInfo.seat}');
    print('  가격: ${gameInfo.price}원');
    print('  신뢰도: ${(gameInfo.confidence * 100).toStringAsFixed(1)}%');
    print('  완성도: ${gameInfo.isComplete ? "완료" : "불완전"}');
    print('=========================================');
  }
}
