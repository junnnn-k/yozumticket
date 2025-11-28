import 'package:flutter/material.dart';

/// 앱 테마 타입
enum AppThemeType {
  diary,    // 일기장 스타일
  album,    // 앨범 스타일
  stadium,  // 야구장 스타일
}

/// 테마별 색상 팔레트와 설정
class AppThemes {
  AppThemes._();

  // ============================================
  // Theme 1: Diary Style (일기장 스타일)
  // - 따뜻한 크림/아이보리 톤
  // - 부드러운 느낌
  // HTML 프로토타입 참조: theme1_diary.html
  // ============================================
  static ThemeData get diaryTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // 기본 색상
      colorScheme: const ColorScheme.light(
        // 주요 색상 - 따뜻한 브라운 (#8B7355)
        primary: Color(0xFF8B7355),
        primaryContainer: Color(0xFFFFF9E6),
        onPrimary: Color(0xFFFFFFFF),
        onPrimaryContainer: Color(0xFF3A3A3A),

        // 보조 색상 - 부드러운 핑크 (#FFB6C1)
        secondary: Color(0xFFFFB6C1),
        secondaryContainer: Color(0xFFA8D8EA),  // 블루 강조색
        onSecondary: Color(0xFFFFFFFF),
        onSecondaryContainer: Color(0xFF3A3A3A),

        // 배경
        surface: Color(0xFFFFFEF9),  // 컨테이너 배경
        onSurface: Color(0xFF3A3A3A),

        // 에러
        error: Color(0xFFBA1A1A),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),

        // 기타
        outline: Color(0xFFA0826D),
        shadow: Color(0xFF000000),
        inverseSurface: Color(0xFF3A3A3A),
        onInverseSurface: Color(0xFFFFFEF9),
      ),

      // 카드 테마
      cardTheme: CardTheme(
        color: const Color(0xFFFFFFFF),
        elevation: 2,
        shadowColor: const Color(0xFFA8D8EA).withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFFFFF9E6),
            width: 2,
          ),
        ),
      ),

      // 앱바 테마
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFF9E6),
        foregroundColor: Color(0xFF8B7355),
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // ============================================
  // Theme 2: Album Style (앨범 스타일)
  // - 화이트/골드 톤
  // - 고급스럽고 세련된 느낌
  // HTML 프로토타입 참조: theme2_album.html
  // ============================================
  static ThemeData get albumTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.light(
        // 주요 색상 - 블루 (#1E3A8A, #3B82F6)
        primary: Color(0xFF1E3A8A),
        primaryContainer: Color(0xFF3B82F6),
        onPrimary: Color(0xFFFFFFFF),
        onPrimaryContainer: Color(0xFFFFFFFF),

        // 보조 색상 - 골드 (#D4AF37, #FFD700)
        secondary: Color(0xFFD4AF37),
        secondaryContainer: Color(0xFFFFD700),
        onSecondary: Color(0xFFFFFFFF),
        onSecondaryContainer: Color(0xFF000000),

        // 배경
        surface: Color(0xFFFFFFFF),  // 순백색
        onSurface: Color(0xFF000000),

        // 에러
        error: Color(0xFFBA1A1A),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),

        // 기타
        outline: Color(0xFFE5E5E5),
        shadow: Color(0xFF000000),
        inverseSurface: Color(0xFF313030),
        onInverseSurface: Color(0xFFF4EFF4),
      ),

      cardTheme: CardTheme(
        color: const Color(0xFFFAFAFA),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(
            color: Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E3A8A),
        foregroundColor: Color(0xFFFFFFFF),
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // ============================================
  // Theme 3: Stadium Style (야구장 스타일)
  // - 그린/골드 톤
  // - 역동적이고 스포티한 느낌
  // HTML 프로토타입 참조: theme3_stadium.html
  // ============================================
  static ThemeData get stadiumTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        // 주요 색상 - 골드 (#FFD700)
        primary: Color(0xFFFFD700),
        primaryContainer: Color(0xFFFFA500),
        onPrimary: Color(0xFF1a1a1a),
        onPrimaryContainer: Color(0xFF1a1a1a),

        // 보조 색상 - 레드 (#DC143C, #8B0000)
        secondary: Color(0xFFDC143C),
        secondaryContainer: Color(0xFF8B0000),
        onSecondary: Color(0xFFFFFFFF),
        onSecondaryContainer: Color(0xFFFFFFFF),

        // 배경 - 다크 (#1a1a1a, #0a0a0a)
        surface: Color(0xFF1a1a1a),
        onSurface: Color(0xFFFFFFFF),

        // 에러
        error: Color(0xFFDC143C),
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFF8B0000),
        onErrorContainer: Color(0xFFFFFFFF),

        // 기타
        outline: Color(0xFFFFD700),
        shadow: Color(0xFF000000),
        inverseSurface: Color(0xFFFFFFFF),
        onInverseSurface: Color(0xFF1a1a1a),
      ),

      cardTheme: CardTheme(
        color: const Color(0xFF2a2a2a),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            width: 2,
          ),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1a1a1a),
        foregroundColor: Color(0xFFFFD700),
        elevation: 2,
        centerTitle: true,
      ),
    );
  }

  /// 테마 타입에 따른 ThemeData 반환
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.diary:
        return diaryTheme;
      case AppThemeType.album:
        return albumTheme;
      case AppThemeType.stadium:
        return stadiumTheme;
    }
  }

  /// 테마 타입에 따른 이름 반환 (한글)
  static String getThemeName(AppThemeType type) {
    switch (type) {
      case AppThemeType.diary:
        return '일기장';
      case AppThemeType.album:
        return '앨범';
      case AppThemeType.stadium:
        return '야구장';
    }
  }

  /// 테마 타입에 따른 설명 반환
  static String getThemeDescription(AppThemeType type) {
    switch (type) {
      case AppThemeType.diary:
        return '따뜻하고 포근한 일기장 스타일';
      case AppThemeType.album:
        return '고급스럽고 세련된 앨범 스타일';
      case AppThemeType.stadium:
        return '역동적이고 활기찬 야구장 스타일';
    }
  }
}
