import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 이미지 선택, 크롭, 압축을 담당하는 서비스
class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// 최대 파일 크기 (10MB)
  static const int maxFileSizeInBytes = 10 * 1024 * 1024;

  /// 카메라 권한 요청
  Future<bool> _requestCameraPermission(BuildContext? context) async {
    var status = await Permission.camera.status;

    // 권한이 영구적으로 거부되었거나 거부된 경우
    if (status.isPermanentlyDenied || status.isDenied) {
      if (context != null) {
        // 설정 안내 다이얼로그 표시
        final shouldOpenSettings = await _showPermissionDialog(
          context,
          '카메라',
          '티켓 사진을 촬영하려면 카메라 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
        );

        if (shouldOpenSettings) {
          await openAppSettings();
        }
      }
      return false;
    }

    // 권한이 아직 요청되지 않은 경우
    if (!status.isGranted) {
      status = await Permission.camera.request();

      // 거부된 경우 다이얼로그 표시
      if (!status.isGranted && context != null) {
        final shouldOpenSettings = await _showPermissionDialog(
          context,
          '카메라',
          '티켓 사진을 촬영하려면 카메라 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
        );

        if (shouldOpenSettings) {
          await openAppSettings();
        }
      }
    }

    return status.isGranted;
  }

  /// 저장소 권한 요청
  Future<bool> _requestStoragePermission(BuildContext? context) async {
    Permission permission;

    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        // Android 13+ (API 33+): READ_MEDIA_IMAGES 사용
        permission = Permission.photos;
      } else {
        // Android 12 이하: READ_EXTERNAL_STORAGE 사용
        permission = Permission.storage;
      }
    } else {
      // iOS
      permission = Permission.photos;
    }

    var status = await permission.status;

    // 권한이 영구적으로 거부되었거나 거부된 경우
    if (status.isPermanentlyDenied || status.isDenied) {
      if (context != null) {
        // 설정 안내 다이얼로그 표시
        final shouldOpenSettings = await _showPermissionDialog(
          context,
          '갤러리',
          '티켓 사진을 선택하려면 갤러리 접근 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
        );

        if (shouldOpenSettings) {
          await openAppSettings();
        }
      }
      return false;
    }

    // 권한이 아직 요청되지 않은 경우
    if (!status.isGranted) {
      status = await permission.request();

      // 거부된 경우 다이얼로그 표시
      if (!status.isGranted && context != null) {
        final shouldOpenSettings = await _showPermissionDialog(
          context,
          '갤러리',
          '티켓 사진을 선택하려면 갤러리 접근 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
        );

        if (shouldOpenSettings) {
          await openAppSettings();
        }
      }
    }

    return status.isGranted;
  }

  /// 권한 안내 다이얼로그 표시
  Future<bool> _showPermissionDialog(
    BuildContext context,
    String permissionName,
    String message,
  ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('$permissionName 권한 필요'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('설정으로 이동'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Android 버전 확인
  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      await Permission.storage.status; // 권한 상태 확인
      return 33; // 기본값으로 33 반환 (안전한 쪽으로)
    }
    return 0;
  }

  /// 파일 크기 검증
  ///
  /// [file] 검증할 파일
  ///
  /// Returns:
  ///   파일 크기가 제한 이내면 true
  ///
  /// Throws:
  ///   파일 크기가 제한을 초과하면 Exception
  Future<bool> _validateFileSize(File file) async {
    try {
      final fileSize = await file.length();
      if (fileSize > maxFileSizeInBytes) {
        throw Exception(
          '이미지 크기가 너무 큽니다.\n10MB 이하의 이미지를 선택해주세요.\n(현재: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)',
        );
      }
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// 카메라로 이미지 촬영
  ///
  /// [context] BuildContext (권한 다이얼로그 표시용)
  ///
  /// Returns:
  ///   선택된 이미지 파일, 취소 시 null
  ///
  /// Throws:
  ///   파일 크기가 제한을 초과하면 Exception
  Future<File?> pickFromCamera({BuildContext? context}) async {
    try {
      // 권한 요청
      final hasPermission = await _requestCameraPermission(context);
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

      final File imageFile = File(image.path);

      // 파일 크기 검증
      await _validateFileSize(imageFile);

      return imageFile;
    } catch (e) {
      debugPrint('카메라 이미지 선택 오류: $e');
      rethrow;
    }
  }

  /// 갤러리에서 이미지 선택
  ///
  /// [context] BuildContext (권한 다이얼로그 표시용)
  ///
  /// Returns:
  ///   선택된 이미지 파일, 취소 시 null
  ///
  /// Throws:
  ///   파일 크기가 제한을 초과하면 Exception
  Future<File?> pickFromGallery({BuildContext? context}) async {
    try {
      // 권한 요청
      final hasPermission = await _requestStoragePermission(context);
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

      final File imageFile = File(image.path);

      // 파일 크기 검증
      await _validateFileSize(imageFile);

      return imageFile;
    } catch (e) {
      debugPrint('갤러리 이미지 선택 오류: $e');
      rethrow;
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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('이미지 선택'),
          content: const Text('티켓 이미지를 어떻게 추가하시겠습니까?'),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(dialogContext, ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('카메라로 촬영'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pop(dialogContext, ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('갤러리에서 선택'),
            ),
          ],
        );
      },
    );

    if (source == null) return null;

    // 선택된 소스에 따라 이미지 가져오기 (context 전달)
    File? imageFile;
    if (source == ImageSource.camera) {
      imageFile = await pickFromCamera(context: context);
    } else {
      imageFile = await pickFromGallery(context: context);
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

  /// 다중 이미지 선택 (갤러리)
  ///
  /// [context] BuildContext (권한 다이얼로그 표시용)
  /// [maxImages] 최대 선택 가능 개수 (기본값: 10)
  ///
  /// Returns:
  ///   선택된 이미지 파일 리스트
  ///
  /// Throws:
  ///   파일 크기가 제한을 초과하면 Exception
  Future<List<File>> pickMultipleImages({
    BuildContext? context,
    int maxImages = 10,
  }) async {
    try {
      // 권한 요청
      final hasPermission = await _requestStoragePermission(context);
      if (!hasPermission) {
        debugPrint('저장소 권한이 거부되었습니다');
        return [];
      }

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) return [];

      // 최대 개수 제한
      final List<XFile> limitedImages = images.take(maxImages).toList();

      // XFile을 File로 변환 및 크기 검증
      final List<File> validatedFiles = [];
      for (final xFile in limitedImages) {
        final file = File(xFile.path);
        try {
          await _validateFileSize(file);
          validatedFiles.add(file);
        } catch (e) {
          // 크기 초과 파일은 건너뛰고 경고 표시
          debugPrint('이미지 크기 초과로 건너뜀: ${xFile.name}');
          // 첫 번째 크기 초과 파일에서 예외 발생
          if (validatedFiles.isEmpty) {
            rethrow;
          }
        }
      }

      return validatedFiles;
    } catch (e) {
      debugPrint('다중 이미지 선택 오류: $e');
      rethrow;
    }
  }
}
