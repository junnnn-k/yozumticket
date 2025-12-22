import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

/// 게시글 Firestore 서비스
class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'posts';

  /// 게시글 생성
  Future<String> createPost(Post post) async {
    try {
      // 제공된 ID 사용 (이미 Storage 업로드에 사용된 ID)
      final docRef = _firestore.collection(_collectionName).doc(post.id);

      // 타임스탬프 업데이트
      final newPost = post.copyWith(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Firestore에 저장
      await docRef.set(newPost.toJson());

      print('✅ Firestore 저장 완료: postId=${post.id}');

      return post.id;
    } catch (e) {
      throw Exception('게시글 작성 실패: $e');
    }
  }

  /// 게시글 조회 (단건)
  Future<Post?> getPost(String postId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(postId).get();

      if (!doc.exists) {
        return null;
      }

      return Post.fromFirestore(doc);
    } catch (e) {
      throw Exception('게시글 조회 실패: $e');
    }
  }

  /// 게시글 수정
  Future<void> updatePost(Post post) async {
    try {
      final updatedPost = post.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection(_collectionName)
          .doc(post.id)
          .update(updatedPost.toJson());
    } catch (e) {
      throw Exception('게시글 수정 실패: $e');
    }
  }

  /// 게시글 삭제
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection(_collectionName).doc(postId).delete();
    } catch (e) {
      throw Exception('게시글 삭제 실패: $e');
    }
  }

  /// 내 게시글 목록 조회 (페이지네이션)
  Future<List<Post>> getMyPosts(
    String userId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // 페이지네이션: 마지막 문서 이후부터 조회
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('게시글 목록 조회 실패: $e');
    }
  }

  // 전체 공개 기능 제거됨 (2025-12-22)
  // getPublicPosts() 함수는 더 이상 사용되지 않음

  /// 게시글 개수 조회
  Future<int> getPostCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.size;
    } catch (e) {
      throw Exception('게시글 개수 조회 실패: $e');
    }
  }

  /// 게시글 실시간 스트림 (내 게시글)
  Stream<List<Post>> getMyPostsStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  /// 특정 경기의 게시글 조회 (날짜 + 팀)
  Future<List<Post>> getPostsByGame({
    required DateTime gameDate,
    String? homeTeam,
    String? awayTeam,
    int limit = 20,
  }) async {
    try {
      // 날짜 범위 (해당 날짜 0시~23시 59분)
      final startOfDay = DateTime(gameDate.year, gameDate.month, gameDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      Query query = _firestore
          .collection(_collectionName)
          .where('gameInfo.date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('gameInfo.date', isLessThan: Timestamp.fromDate(endOfDay))
          .limit(limit);

      final snapshot = await query.get();

      // 팀 필터링 (Firestore는 중첩 필드 복합 쿼리 제한이 있어 클라이언트에서 필터링)
      var posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();

      if (homeTeam != null) {
        posts = posts
            .where((post) => post.gameInfo.homeTeam == homeTeam)
            .toList();
      }

      if (awayTeam != null) {
        posts = posts
            .where((post) => post.gameInfo.awayTeam == awayTeam)
            .toList();
      }

      return posts;
    } catch (e) {
      throw Exception('경기별 게시글 조회 실패: $e');
    }
  }

  /// 태그로 게시글 검색
  Future<List<Post>> getPostsByTag(
    String tag, {
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('tags', arrayContains: tag)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('태그 검색 실패: $e');
    }
  }

  /// 사용자 통계 조회
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();

      // 총 관람 횟수
      final totalCount = posts.length;

      // 구장별 방문 횟수
      final stadiumCounts = <String, int>{};
      for (final post in posts) {
        final stadium = post.gameInfo.stadium;
        if (stadium != null && stadium.isNotEmpty) {
          stadiumCounts[stadium] = (stadiumCounts[stadium] ?? 0) + 1;
        }
      }

      // 가장 많이 방문한 구장
      String mostVisitedStadium = '';
      int maxVisits = 0;
      stadiumCounts.forEach((stadium, count) {
        if (count > maxVisits) {
          maxVisits = count;
          mostVisitedStadium = stadium;
        }
      });

      // 팀별 관람 횟수
      final teamCounts = <String, int>{};
      for (final post in posts) {
        final homeTeam = post.gameInfo.homeTeam;
        final awayTeam = post.gameInfo.awayTeam;
        if (homeTeam != null && homeTeam.isNotEmpty) {
          teamCounts[homeTeam] = (teamCounts[homeTeam] ?? 0) + 1;
        }
        if (awayTeam != null && awayTeam.isNotEmpty) {
          teamCounts[awayTeam] = (teamCounts[awayTeam] ?? 0) + 1;
        }
      }

      return {
        'totalCount': totalCount,
        'mostVisitedStadium': mostVisitedStadium,
        'stadiumVisits': maxVisits,
        'stadiumCounts': stadiumCounts,
        'teamCounts': teamCounts,
      };
    } catch (e) {
      throw Exception('통계 조회 실패: $e');
    }
  }

  /// 친구의 게시글 조회 (프라이버시 필터링 적용)
  ///
  /// [friendId] 친구의 사용자 ID
  /// [viewerId] 조회하는 사용자 ID
  /// [limit] 조회할 게시글 수 (기본값: 20)
  ///
  /// Returns: 친구의 공개 게시글 목록 (전체 공개 + 친구 공개)
  Future<List<Post>> getFriendPosts(
    String friendId,
    String viewerId, {
    int limit = 20,
  }) async {
    try {
      // 친구의 게시글 중 전체 공개 또는 친구 공개인 게시글만 조회
      final query = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: friendId)
          .where('privacy', whereIn: ['public', 'friends'])
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => Post.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('친구 게시글 조회 실패: $e');
    }
  }

  /// 친구의 게시글 수 조회
  ///
  /// [friendId] 친구의 사용자 ID
  ///
  /// Returns: 친구의 공개 게시글 수
  Future<int> getFriendPostCount(String friendId) async {
    try {
      final query = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: friendId)
          .where('privacy', whereIn: ['public', 'friends'])
          .get();

      return query.docs.length;
    } catch (e) {
      throw Exception('친구 게시글 수 조회 실패: $e');
    }
  }
}
