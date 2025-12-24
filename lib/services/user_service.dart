import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// Firestore Users 컬렉션 서비스
///
/// 사용자 프로필 CRUD 기능 제공
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

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
  /// 회원 탈퇴 시 모든 사용자 데이터 삭제
  /// - Firestore: users, posts, friendships, sharedArchives
  /// - Firebase Storage: 모든 사용자 파일
  Future<void> deleteUser(String uid) async {
    try {
      print('[UserService] Starting user deletion: $uid');

      // 1. 사용자의 모든 게시글 삭제
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: uid)
          .get();

      print('[UserService] Found ${postsSnapshot.docs.length} posts to delete');

      for (final doc in postsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. 사용자와 관련된 모든 친구 관계 삭제
      final friendshipsAsRequester = await _firestore
          .collection('friendships')
          .where('requesterId', isEqualTo: uid)
          .get();

      final friendshipsAsReceiver = await _firestore
          .collection('friendships')
          .where('receiverId', isEqualTo: uid)
          .get();

      print('[UserService] Found ${friendshipsAsRequester.docs.length + friendshipsAsReceiver.docs.length} friendships to delete');

      for (final doc in friendshipsAsRequester.docs) {
        await doc.reference.delete();
      }
      for (final doc in friendshipsAsReceiver.docs) {
        await doc.reference.delete();
      }

      // 3. 생성자인 공유 아카이브 처리
      final createdArchives = await _firestore
          .collection('sharedArchives')
          .where('createdBy', isEqualTo: uid)
          .get();

      print('[UserService] Found ${createdArchives.docs.length} shared archives created by user');

      for (final doc in createdArchives.docs) {
        final data = doc.data();
        final members = List<String>.from(data['members'] ?? []);

        // 생성자를 멤버 목록에서 제거
        members.remove(uid);

        if (members.isEmpty) {
          // 멤버가 없으면 아카이브 삭제
          await doc.reference.delete();
          print('[UserService] Deleted empty shared archive: ${doc.id}');
        } else {
          // 첫 번째 멤버에게 소유권 이전
          await doc.reference.update({
            'createdBy': members.first,
            'members': members,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('[UserService] Transferred ownership of archive ${doc.id} to ${members.first}');
        }
      }

      // 4. 멤버로 참여한 공유 아카이브에서 제거
      final memberArchives = await _firestore
          .collection('sharedArchives')
          .where('members', arrayContains: uid)
          .get();

      print('[UserService] Found ${memberArchives.docs.length} shared archives as member');

      for (final doc in memberArchives.docs) {
        await doc.reference.update({
          'members': FieldValue.arrayRemove([uid]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('[UserService] Removed user from shared archive: ${doc.id}');
      }

      // 5. Firebase Storage의 모든 사용자 파일 삭제
      await _storageService.deleteUserData(uid);

      // 6. Firestore users 문서 삭제
      await _usersCollection.doc(uid).delete();

      print('[UserService] User and all related data deleted successfully: $uid');
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

  /// 프리미엄 구독 활성화
  Future<void> activatePremiumSubscription({
    required String uid,
    required String subscriptionType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await updateUser(uid, {
      'isPremium': true,
      'subscriptionType': subscriptionType,
      'subscriptionStartDate': Timestamp.fromDate(startDate),
      'subscriptionEndDate': Timestamp.fromDate(endDate),
      'maxPhotosPerPost': 20,
      'maxSharedArchives': -1,
      'showBannerAds': false,
    });
  }

  /// 프리미엄 구독 해지
  Future<void> cancelPremiumSubscription(String uid) async {
    await updateUser(uid, {
      'isPremium': false,
      'subscriptionType': null,
      'subscriptionStartDate': null,
      'subscriptionEndDate': null,
      'maxPhotosPerPost': 3,
      'maxSharedArchives': 2,
      'showBannerAds': true,
    });
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

  // ============================================================================
  // 비즈니스 모델 관련 메서드 (v3.1)
  // ============================================================================

  /// 프리미엄 상태 업데이트
  ///
  /// 프리미엄 구독 시 한 번에 여러 필드 업데이트
  /// - isPremium: true
  /// - maxPhotosPerPost: 20
  /// - maxSharedArchives: -1 (무제한)
  /// - showBannerAds: false
  Future<void> upgradeToPremium({
    required String uid,
    required String subscriptionType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      await updateUser(uid, {
        'isPremium': true,
        'subscriptionType': subscriptionType,
        'subscriptionStartDate': Timestamp.fromDate(startDate),
        'subscriptionEndDate': Timestamp.fromDate(endDate),
        'maxPhotosPerPost': 20,
        'maxSharedArchives': -1, // 무제한
        'showBannerAds': false,
      });
      print('[UserService] User upgraded to premium: $uid');
    } catch (e) {
      print('[UserService] Failed to upgrade to premium: $e');
      rethrow;
    }
  }

  /// 프리미엄 상태 해제 (구독 만료 시)
  ///
  /// 무료 사용자 상태로 복귀
  Future<void> downgradeToFree(String uid) async {
    try {
      await updateUser(uid, {
        'isPremium': false,
        'subscriptionType': null,
        'subscriptionStartDate': null,
        'subscriptionEndDate': null,
        'maxPhotosPerPost': 3,
        'maxSharedArchives': 2,
        'showBannerAds': true,
      });
      print('[UserService] User downgraded to free: $uid');
    } catch (e) {
      print('[UserService] Failed to downgrade to free: $e');
      rethrow;
    }
  }

  /// 구독 정보 업데이트
  ///
  /// 구독 연장 또는 변경 시 사용
  Future<void> updateSubscription({
    required String uid,
    required String subscriptionType,
    required DateTime endDate,
  }) async {
    try {
      await updateUser(uid, {
        'subscriptionType': subscriptionType,
        'subscriptionEndDate': Timestamp.fromDate(endDate),
      });
      print('[UserService] Subscription updated: $uid');
    } catch (e) {
      print('[UserService] Failed to update subscription: $e');
      rethrow;
    }
  }

  /// 리워드 광고 시청 횟수 증가
  ///
  /// 사용자가 리워드 광고를 시청할 때마다 호출
  /// 일일 제한 체크는 호출 측에서 수행
  Future<void> incrementRewardedAdCount(String uid) async {
    try {
      final user = await getUser(uid);
      if (user == null) return;

      final now = DateTime.now();
      final lastAdDate = user.lastRewardedAdDate;

      // 날짜가 바뀌었으면 카운트 초기화
      int newCount = 1;
      if (lastAdDate != null &&
          lastAdDate.year == now.year &&
          lastAdDate.month == now.month &&
          lastAdDate.day == now.day) {
        // 같은 날이면 카운트 증가
        newCount = user.dailyRewardedAdCount + 1;
      }

      await updateUser(uid, {
        'dailyRewardedAdCount': newCount,
        'lastRewardedAdDate': Timestamp.fromDate(now),
      });

      print('[UserService] Rewarded ad count updated: $uid ($newCount)');
    } catch (e) {
      print('[UserService] Failed to increment ad count: $e');
      rethrow;
    }
  }

  /// 일일 광고 횟수 초기화
  ///
  /// 매일 자정에 호출 (서버 트리거 또는 앱 시작 시 체크)
  Future<void> resetDailyAdCount(String uid) async {
    try {
      await updateUser(uid, {
        'dailyRewardedAdCount': 0,
      });
      print('[UserService] Daily ad count reset: $uid');
    } catch (e) {
      print('[UserService] Failed to reset ad count: $e');
      rethrow;
    }
  }

  /// 테마 구매 추가
  ///
  /// 사용자가 테마를 구매했을 때 호출
  Future<void> addOwnedTheme(String uid, String themeId) async {
    try {
      final user = await getUser(uid);
      if (user == null) return;

      // 이미 소유한 테마인지 확인
      if (user.ownedThemes.contains(themeId)) {
        print('[UserService] Theme already owned: $themeId');
        return;
      }

      final updatedThemes = [...user.ownedThemes, themeId];
      await updateUser(uid, {
        'ownedThemes': updatedThemes,
      });

      print('[UserService] Theme added: $uid -> $themeId');
    } catch (e) {
      print('[UserService] Failed to add theme: $e');
      rethrow;
    }
  }

  /// 구매 이력 추가
  ///
  /// 모든 구매(구독, 개별 상품) 이력 기록
  Future<void> addPurchaseHistory(String uid, String productId) async {
    try {
      final user = await getUser(uid);
      if (user == null) return;

      final updatedHistory = [...user.purchaseHistory, productId];
      await updateUser(uid, {
        'purchaseHistory': updatedHistory,
      });

      print('[UserService] Purchase history added: $uid -> $productId');
    } catch (e) {
      print('[UserService] Failed to add purchase history: $e');
      rethrow;
    }
  }

  /// 사진 제한 커스텀 설정
  ///
  /// 개별 상품 구매 시 (예: 추가사진+ 구독)
  Future<void> updatePhotoLimit(String uid, int maxPhotos) async {
    try {
      await updateUser(uid, {
        'maxPhotosPerPost': maxPhotos,
      });
      print('[UserService] Photo limit updated: $uid -> $maxPhotos');
    } catch (e) {
      print('[UserService] Failed to update photo limit: $e');
      rethrow;
    }
  }

  /// 공유 아카이브 제한 커스텀 설정
  ///
  /// 개별 상품 구매 시
  Future<void> updateSharedArchiveLimit(String uid, int maxArchives) async {
    try {
      await updateUser(uid, {
        'maxSharedArchives': maxArchives,
      });
      print('[UserService] Shared archive limit updated: $uid -> $maxArchives');
    } catch (e) {
      print('[UserService] Failed to update archive limit: $e');
      rethrow;
    }
  }

  /// 광고 표시 설정
  ///
  /// 개별 광고 제거 상품 구매 시
  Future<void> updateAdSettings(String uid, bool showBannerAds) async {
    try {
      await updateUser(uid, {
        'showBannerAds': showBannerAds,
      });
      print('[UserService] Ad settings updated: $uid -> showBannerAds: $showBannerAds');
    } catch (e) {
      print('[UserService] Failed to update ad settings: $e');
      rethrow;
    }
  }

  // ============================================================================
  // FCM 관련 메서드 (v3.2)
  // ============================================================================

  /// FCM 토큰 업데이트
  ///
  /// 푸시 알림을 위한 FCM 토큰 저장
  Future<void> updateFCMToken(String uid, String fcmToken) async {
    try {
      await updateUser(uid, {
        'fcmToken': fcmToken,
      });
      print('[UserService] FCM token updated: $uid');
    } catch (e) {
      print('[UserService] Failed to update FCM token: $e');
      rethrow;
    }
  }

  /// FCM 토큰 삭제
  ///
  /// 로그아웃 시 호출
  Future<void> deleteFCMToken(String uid) async {
    try {
      await updateUser(uid, {
        'fcmToken': null,
      });
      print('[UserService] FCM token deleted: $uid');
    } catch (e) {
      print('[UserService] Failed to delete FCM token: $e');
      rethrow;
    }
  }

  // ========================================
  // 리워드 광고 보상 관리 (v3.3)
  // ========================================

  /// 프리미엄 테마 광고 시청 횟수 증가
  Future<void> incrementPremiumThemeAdCount(String uid) async {
    try {
      final user = await getUser(uid);
      if (user == null) return;

      final now = DateTime.now();
      final lastDate = user.lastPremiumThemeAdDate;

      // 날짜가 바뀌었으면 카운트 초기화
      int newCount = 1;
      if (lastDate != null &&
          lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day) {
        newCount = user.dailyPremiumThemeAdCount + 1;
      }

      await updateUser(uid, {
        'dailyPremiumThemeAdCount': newCount,
        'lastPremiumThemeAdDate': Timestamp.fromDate(now),
      });
    } catch (e) {
      print('[UserService] Failed to increment premium theme ad count: $e');
      rethrow;
    }
  }

  /// 추가 사진 광고 시청 횟수 증가
  Future<void> incrementExtraPhotoAdCount(String uid) async {
    try {
      final user = await getUser(uid);
      if (user == null) return;

      final now = DateTime.now();
      final lastDate = user.lastExtraPhotoAdDate;

      // 날짜가 바뀌었으면 카운트 초기화
      int newCount = 1;
      if (lastDate != null &&
          lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day) {
        newCount = user.dailyExtraPhotoAdCount + 1;
      }

      await updateUser(uid, {
        'dailyExtraPhotoAdCount': newCount,
        'lastExtraPhotoAdDate': Timestamp.fromDate(now),
      });
    } catch (e) {
      print('[UserService] Failed to increment extra photo ad count: $e');
      rethrow;
    }
  }

  /// 임시 프리미엄 부여 (광고 보상)
  ///
  /// [expiry] 만료 시간 (보통 1일 후)
  Future<void> grantTempPremium(String uid, DateTime expiry) async {
    try {
      await updateUser(uid, {
        'tempPremiumExpiry': Timestamp.fromDate(expiry),
      });
      print('[UserService] Temp premium granted until: $expiry');
    } catch (e) {
      print('[UserService] Failed to grant temp premium: $e');
      rethrow;
    }
  }

  /// 임시 추가 사진 부여 (광고 보상)
  ///
  /// 1회 추가 (기존 값에 +1)
  Future<void> grantTempExtraPhoto(String uid) async {
    try {
      final user = await getUser(uid);
      if (user == null) return;

      final newCount = user.tempExtraPhotoCount + 1;
      await updateUser(uid, {
        'tempExtraPhotoCount': newCount,
      });
      print('[UserService] Temp extra photo granted. Total: $newCount');
    } catch (e) {
      print('[UserService] Failed to grant temp extra photo: $e');
      rethrow;
    }
  }

  /// 임시 추가 사진 사용 (1회 차감)
  Future<void> consumeTempExtraPhoto(String uid) async {
    try {
      final user = await getUser(uid);
      if (user == null || user.tempExtraPhotoCount <= 0) return;

      final newCount = user.tempExtraPhotoCount - 1;
      await updateUser(uid, {
        'tempExtraPhotoCount': newCount,
      });
      print('[UserService] Temp extra photo consumed. Remaining: $newCount');
    } catch (e) {
      print('[UserService] Failed to consume temp extra photo: $e');
      rethrow;
    }
  }
}
