import 'package:flutter/material.dart';
import '../core/constants/app_themes.dart';
import '../models/user_model.dart';

/// 테마 관리 Provider
class ThemeProvider extends ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.diary;
  UserModel? _currentUser;

  /// 현재 테마 타입
  AppThemeType get currentTheme => _currentTheme;

  /// 현재 테마 데이터
  ThemeData get themeData => AppThemes.getTheme(_currentTheme);

  /// 현재 사용자 설정
  void setCurrentUser(UserModel? user) {
    _currentUser = user;

    // 무료 사용자가 프리미엄 테마를 사용 중이면 기본 테마로 변경
    if (user != null &&
        !user.isPremium &&
        AppThemes.isPremiumTheme(_currentTheme)) {
      _currentTheme = AppThemeType.diary;
      notifyListeners();
    }
  }

  /// 테마 변경 (프리미엄 차단 로직 포함)
  ///
  /// Returns: 성공 여부
  /// - true: 테마 변경 성공
  /// - false: 프리미엄 전용 테마로 차단됨
  bool setTheme(AppThemeType theme, {Function(String)? onPremiumRequired}) {
    // 프리미엄 테마 체크
    if (AppThemes.isPremiumTheme(theme)) {
      // 프리미엄 사용자가 아니면 차단
      if (_currentUser == null || !_currentUser!.isPremium) {
        final themeName = AppThemes.getThemeName(theme);
        final message = '$themeName 테마는 프리미엄 전용입니다.';

        // 콜백 호출 (다이얼로그 표시용)
        if (onPremiumRequired != null) {
          onPremiumRequired(message);
        }

        return false; // 테마 변경 실패
      }
    }

    // 테마 변경
    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();
    }

    return true; // 테마 변경 성공
  }

  /// 테마 토글 (순환) - 프리미엄 테마는 건너뜀
  void toggleTheme({Function(String)? onPremiumRequired}) {
    final isPremium = _currentUser?.isPremium ?? false;

    switch (_currentTheme) {
      case AppThemeType.diary:
        // album이 프리미엄이고 사용자가 무료면 diary로 유지 또는 다음으로
        if (!isPremium && AppThemes.isPremiumTheme(AppThemeType.album)) {
          // 다음 무료 테마 또는 현재 유지
          setTheme(AppThemeType.diary);
        } else {
          setTheme(AppThemeType.album, onPremiumRequired: onPremiumRequired);
        }
        break;
      case AppThemeType.album:
        if (!isPremium && AppThemes.isPremiumTheme(AppThemeType.stadium)) {
          setTheme(AppThemeType.diary);
        } else {
          setTheme(AppThemeType.stadium, onPremiumRequired: onPremiumRequired);
        }
        break;
      case AppThemeType.stadium:
        setTheme(AppThemeType.diary);
        break;
    }
  }

  /// 사용자가 접근 가능한 테마 목록
  List<AppThemeType> get availableThemes {
    final isPremium = _currentUser?.isPremium ?? false;

    if (isPremium) {
      return AppThemes.allThemes; // 프리미엄은 모든 테마
    } else {
      return AppThemes.freeThemes; // 무료는 무료 테마만
    }
  }

  /// 테마 접근 가능 여부 확인
  bool canAccessTheme(AppThemeType theme) {
    if (!AppThemes.isPremiumTheme(theme)) {
      return true; // 무료 테마는 누구나 접근 가능
    }

    return _currentUser?.isPremium ?? false;
  }
}
