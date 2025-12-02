import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

/// Firebase Storage 이미지 업로드 서비스
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 이미지 압축
  ///
  /// [imageFile]: 원본 이미지 파일
  /// [quality]: 압축 품질 (0-100, 기본 80)
  /// [maxWidth]: 최대 너비 (기본 1920px)
  Future<File> compressImage(
    File imageFile, {
    int quality = 80,
    int maxWidth = 1920,
  }) async {
    try {
      final String targetPath = imageFile.path.replaceAll('.jpg', '_compressed.jpg');

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) {
        throw Exception('이미지 압축 실패');
      }

      return File(compressedFile.path);
    } catch (e) {
      throw Exception('이미지 압축 오류: $e');
    }
  }

  /// 티켓 이미지 업로드
  ///
  /// [imageFile]: 업로드할 이미지 파일
  /// [userId]: 사용자 ID
  /// [postId]: 게시글 ID
  ///
  /// Returns: 업로드된 이미지의 다운로드 URL
  Future<String> uploadTicketImage({
    required File imageFile,
    required String userId,
    required String postId,
  }) async {
    try {
      // 1. 이미지 압축
      final compressedFile = await compressImage(imageFile);

      // 2. Storage 경로 설정
      final String fileName = 'ticket.jpg';
      final String storagePath = 'users/$userId/posts/$postId/$fileName';

      // 3. 업로드
      final Reference ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(compressedFile);

      // 4. 완료 대기
      final TaskSnapshot snapshot = await uploadTask;

      // 5. 다운로드 URL 반환
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // 6. 압축된 임시 파일 삭제
      if (await compressedFile.exists()) {
        await compressedFile.delete();
      }

      return downloadUrl;
    } catch (e) {
      throw Exception('티켓 이미지 업로드 실패: $e');
    }
  }

  /// 추가 사진 업로드 (다중)
  ///
  /// [imageFiles]: 업로드할 이미지 파일 리스트 (최대 10개)
  /// [userId]: 사용자 ID
  /// [postId]: 게시글 ID
  /// [onProgress]: 진행률 콜백 (0.0 ~ 1.0)
  ///
  /// Returns: 업로드된 이미지들의 다운로드 URL 리스트
  Future<List<String>> uploadAdditionalPhotos({
    required List<File> imageFiles,
    required String userId,
    required String postId,
    void Function(double)? onProgress,
  }) async {
    try {
      // 최대 10개 제한
      if (imageFiles.length > 10) {
        throw Exception('추가 사진은 최대 10장까지 업로드 가능합니다');
      }

      final List<String> downloadUrls = [];
      final int totalFiles = imageFiles.length;

      for (int i = 0; i < imageFiles.length; i++) {
        final File imageFile = imageFiles[i];

        // 1. 이미지 압축
        final compressedFile = await compressImage(imageFile);

        // 2. Storage 경로 설정
        final String fileName = 'photo_${i + 1}.jpg';
        final String storagePath = 'users/$userId/posts/$postId/$fileName';

        // 3. 업로드
        final Reference ref = _storage.ref().child(storagePath);
        final UploadTask uploadTask = ref.putFile(compressedFile);

        // 4. 완료 대기
        final TaskSnapshot snapshot = await uploadTask;

        // 5. 다운로드 URL 추가
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);

        // 6. 압축된 임시 파일 삭제
        if (await compressedFile.exists()) {
          await compressedFile.delete();
        }

        // 7. 진행률 콜백
        if (onProgress != null) {
          final double progress = (i + 1) / totalFiles;
          onProgress(progress);
        }
      }

      return downloadUrls;
    } catch (e) {
      throw Exception('추가 사진 업로드 실패: $e');
    }
  }

  /// 단일 이미지 업로드 (진행률 스트림)
  ///
  /// [imageFile]: 업로드할 이미지 파일
  /// [userId]: 사용자 ID
  /// [postId]: 게시글 ID
  /// [fileName]: 파일 이름
  ///
  /// Returns: 업로드 진행률 스트림 및 다운로드 URL
  Stream<double> uploadImageWithProgress({
    required File imageFile,
    required String userId,
    required String postId,
    required String fileName,
  }) async* {
    try {
      // 1. 이미지 압축
      final compressedFile = await compressImage(imageFile);

      // 2. Storage 경로 설정
      final String storagePath = 'users/$userId/posts/$postId/$fileName';

      // 3. 업로드
      final Reference ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(compressedFile);

      // 4. 진행률 스트림
      await for (final TaskSnapshot snapshot in uploadTask.snapshotEvents) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        yield progress;
      }

      // 5. 압축된 임시 파일 삭제
      if (await compressedFile.exists()) {
        await compressedFile.delete();
      }
    } catch (e) {
      throw Exception('이미지 업로드 실패: $e');
    }
  }

  /// 이미지 삭제
  ///
  /// [imageUrl]: 삭제할 이미지 URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('이미지 삭제 실패: $e');
    }
  }

  /// 게시글의 모든 이미지 삭제
  ///
  /// [userId]: 사용자 ID
  /// [postId]: 게시글 ID
  Future<void> deletePostImages({
    required String userId,
    required String postId,
  }) async {
    try {
      final String storagePath = 'users/$userId/posts/$postId';
      final Reference ref = _storage.ref().child(storagePath);

      print('🗑️ Storage 삭제 시작: $storagePath');

      // 폴더 내 모든 파일 조회
      final ListResult result = await ref.listAll();

      print('📁 발견된 파일 개수: ${result.items.length}');

      if (result.items.isEmpty) {
        print('⚠️ 경고: 삭제할 파일이 없습니다');
        // 파일이 없어도 에러를 던지지 않고 정상 종료
        return;
      }

      // 모든 파일 삭제
      int deletedCount = 0;
      for (final Reference fileRef in result.items) {
        try {
          print('🗑️ 삭제 중: ${fileRef.fullPath}');
          await fileRef.delete();
          deletedCount++;
          print('✅ 삭제 성공: ${fileRef.fullPath}');
        } catch (e) {
          print('❌ 삭제 실패: ${fileRef.fullPath}, 오류: $e');
          // 개별 파일 삭제 실패 시에도 계속 진행
          continue;
        }
      }

      print('✅ Storage 삭제 완료: $deletedCount/${result.items.length}개 파일 삭제됨');

      if (deletedCount == 0 && result.items.isNotEmpty) {
        throw Exception('모든 파일 삭제 실패');
      }
    } catch (e) {
      print('❌ deletePostImages 오류: $e');
      throw Exception('게시글 이미지 삭제 실패: $e');
    }
  }

  /// 파일 크기 확인 (MB 단위)
  ///
  /// [file]: 확인할 파일
  /// Returns: 파일 크기 (MB)
  Future<double> getFileSizeMB(File file) async {
    final int bytes = await file.length();
    return bytes / (1024 * 1024);
  }

  /// 파일 크기 제한 확인 (5MB)
  ///
  /// [file]: 확인할 파일
  /// Returns: 크기가 제한 이내면 true
  Future<bool> isFileSizeValid(File file, {double maxSizeMB = 5.0}) async {
    final double sizeMB = await getFileSizeMB(file);
    return sizeMB <= maxSizeMB;
  }
}
