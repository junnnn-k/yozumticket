import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/material.dart';

/// OCR (광학 문자 인식) 서비스
/// Google ML Kit을 사용하여 이미지에서 텍스트 추출
class OcrService {
  // 기본 텍스트 인식기 (한국어, 영어, 숫자 모두 지원)
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// 이미지에서 텍스트 인식
  ///
  /// [imageFile] 분석할 이미지 파일
  ///
  /// Returns:
  ///   인식된 텍스트 객체
  Future<RecognizedText> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      debugPrint('=== OCR 처리 완료 ===');
      debugPrint('인식된 텍스트 블록 수: ${recognizedText.blocks.length}');

      return recognizedText;
    } catch (e) {
      debugPrint('OCR 처리 오류: $e');
      rethrow;
    }
  }

  /// 텍스트 블록 추출
  ///
  /// [recognizedText] 인식된 텍스트 객체
  ///
  /// Returns:
  ///   텍스트 블록 리스트
  List<TextBlock> extractTextBlocks(RecognizedText recognizedText) {
    return recognizedText.blocks;
  }

  /// 전체 텍스트 문자열 추출
  ///
  /// [recognizedText] 인식된 텍스트 객체
  ///
  /// Returns:
  ///   모든 텍스트를 하나의 문자열로 결합
  String extractFullText(RecognizedText recognizedText) {
    final StringBuffer buffer = StringBuffer();

    for (final block in recognizedText.blocks) {
      buffer.writeln(block.text);
    }

    return buffer.toString().trim();
  }

  /// 신뢰도 점수 계산
  ///
  /// [recognizedText] 인식된 텍스트 객체
  ///
  /// Returns:
  ///   평균 신뢰도 점수 (0.0 ~ 1.0)
  double calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int lineCount = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        // ML Kit의 confidence는 일반적으로 암묵적으로 높게 평가됨
        // 실제로는 텍스트 길이와 블록 수로 품질 추정
        lineCount++;
      }
    }

    // 간단한 휴리스틱: 많은 텍스트가 인식되면 신뢰도 높음
    if (lineCount > 10) {
      return 0.9;
    } else if (lineCount > 5) {
      return 0.7;
    } else if (lineCount > 0) {
      return 0.5;
    } else {
      return 0.0;
    }
  }

  /// 디버깅용 상세 로그 출력
  ///
  /// [recognizedText] 인식된 텍스트 객체
  void printDetailedLog(RecognizedText recognizedText) {
    debugPrint('\n========== OCR 상세 결과 ==========');
    debugPrint('총 블록 수: ${recognizedText.blocks.length}');
    debugPrint('신뢰도 점수: ${calculateConfidence(recognizedText).toStringAsFixed(2)}');
    debugPrint('\n--- 인식된 텍스트 ---');

    for (int i = 0; i < recognizedText.blocks.length; i++) {
      final block = recognizedText.blocks[i];
      debugPrint('\n[블록 $i]');
      debugPrint('블록 텍스트: ${block.text}');
      debugPrint('줄 수: ${block.lines.length}');

      for (int j = 0; j < block.lines.length; j++) {
        final line = block.lines[j];
        debugPrint('  줄 $j: ${line.text}');

        // 요소별 상세 정보 (선택사항)
        for (int k = 0; k < line.elements.length; k++) {
          final element = line.elements[k];
          debugPrint('    요소 $k: ${element.text}');
        }
      }
    }

    debugPrint('\n--- 전체 텍스트 (통합) ---');
    debugPrint(extractFullText(recognizedText));
    debugPrint('===================================\n');
  }

  /// 특정 패턴 검색
  ///
  /// [recognizedText] 인식된 텍스트 객체
  /// [pattern] 검색할 정규표현식
  ///
  /// Returns:
  ///   매칭된 문자열 리스트
  List<String> searchPattern(RecognizedText recognizedText, RegExp pattern) {
    final List<String> matches = [];
    final fullText = extractFullText(recognizedText);

    final Iterable<RegExpMatch> regExpMatches = pattern.allMatches(fullText);

    for (final match in regExpMatches) {
      if (match.group(0) != null) {
        matches.add(match.group(0)!);
      }
    }

    return matches;
  }

  /// 키워드 검색
  ///
  /// [recognizedText] 인식된 텍스트 객체
  /// [keywords] 검색할 키워드 리스트
  ///
  /// Returns:
  ///   발견된 키워드 리스트
  List<String> searchKeywords(RecognizedText recognizedText, List<String> keywords) {
    final List<String> foundKeywords = [];
    final fullText = extractFullText(recognizedText).toLowerCase();

    for (final keyword in keywords) {
      if (fullText.contains(keyword.toLowerCase())) {
        foundKeywords.add(keyword);
      }
    }

    return foundKeywords;
  }

  /// 리소스 정리
  void dispose() {
    _textRecognizer.close();
  }
}
