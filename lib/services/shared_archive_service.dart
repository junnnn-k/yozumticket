/// 공유 아카이브 서비스
///
/// 공유 아카이브의 생성, 수정, 삭제, 멤버 관리, 게시물 관리를 담당합니다.

import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shared_archive_model.dart';

class SharedArchiveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'sharedArchives';

  /// 공유 아카이브 생성
  Future<String> createArchive({
    required String name,
    required String description,
    required String createdBy,
    required List<String> members,
    String? coverImage,
  }) async {
    try {
      // 생성자를 멤버에 자동 포함
      final allMembers = {...members, createdBy}.toList();

      final archive = SharedArchive(
        id: '', // Firestore가 자동 생성
        name: name,
        description: description,
        createdBy: createdBy,
        members: allMembers,
        posts: [],
        coverImage: coverImage,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(archive.toMap());

      dev.log('Shared archive created: ${docRef.id}',
          name: 'SharedArchiveService');

      return docRef.id;
    } catch (e, stackTrace) {
      dev.log(
        'Failed to create shared archive: $e',
        name: 'SharedArchiveService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// 아카이브 정보 조회
  Future<SharedArchive?> getArchive(String archiveId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(archiveId).get();

      if (!doc.exists) {
        return null;
      }

      return SharedArchive.fromFirestore(doc);
    } catch (e) {
      dev.log('Failed to get archive: $e', name: 'SharedArchiveService');
      return null;
    }
  }

  /// 내가 속한 아카이브 목록 조회
  Future<List<SharedArchive>> getMyArchives(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('members', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SharedArchive.fromFirestore(doc))
          .toList();
    } catch (e) {
      dev.log('Failed to get my archives: $e', name: 'SharedArchiveService');
      return [];
    }
  }

  /// 아카이브 정보 스트림 (실시간 업데이트)
  Stream<SharedArchive?> getArchiveStream(String archiveId) {
    return _firestore
        .collection(_collectionName)
        .doc(archiveId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return SharedArchive.fromFirestore(doc);
    });
  }

  /// 내 아카이브 목록 스트림 (실시간 업데이트)
  Stream<List<SharedArchive>> getMyArchivesStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('members', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SharedArchive.fromFirestore(doc))
          .toList();
    });
  }

  /// 아카이브 정보 수정
  Future<void> updateArchive({
    required String archiveId,
    String? name,
    String? description,
    String? coverImage,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (coverImage != null) updates['coverImage'] = coverImage;

      await _firestore
          .collection(_collectionName)
          .doc(archiveId)
          .update(updates);

      dev.log('Archive updated: $archiveId', name: 'SharedArchiveService');
    } catch (e) {
      dev.log('Failed to update archive: $e', name: 'SharedArchiveService');
      rethrow;
    }
  }

  /// 아카이브 삭제
  Future<void> deleteArchive(String archiveId) async {
    try {
      await _firestore.collection(_collectionName).doc(archiveId).delete();

      dev.log('Archive deleted: $archiveId', name: 'SharedArchiveService');
    } catch (e) {
      dev.log('Failed to delete archive: $e', name: 'SharedArchiveService');
      rethrow;
    }
  }

  /// 멤버 추가
  Future<void> addMember({
    required String archiveId,
    required String userId,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(archiveId).update({
        'members': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      dev.log('Member added to archive: $archiveId - $userId',
          name: 'SharedArchiveService');
    } catch (e) {
      dev.log('Failed to add member: $e', name: 'SharedArchiveService');
      rethrow;
    }
  }

  /// 멤버 제거
  Future<void> removeMember({
    required String archiveId,
    required String userId,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(archiveId).update({
        'members': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      dev.log('Member removed from archive: $archiveId - $userId',
          name: 'SharedArchiveService');
    } catch (e) {
      dev.log('Failed to remove member: $e', name: 'SharedArchiveService');
      rethrow;
    }
  }

  /// 게시물 추가
  Future<void> addPost({
    required String archiveId,
    required String postId,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(archiveId).update({
        'posts': FieldValue.arrayUnion([postId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      dev.log('Post added to archive: $archiveId - $postId',
          name: 'SharedArchiveService');
    } catch (e) {
      dev.log('Failed to add post: $e', name: 'SharedArchiveService');
      rethrow;
    }
  }

  /// 게시물 제거
  Future<void> removePost({
    required String archiveId,
    required String postId,
  }) async {
    try {
      await _firestore.collection(_collectionName).doc(archiveId).update({
        'posts': FieldValue.arrayRemove([postId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      dev.log('Post removed from archive: $archiveId - $postId',
          name: 'SharedArchiveService');
    } catch (e) {
      dev.log('Failed to remove post: $e', name: 'SharedArchiveService');
      rethrow;
    }
  }

  /// 아카이브 나가기
  Future<void> leaveArchive({
    required String archiveId,
    required String userId,
  }) async {
    try {
      final archive = await getArchive(archiveId);
      if (archive == null) {
        throw Exception('Archive not found');
      }

      // 생성자는 나갈 수 없음
      if (archive.createdBy == userId) {
        throw Exception('Creator cannot leave the archive');
      }

      await removeMember(archiveId: archiveId, userId: userId);

      dev.log('User left archive: $archiveId - $userId',
          name: 'SharedArchiveService');
    } catch (e) {
      dev.log('Failed to leave archive: $e', name: 'SharedArchiveService');
      rethrow;
    }
  }

  /// 아카이브 멤버 수 조회
  Future<int> getMemberCount(String archiveId) async {
    try {
      final archive = await getArchive(archiveId);
      return archive?.memberCount ?? 0;
    } catch (e) {
      dev.log('Failed to get member count: $e', name: 'SharedArchiveService');
      return 0;
    }
  }

  /// 사용자가 특정 아카이브의 멤버인지 확인
  Future<bool> isMember({
    required String archiveId,
    required String userId,
  }) async {
    try {
      final archive = await getArchive(archiveId);
      return archive?.isMember(userId) ?? false;
    } catch (e) {
      dev.log('Failed to check membership: $e', name: 'SharedArchiveService');
      return false;
    }
  }

  /// 사용자가 특정 아카이브의 생성자인지 확인
  Future<bool> isCreator({
    required String archiveId,
    required String userId,
  }) async {
    try {
      final archive = await getArchive(archiveId);
      return archive?.isCreator(userId) ?? false;
    } catch (e) {
      dev.log('Failed to check creator: $e', name: 'SharedArchiveService');
      return false;
    }
  }
}
