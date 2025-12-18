/// 공유 아카이브 상태 관리 Provider
///
/// 사용자가 속한 공유 아카이브 목록을 관리하고
/// 실시간 업데이트를 제공합니다.

import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/shared_archive_model.dart';
import '../services/shared_archive_service.dart';

class SharedArchivesProvider extends ChangeNotifier {
  final SharedArchiveService _archiveService = SharedArchiveService();

  List<SharedArchive> _archives = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<SharedArchive>>? _archivesSubscription;

  /// 아카이브 목록
  List<SharedArchive> get archives => _archives;

  /// 로딩 상태
  bool get isLoading => _isLoading;

  /// 에러 메시지
  String? get errorMessage => _errorMessage;

  /// 아카이브 수
  int get archiveCount => _archives.length;

  /// 비어있는지 확인
  bool get isEmpty => _archives.isEmpty;

  /// 사용자 ID 설정 및 아카이브 목록 구독
  void setUserId(String? userId) {
    // 기존 구독 취소
    _archivesSubscription?.cancel();
    _archives = [];
    _errorMessage = null;

    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // 실시간 스트림 구독
    _isLoading = true;
    notifyListeners();

    // 첫 데이터 수신 여부 추적
    bool hasReceivedFirstData = false;

    _archivesSubscription = _archiveService
        .getMyArchivesStream(userId)
        .listen(
          (archives) {
            _archives = archives;
            _isLoading = false;
            _errorMessage = null;
            hasReceivedFirstData = true;
            notifyListeners();
          },
          onError: (error) {
            print('SharedArchivesProvider Error: $error');
            // Firestore 인덱스 에러 감지
            if (error.toString().contains('index') ||
                error.toString().contains('FAILED_PRECONDITION')) {
              _errorMessage = '인덱스 빌드 중입니다.\n잠시 후 다시 시도해주세요.';
            } else {
              _errorMessage = '아카이브 목록을 불러오지 못했습니다';
            }
            _isLoading = false;
            notifyListeners();
          },
          cancelOnError: false, // 에러 발생 시에도 스트림 유지
        );

    // 첫 데이터 로딩 타임아웃 체크 (10초)
    Future.delayed(const Duration(seconds: 10), () {
      // 10초 후에도 첫 데이터를 받지 못하고 여전히 로딩 중이면 타임아웃
      if (_isLoading && !hasReceivedFirstData) {
        _errorMessage = '서버 응답이 없습니다.\n네트워크를 확인해주세요.';
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// 아카이브 생성
  Future<String?> createArchive({
    required String name,
    required String description,
    required String createdBy,
    required List<String> members,
    String? coverImage,
  }) async {
    try {
      final archiveId = await _archiveService.createArchive(
        name: name,
        description: description,
        createdBy: createdBy,
        members: members,
        coverImage: coverImage,
      );

      return archiveId;
    } catch (e) {
      _errorMessage = '아카이브 생성에 실패했습니다';
      notifyListeners();
      return null;
    }
  }

  /// 아카이브 수정
  Future<bool> updateArchive({
    required String archiveId,
    String? name,
    String? description,
    String? coverImage,
  }) async {
    try {
      await _archiveService.updateArchive(
        archiveId: archiveId,
        name: name,
        description: description,
        coverImage: coverImage,
      );

      return true;
    } catch (e) {
      _errorMessage = '아카이브 수정에 실패했습니다';
      notifyListeners();
      return false;
    }
  }

  /// 아카이브 삭제
  Future<bool> deleteArchive(String archiveId) async {
    try {
      await _archiveService.deleteArchive(archiveId);
      return true;
    } catch (e) {
      _errorMessage = '아카이브 삭제에 실패했습니다';
      notifyListeners();
      return false;
    }
  }

  /// 멤버 추가
  Future<bool> addMember({
    required String archiveId,
    required String userId,
  }) async {
    try {
      await _archiveService.addMember(
        archiveId: archiveId,
        userId: userId,
      );
      return true;
    } catch (e) {
      _errorMessage = '멤버 추가에 실패했습니다';
      notifyListeners();
      return false;
    }
  }

  /// 멤버 제거
  Future<bool> removeMember({
    required String archiveId,
    required String userId,
  }) async {
    try {
      await _archiveService.removeMember(
        archiveId: archiveId,
        userId: userId,
      );
      return true;
    } catch (e) {
      _errorMessage = '멤버 제거에 실패했습니다';
      notifyListeners();
      return false;
    }
  }

  /// 게시물 추가
  Future<bool> addPost({
    required String archiveId,
    required String postId,
  }) async {
    try {
      await _archiveService.addPost(
        archiveId: archiveId,
        postId: postId,
      );
      return true;
    } catch (e) {
      _errorMessage = '게시물 추가에 실패했습니다';
      notifyListeners();
      return false;
    }
  }

  /// 게시물 제거
  Future<bool> removePost({
    required String archiveId,
    required String postId,
  }) async {
    try {
      await _archiveService.removePost(
        archiveId: archiveId,
        postId: postId,
      );
      return true;
    } catch (e) {
      _errorMessage = '게시물 제거에 실패했습니다';
      notifyListeners();
      return false;
    }
  }

  /// 아카이브 나가기
  Future<bool> leaveArchive({
    required String archiveId,
    required String userId,
  }) async {
    try {
      await _archiveService.leaveArchive(
        archiveId: archiveId,
        userId: userId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().contains('Creator')
          ? '생성자는 아카이브를 나갈 수 없습니다'
          : '아카이브 나가기에 실패했습니다';
      notifyListeners();
      return false;
    }
  }

  /// ID로 아카이브 찾기
  SharedArchive? getArchiveById(String archiveId) {
    try {
      return _archives.firstWhere((archive) => archive.id == archiveId);
    } catch (e) {
      return null;
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _archivesSubscription?.cancel();
    super.dispose();
  }
}
