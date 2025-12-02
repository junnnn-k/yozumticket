import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Firestore Users 컬렉션 서비스
///
/// 사용자 프로필 CRUD 기능 제공
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Users 컬렉션 참조
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 사용자 생성
  ///
  /// 첫 로그인 시 Firestore에 사용자 정보 저장
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toJson());
      print('[UserService] User created: ${user.uid}');
    } catch (e) {
      print('[UserService] Failed to create user: $e');
      rethrow;
    }
  }

  /// 사용자 조회
  ///
  /// uid로 사용자 정보 가져오기
  /// Returns: UserModel (존재하는 경우), null (존재하지 않는 경우)
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();

      if (!doc.exists) {
        print('[UserService] User not found: $uid');
        return null;
      }

      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('[UserService] Failed to get user: $e');
      rethrow;
    }
  }

  /// 사용자 정보 업데이트
  ///
  /// 부분 업데이트 지원 (변경된 필드만 업데이트)
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
      print('[UserService] User updated: $uid');
    } catch (e) {
      print('[UserService] Failed to update user: $e');
      rethrow;
    }
  }

  /// 사용자 삭제
  ///
  /// 회원 탈퇴 시 Firestore 사용자 데이터 삭제
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
      print('[UserService] User deleted: $uid');
    } catch (e) {
      print('[UserService] Failed to delete user: $e');
      rethrow;
    }
  }

  /// 사용자 이름으로 검색
  ///
  /// 친구 검색 기능에서 사용
  /// Returns: 검색된 사용자 목록
  Future<List<UserModel>> searchUsersByName(String query) async {
    try {
      // Firestore는 부분 문자열 검색을 지원하지 않으므로
      // 전체 사용자를 가져와서 클라이언트에서 필터링
      // 추후 Algolia 등 검색 서비스 도입 고려
      final snapshot = await _usersCollection
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('[UserService] Failed to search users: $e');
      return [];
    }
  }

  /// 응원팀으로 사용자 검색
  ///
  /// 같은 팀 팬들 찾기
  Future<List<UserModel>> getUsersByFavoriteTeam(String team) async {
    try {
      final snapshot = await _usersCollection
          .where('favoriteTeams', arrayContains: team)
          .limit(20)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('[UserService] Failed to get users by team: $e');
      return [];
    }
  }

  /// 사용자 프로필 이미지 업데이트
  Future<void> updateProfileImage(String uid, String imageUrl) async {
    await updateUser(uid, {'profileImageUrl': imageUrl});
  }

  /// 응원팀 업데이트
  Future<void> updateFavoriteTeams(String uid, List<String> teams) async {
    await updateUser(uid, {'favoriteTeams': teams});
  }

  /// 자기소개 업데이트
  Future<void> updateBio(String uid, String bio) async {
    await updateUser(uid, {'bio': bio});
  }

  /// 사용자 이름 업데이트
  Future<void> updateUsername(String uid, String username) async {
    await updateUser(uid, {'username': username});
  }

  /// 사용자 존재 여부 확인
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('[UserService] Failed to check user existence: $e');
      return false;
    }
  }

  /// 사용자 스트림 (실시간 업데이트)
  ///
  /// 프로필 화면 등에서 실시간으로 사용자 정보 반영
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }
}
