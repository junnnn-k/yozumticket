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

    // 프리미엄이 아니고 임시 프리미엄도 없는 사용자가 프리미엄 테마 사용 중이면 기본 테마로 변경
    if (user != null &&
        !_hasActivePremium(user) &&
        AppThemes.isPremiumTheme(_currentTheme)) {
      _currentTheme = AppThemeType.diary;
      notifyListeners();
    }
  }

  /// 프리미엄 접근 권한 확인 (구독 또는 임시 프리미엄)
  bool _hasActivePremium(UserModel user) {
    // 정식 프리미엄 구독자
    if (user.isPremium) return true;

    // 임시 프리미엄 (광고 보상) 확인
    if (user.tempPremiumExpiry != null) {
      final now = DateTime.now();
      return now.isBefore(user.tempPremiumExpiry!);
    }

    return false;
  }

  /// 테마 변경 (프리미엄 차단 로직 포함)
  ///
  /// Returns: 성공 여부
  /// - true: 테마 변경 성공
  /// - false: 프리미엄 전용 테마로 차단됨
  bool setTheme(AppThemeType theme, {Function(String)? onPremiumRequired}) {
    // 프리미엄 테마 체크
    if (AppThemes.isPremiumTheme(theme)) {
      // 프리미엄 권한이 없으면 차단
      if (_currentUser == null || !_hasActivePremium(_currentUser!)) {
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
    final isPremium = _currentUser != null && _hasActivePremium(_currentUser!);

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
    final hasPremium = _currentUser != null && _hasActivePremium(_currentUser!);

    if (hasPremium) {
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

    return _currentUser != null && _hasActivePremium(_currentUser!);
  }
}
