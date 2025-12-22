import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/friendship_model.dart';
import '../models/user_model.dart';

/// 친구 관리 서비스
class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 친구 요청 보내기
  ///
  /// [currentUserId] 현재 사용자 ID
  /// [targetUserId] 친구 요청을 보낼 사용자 ID
  ///
  /// Returns: 생성된 Friendship 문서 ID
  Future<String> sendFriendRequest(
    String currentUserId,
    String targetUserId,
  ) async {
    // 자기 자신에게 친구 요청 방지
    if (currentUserId == targetUserId) {
      throw Exception('자기 자신에게 친구 요청을 보낼 수 없습니다.');
    }

    // 기존 친구 관계 확인
    final existingFriendship = await checkFriendship(currentUserId, targetUserId);
    if (existingFriendship != null) {
      if (existingFriendship.status == FriendshipStatus.accepted) {
        throw Exception('이미 친구입니다.');
      } else if (existingFriendship.status == FriendshipStatus.pending) {
        throw Exception('이미 친구 요청을 보냈습니다.');
      } else if (existingFriendship.status == FriendshipStatus.blocked) {
        throw Exception('차단된 사용자입니다.');
      }
    }

    // 새 친구 요청 생성
    final friendship = Friendship(
      id: '', // Firestore가 자동 생성
      requesterId: currentUserId,
      receiverId: targetUserId,
      status: FriendshipStatus.pending,
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection('friendships')
        .add(friendship.toJson());

    return docRef.id;
  }

  /// 친구 요청 수락
  ///
  /// [friendshipId] Friendship 문서 ID
  Future<void> acceptFriendRequest(String friendshipId) async {
    await _firestore.collection('friendships').doc(friendshipId).update({
      'status': FriendshipStatus.accepted,
      'updatedAt': Timestamp.now(),
    });
  }

  /// 친구 요청 거절
  ///
  /// [friendshipId] Friendship 문서 ID
  Future<void> rejectFriendRequest(String friendshipId) async {
    await _firestore.collection('friendships').doc(friendshipId).update({
      'status': FriendshipStatus.rejected,
      'updatedAt': Timestamp.now(),
    });
  }

  /// 친구 삭제
  ///
  /// [friendshipId] Friendship 문서 ID
  Future<void> removeFriend(String friendshipId) async {
    await _firestore.collection('friendships').doc(friendshipId).delete();
  }

  /// 친구 목록 조회
  ///
  /// [userId] 사용자 ID
  ///
  /// Returns: 친구인 사용자 목록 (UserModel)
  Future<List<UserModel>> getFriends(String userId) async {
    // 내가 요청자이면서 수락된 친구
    final sentQuery = await _firestore
        .collection('friendships')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.accepted)
        .get();

    // 내가 수신자이면서 수락된 친구
    final receivedQuery = await _firestore
        .collection('friendships')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.accepted)
        .get();

    // 친구 ID 목록 추출
    final friendIds = <String>{};
    for (final doc in sentQuery.docs) {
      final friendship = Friendship.fromFirestore(doc);
      friendIds.add(friendship.receiverId);
    }
    for (final doc in receivedQuery.docs) {
      final friendship = Friendship.fromFirestore(doc);
      friendIds.add(friendship.requesterId);
    }

    // 친구 정보 조회
    if (friendIds.isEmpty) return [];

    final friends = <UserModel>[];
    for (final friendId in friendIds) {
      final userDoc = await _firestore.collection('users').doc(friendId).get();
      if (userDoc.exists) {
        friends.add(UserModel.fromFirestore(userDoc));
      }
    }

    return friends;
  }

  /// 받은 친구 요청 목록 조회
  ///
  /// [userId] 사용자 ID
  ///
  /// Returns: 받은 친구 요청 목록 (Friendship)
  Future<List<Friendship>> getPendingRequests(String userId) async {
    final query = await _firestore
        .collection('friendships')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.pending)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => Friendship.fromFirestore(doc)).toList();
  }

  /// 보낸 친구 요청 목록 조회
  ///
  /// [userId] 사용자 ID
  ///
  /// Returns: 보낸 친구 요청 목록 (Friendship)
  Future<List<Friendship>> getSentRequests(String userId) async {
    final query = await _firestore
        .collection('friendships')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.pending)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map((doc) => Friendship.fromFirestore(doc)).toList();
  }

  /// 친구 관계 확인
  ///
  /// [userId1] 사용자 1 ID
  /// [userId2] 사용자 2 ID
  ///
  /// Returns: Friendship 객체 (없으면 null)
  Future<Friendship?> checkFriendship(String userId1, String userId2) async {
    // userId1이 요청자인 경우
    final query1 = await _firestore
        .collection('friendships')
        .where('requesterId', isEqualTo: userId1)
        .where('receiverId', isEqualTo: userId2)
        .limit(1)
        .get();

    if (query1.docs.isNotEmpty) {
      return Friendship.fromFirestore(query1.docs.first);
    }

    // userId2가 요청자인 경우
    final query2 = await _firestore
        .collection('friendships')
        .where('requesterId', isEqualTo: userId2)
        .where('receiverId', isEqualTo: userId1)
        .limit(1)
        .get();

    if (query2.docs.isNotEmpty) {
      return Friendship.fromFirestore(query2.docs.first);
    }

    return null;
  }

  /// 사용자 차단
  ///
  /// [currentUserId] 현재 사용자 ID
  /// [targetUserId] 차단할 사용자 ID
  Future<void> blockUser(String currentUserId, String targetUserId) async {
    final friendship = await checkFriendship(currentUserId, targetUserId);

    if (friendship != null) {
      // 기존 친구 관계가 있으면 차단 상태로 변경
      await _firestore.collection('friendships').doc(friendship.id).update({
        'status': FriendshipStatus.blocked,
        'updatedAt': Timestamp.now(),
      });
    } else {
      // 기존 친구 관계가 없으면 새로 생성
      final newFriendship = Friendship(
        id: '',
        requesterId: currentUserId,
        receiverId: targetUserId,
        status: FriendshipStatus.blocked,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('friendships')
          .add(newFriendship.toJson());
    }
  }

  /// 차단 해제
  ///
  /// [friendshipId] Friendship 문서 ID
  Future<void> unblockUser(String friendshipId) async {
    await _firestore.collection('friendships').doc(friendshipId).delete();
  }

  /// 친구 수 조회
  ///
  /// [userId] 사용자 ID
  ///
  /// Returns: 친구 수
  Future<int> getFriendCount(String userId) async {
    final sentQuery = await _firestore
        .collection('friendships')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.accepted)
        .get();

    final receivedQuery = await _firestore
        .collection('friendships')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.accepted)
        .get();

    return sentQuery.docs.length + receivedQuery.docs.length;
  }

  /// 대기 중인 친구 요청 수 조회
  ///
  /// [userId] 사용자 ID
  ///
  /// Returns: 받은 친구 요청 수
  Future<int> getPendingRequestCount(String userId) async {
    final query = await _firestore
        .collection('friendships')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.pending)
        .get();

    return query.docs.length;
  }

  /// 친구 요청 이력 조회 (내가 보낸 요청)
  ///
  /// [userId] 사용자 ID
  ///
  /// Returns: 친구 요청 이력 목록
  /// - pending 상태: 기간 제한 없음
  /// - 그 외 상태 (accepted/rejected): 최근 2주 이내 데이터만
  Future<List<Friendship>> getRequestHistory(String userId) async {
    // 2주 전 날짜 계산
    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));

    // pending 요청 (기간 제한 없음)
    final pendingQuery = await _firestore
        .collection('friendships')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.pending)
        .orderBy('createdAt', descending: true)
        .get();

    // accepted 요청 (최근 2주)
    final acceptedQuery = await _firestore
        .collection('friendships')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.accepted)
        .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(twoWeeksAgo))
        .orderBy('updatedAt', descending: true)
        .get();

    // rejected 요청 (최근 2주)
    final rejectedQuery = await _firestore
        .collection('friendships')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.rejected)
        .where('updatedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(twoWeeksAgo))
        .orderBy('updatedAt', descending: true)
        .get();

    // 모든 결과 합치기
    final allDocs = <QueryDocumentSnapshot>[
      ...pendingQuery.docs,
      ...acceptedQuery.docs,
      ...rejectedQuery.docs,
    ];

    // Friendship 객체로 변환
    final friendships = allDocs.map((doc) => Friendship.fromFirestore(doc)).toList();

    // 시간순으로 정렬 (최신순)
    friendships.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt;
      final bDate = b.updatedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    return friendships;
  }

  /// 친구 목록 실시간 스트림
  ///
  /// [userId] 사용자 ID
  ///
  /// Returns: 친구 목록 Stream
  Stream<List<UserModel>> getFriendsStream(String userId) {
    // Note: Firestore의 복합 쿼리 제한으로 인해 두 쿼리를 합쳐야 함
    // 실제 구현에서는 Cloud Function을 사용하거나 클라이언트에서 병합하는 것이 좋음
    return _firestore
        .collection('friendships')
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: FriendshipStatus.accepted)
        .snapshots()
        .asyncMap((snapshot) async {
      final friendIds = <String>{};
      for (final doc in snapshot.docs) {
        final friendship = Friendship.fromFirestore(doc);
        friendIds.add(friendship.receiverId);
      }

      // receiverId로도 조회
      final receivedQuery = await _firestore
          .collection('friendships')
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: FriendshipStatus.accepted)
          .get();

      for (final doc in receivedQuery.docs) {
        final friendship = Friendship.fromFirestore(doc);
        friendIds.add(friendship.requesterId);
      }

      // 친구 정보 조회
      if (friendIds.isEmpty) return <UserModel>[];

      final friends = <UserModel>[];
      for (final friendId in friendIds) {
        final userDoc =
            await _firestore.collection('users').doc(friendId).get();
        if (userDoc.exists) {
          friends.add(UserModel.fromFirestore(userDoc));
        }
      }

      return friends;
    });
  }
}
