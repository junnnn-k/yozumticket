import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

/// 인증 상태 관리 Provider
///
/// Firebase Authentication 상태를 관리하고
/// 로그인/로그아웃 기능을 제공합니다.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  /// 현재 Firebase User
  User? get firebaseUser => _firebaseUser;

  /// 현재 UserModel (Firestore 사용자 정보)
  UserModel? get userModel => _userModel;

  /// 로딩 상태
  bool get isLoading => _isLoading;

  /// 에러 메시지
  String? get errorMessage => _errorMessage;

  /// 로그인 여부
  bool get isSignedIn => _firebaseUser != null;

  /// 현재 사용자 UID
  String? get userId => _firebaseUser?.uid;

  AuthProvider() {
    _initAuthListener();
  }

  /// 인증 상태 리스너 초기화
  ///
  /// Firebase Auth 상태 변경 시 자동으로 UserModel 로드
  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) async {
      _firebaseUser = user;

      if (user != null) {
        // 로그인 상태: Firestore에서 사용자 정보 로드
        await _loadUserModel(user.uid);
      } else {
        // 로그아웃 상태: 사용자 정보 초기화
        _userModel = null;
      }

      notifyListeners();
    });
  }

  /// Firestore에서 사용자 정보 로드
  Future<void> _loadUserModel(String uid) async {
    try {
      _userModel = await _userService.getUser(uid);

      if (_userModel == null) {
        print('[AuthProvider] UserModel not found for uid: $uid');
      }
    } catch (e) {
      print('[AuthProvider] Failed to load UserModel: $e');
      _errorMessage = '사용자 정보를 불러오는데 실패했습니다.';
    }
  }

  /// Google 로그인
  ///
  /// 1. Firebase Auth 로그인
  /// 2. Firestore에 사용자 정보 생성 또는 업데이트
  /// 3. UserModel 로드
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      // 1. Firebase Auth 로그인
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        // 사용자가 로그인 취소
        _setLoading(false);
        return false;
      }

      final user = userCredential.user!;
      _firebaseUser = user;

      // 2. Firestore에 사용자 정보 확인 및 생성
      UserModel? existingUser = await _userService.getUser(user.uid);

      if (existingUser == null) {
        // 첫 로그인: 새 사용자 생성
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          username: user.displayName ?? '사용자',
          profileImageUrl: user.photoURL ?? '',
          favoriteTeams: [],
          bio: '',
          createdAt: DateTime.now(),
        );

        await _userService.createUser(newUser);
        _userModel = newUser;
        print('[AuthProvider] New user created: ${newUser.username}');
      } else {
        // 기존 사용자: UserModel 로드
        _userModel = existingUser;
        print('[AuthProvider] Existing user loaded: ${existingUser.username}');
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      print('[AuthProvider] Google sign-in failed: $e');
      _errorMessage = 'Google 로그인에 실패했습니다.';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
      _firebaseUser = null;
      _userModel = null;

      _setLoading(false);
      notifyListeners();
      print('[AuthProvider] Sign out successful');
    } catch (e) {
      print('[AuthProvider] Sign out failed: $e');
      _errorMessage = '로그아웃에 실패했습니다.';
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 회원 탈퇴
  ///
  /// 1. Firestore 사용자 데이터 삭제
  /// 2. Firebase Auth 계정 삭제
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();

    try {
      if (_firebaseUser == null) {
        _errorMessage = '로그인이 필요합니다.';
        _setLoading(false);
        return false;
      }

      // 1. Firestore 사용자 데이터 삭제
      await _userService.deleteUser(_firebaseUser!.uid);

      // 2. Firebase Auth 계정 삭제
      await _authService.deleteAccount();

      _firebaseUser = null;
      _userModel = null;

      _setLoading(false);
      notifyListeners();
      print('[AuthProvider] Account deleted successfully');
      return true;
    } catch (e) {
      print('[AuthProvider] Account deletion failed: $e');
      _errorMessage = '회원 탈퇴에 실패했습니다.';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// 사용자 정보 새로고침
  Future<void> refreshUserModel() async {
    if (_firebaseUser != null) {
      await _loadUserModel(_firebaseUser!.uid);
      notifyListeners();
    }
  }

  /// 로딩 상태 설정
  void _setLoading(bool value) {
    _isLoading = value;
  }

  /// 에러 메시지 초기화
  void _clearError() {
    _errorMessage = null;
  }
}
