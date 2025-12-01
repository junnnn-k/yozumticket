import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 이미지 선택, 크롭, 압축을 담당하는 서비스
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// 카메라 권한 요청
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// 저장소 권한 요청 (Android 13 미만)
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        // Android 13+ (API 33+): READ_MEDIA_IMAGES 사용
        final status = await Permission.photos.request();
        return status.isGranted;
      } else {
        // Android 12 이하: READ_EXTERNAL_STORAGE 사용
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true; // iOS는 자동 처리
  }

  /// Android 버전 확인
  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      final androidInfo = await Permission.storage.status;
      return 33; // 기본값으로 33 반환 (안전한 쪽으로)
    }
    return 0;
  }

  /// 카메라로 이미지 촬영
  ///
  /// Returns:
  ///   선택된 이미지 파일, 취소 시 null
  Future<File?> pickFromCamera() async {
    try {
      // 권한 요청
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        debugPrint('카메라 권한이 거부되었습니다');
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      debugPrint('카메라 이미지 선택 오류: $e');
      return null;
    }
  }

  /// 갤러리에서 이미지 선택
  ///
  /// Returns:
  ///   선택된 이미지 파일, 취소 시 null
  Future<File?> pickFromGallery() async {
    try {
      // 권한 요청
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        debugPrint('저장소 권한이 거부되었습니다');
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      debugPrint('갤러리 이미지 선택 오류: $e');
      return null;
    }
  }

  /// 이미지 크롭
  ///
  /// [imageFile] 크롭할 이미지 파일
  ///
  /// Returns:
  ///   크롭된 이미지 파일, 취소 시 null
  Future<File?> cropImage(File imageFile) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '티켓 이미지 자르기',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
            ],
          ),
          IOSUiSettings(
            title: '티켓 이미지 자르기',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
            ],
          ),
        ],
      );

      if (croppedFile == null) return null;

      return File(croppedFile.path);
    } catch (e) {
      debugPrint('이미지 크롭 오류: $e');
      return null;
    }
  }

  /// 이미지 선택 소스를 묻는 다이얼로그 표시
  ///
  /// [context] BuildContext
  ///
  /// Returns:
  ///   선택된 이미지 파일, 취소 시 null
  Future<File?> showImageSourceDialog(BuildContext context) async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('이미지 선택'),
          content: const Text('티켓 이미지를 어떻게 추가하시겠습니까?'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('카메라로 촬영'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('갤러리에서 선택'),
            ),
          ],
        );
      },
    );

    if (source == null) return null;

    // 선택된 소스에 따라 이미지 가져오기
    File? imageFile;
    if (source == ImageSource.camera) {
      imageFile = await pickFromCamera();
    } else {
      imageFile = await pickFromGallery();
    }

    return imageFile;
  }

  /// 이미지 선택 및 크롭 (전체 프로세스)
  ///
  /// [context] BuildContext
  /// [showCrop] 크롭 UI 표시 여부 (기본값: true)
  ///
  /// Returns:
  ///   최종 이미지 파일, 취소 시 null
  Future<File?> pickAndCropImage(
    BuildContext context, {
    bool showCrop = true,
  }) async {
    // 1. 이미지 선택
    final File? imageFile = await showImageSourceDialog(context);
    if (imageFile == null) return null;

    // 2. 크롭 (옵션)
    if (showCrop) {
      final File? croppedFile = await cropImage(imageFile);
      return croppedFile ?? imageFile; // 크롭 취소 시 원본 반환
    }

    return imageFile;
  }
}
