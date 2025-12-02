import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication 서비스
///
/// 구글 소셜 로그인, 로그아웃, 인증 상태 관리 기능 제공
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 현재 로그인된 사용자
  User? get currentUser => _auth.currentUser;

  /// 인증 상태 변경 스트림
  ///
  /// 로그인/로그아웃 시 자동으로 알림을 받을 수 있습니다.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 현재 사용자 UID 반환 (null이면 미로그인 상태)
  String? get currentUserId => _auth.currentUser?.uid;

  /// 로그인 여부
  bool get isSignedIn => _auth.currentUser != null;

  /// Google 로그인
  ///
  /// 1. Google Sign-In 플로우 시작
  /// 2. Google 인증 정보 획득
  /// 3. Firebase 크리덴셜 생성
  /// 4. Firebase Authentication 로그인
  ///
  /// Returns: Firebase UserCredential (성공 시)
  /// Throws: Exception (로그인 실패 시)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Google Sign-In 트리거
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // 사용자가 로그인 취소
        print('[AuthService] Google Sign-In canceled by user');
        return null;
      }

      // 2. Google 인증 정보 획득
      final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

      // 3. Firebase 크리덴셜 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Firebase 로그인
      final userCredential = await _auth.signInWithCredential(credential);

      print('[AuthService] Google Sign-In successful: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      print('[AuthService] Google Sign-In failed: $e');
      rethrow;
    }
  }

  /// 로그아웃
  ///
  /// Firebase Authentication과 Google Sign-In 모두 로그아웃 처리
  Future<void> signOut() async {
    try {
      // Firebase 로그아웃
      await _auth.signOut();

      // Google 로그아웃
      await _googleSignIn.signOut();

      print('[AuthService] Sign out successful');
    } catch (e) {
      print('[AuthService] Sign out failed: $e');
      rethrow;
    }
  }

  /// 익명 로그인 (테스트용)
  ///
  /// 개발 단계에서 빠른 테스트를 위해 사용
  /// 프로덕션에서는 제거 예정
  Future<UserCredential> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      print('[AuthService] Anonymous sign-in successful');
      return userCredential;
    } catch (e) {
      print('[AuthService] Anonymous sign-in failed: $e');
      rethrow;
    }
  }

  /// 현재 사용자 삭제 (회원 탈퇴)
  ///
  /// Firebase Authentication 계정 삭제
  /// Firestore 사용자 데이터는 별도로 삭제 필요 (UserService에서 처리)
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        print('[AuthService] Account deleted successfully');
      }
    } catch (e) {
      print('[AuthService] Account deletion failed: $e');
      rethrow;
    }
  }
}
