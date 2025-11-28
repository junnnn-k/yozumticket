import 'package:flutter/material.dart';
import '../core/constants/app_themes.dart';

/// 테마 관리 Provider
class ThemeProvider extends ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.diary;

  /// 현재 테마 타입
  AppThemeType get currentTheme => _currentTheme;

  /// 현재 테마 데이터
  ThemeData get themeData => AppThemes.getTheme(_currentTheme);

  /// 테마 변경
  void setTheme(AppThemeType theme) {
    if (_currentTheme != theme) {
      _currentTheme = theme;
      notifyListeners();
    }
  }

  /// 테마 토글 (순환)
  void toggleTheme() {
    switch (_currentTheme) {
      case AppThemeType.diary:
        setTheme(AppThemeType.album);
        break;
      case AppThemeType.album:
        setTheme(AppThemeType.stadium);
        break;
      case AppThemeType.stadium:
        setTheme(AppThemeType.diary);
        break;
    }
  }
}
