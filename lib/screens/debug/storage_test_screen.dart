import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/storage_service.dart';
import '../../services/image_service.dart';

/// Firebase Storage 테스트 화면 (디버그용)
class StorageTestScreen extends StatefulWidget {
  const StorageTestScreen({super.key});

  @override
  State<StorageTestScreen> createState() => _StorageTestScreenState();
}

class _StorageTestScreenState extends State<StorageTestScreen> {
  final StorageService _storageService = StorageService();
  final ImageService _imageService = ImageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? _selectedImage;
  List<File> _selectedImages = [];
  String _uploadedUrl = '';
  List<String> _uploadedUrls = [];
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _result = '';
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _signInAnonymously();
  }

  /// 익명 로그인 (테스트용)
  Future<void> _signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      setState(() {
        _isAuthenticated = true;
        _result = '✅ 익명 로그인 완료 (UID: ${userCredential.user?.uid})';
      });
      debugPrint('익명 로그인 성공: ${userCredential.user?.uid}');
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _result = '''
⚠️ 익명 로그인 실패 (Storage 테스트는 가능)

Firebase Console에서 익명 인증을 활성화하세요:
1. Authentication > Sign-in method
2. "익명" 제공업체 활성화

에러: $e
        ''';
      });
      debugPrint('익명 로그인 실패: $e');
    }
  }

  /// 단일 이미지 선택
  Future<void> _pickSingleImage() async {
    setState(() => _isLoading = true);

    final File? imageFile = await _imageService.pickAndCropImage(
      context,
      showCrop: false,
    );

    setState(() {
      _selectedImage = imageFile;
      _isLoading = false;
      if (imageFile != null) {
        _result = '✅ 이미지 선택 완료';
      }
    });
  }

  /// 다중 이미지 선택 (최대 10개)
  Future<void> _pickMultipleImages() async {
    setState(() => _isLoading = true);

    try {
      final List<File> imageFiles = await _imageService.pickMultipleImages(
        maxImages: 10,
      );

      setState(() {
        _selectedImages = imageFiles;
        _result = '✅ ${imageFiles.length}개 이미지 선택 완료';
      });
    } catch (e) {
      setState(() {
        _result = '❌ 이미지 선택 실패: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 단일 이미지 업로드
  Future<void> _uploadSingleImage() async {
    if (_selectedImage == null) {
      setState(() {
        _result = '❌ 먼저 이미지를 선택해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _result = '';
    });

    try {
      final String downloadUrl = await _storageService.uploadTicketImage(
        imageFile: _selectedImage!,
        userId: 'test_user_123',
        postId: 'test_post_${DateTime.now().millisecondsSinceEpoch}',
      );

      setState(() {
        _uploadedUrl = downloadUrl;
        _uploadProgress = 1.0;
        _result = '✅ 티켓 이미지 업로드 성공!\n\nURL: $downloadUrl';
      });
    } catch (e) {
      setState(() {
        _result = '❌ 업로드 실패: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 다중 이미지 업로드
  Future<void> _uploadMultipleImages() async {
    if (_selectedImages.isEmpty) {
      setState(() {
        _result = '❌ 먼저 이미지를 선택해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _result = '';
    });

    try {
      final List<String> downloadUrls = await _storageService.uploadAdditionalPhotos(
        imageFiles: _selectedImages,
        userId: 'test_user_123',
        postId: 'test_post_${DateTime.now().millisecondsSinceEpoch}',
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      setState(() {
        _uploadedUrls = downloadUrls;
        _uploadProgress = 1.0;
        _result = '✅ ${downloadUrls.length}개 이미지 업로드 성공!';
      });
    } catch (e) {
      setState(() {
        _result = '❌ 업로드 실패: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 압축 테스트
  Future<void> _testCompression() async {
    // 단일 또는 다중 이미지 확인
    File? imageToCompress;
    if (_selectedImage != null) {
      imageToCompress = _selectedImage;
    } else if (_selectedImages.isNotEmpty) {
      imageToCompress = _selectedImages.first;
    }

    if (imageToCompress == null) {
      setState(() {
        _result = '❌ 먼저 이미지를 선택해주세요';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final double originalSize = await _storageService.getFileSizeMB(imageToCompress);

      final File compressedFile = await _storageService.compressImage(imageToCompress);
      final double compressedSize = await _storageService.getFileSizeMB(compressedFile);

      final double compressionRatio = ((originalSize - compressedSize) / originalSize * 100);

      // 다중 이미지인 경우 안내 메시지 추가
      final String multiImageNote = _selectedImages.isNotEmpty && _selectedImage == null
          ? '(다중 선택 시 첫 번째 이미지 테스트)\n\n'
          : '';

      setState(() {
        _result = '''
✅ 압축 완료!

${multiImageNote}원본 크기: ${originalSize.toStringAsFixed(2)} MB
압축 후: ${compressedSize.toStringAsFixed(2)} MB
압축률: ${compressionRatio.toStringAsFixed(1)}%
        ''';
      });

      // 임시 압축 파일 삭제
      if (await compressedFile.exists()) {
        await compressedFile.delete();
      }
    } catch (e) {
      setState(() {
        _result = '❌ 압축 실패: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage 테스트'),
        backgroundColor: colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이미지 선택 버튼
            _buildSectionTitle('1. 이미지 선택'),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickSingleImage,
                    icon: const Icon(Icons.image),
                    label: const Text('단일 선택'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _pickMultipleImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('다중 선택'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 선택된 이미지 미리보기
            if (_selectedImage != null || _selectedImages.isNotEmpty) ...[
              _buildSectionTitle('선택된 이미지'),
              _buildImagePreview(),
              const SizedBox(height: 24),
            ],

            // 테스트 버튼
            _buildSectionTitle('2. 테스트'),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testCompression,
              icon: const Icon(Icons.compress),
              label: const Text('압축 테스트'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadSingleImage,
              icon: const Icon(Icons.upload),
              label: const Text('단일 업로드'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadMultipleImages,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('다중 업로드'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // 진행률 표시
            if (_isLoading && _uploadProgress > 0) ...[
              _buildSectionTitle('업로드 진행률'),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
            ],

            // 로딩 인디케이터
            if (_isLoading && _uploadProgress == 0)
              const Center(child: CircularProgressIndicator()),

            // 결과 메시지
            if (_result.isNotEmpty) ...[
              _buildSectionTitle('결과'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result.startsWith('✅')
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _result.startsWith('✅') ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _result,
                  style: TextStyle(
                    color: _result.startsWith('✅') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 업로드된 이미지 미리보기
            if (_uploadedUrl.isNotEmpty || _uploadedUrls.isNotEmpty) ...[
              _buildSectionTitle('업로드된 이미지'),
              _buildUploadedImagePreview(),
            ],
          ],
        ),
      ),
    );
  }

  /// 섹션 제목
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 선택된 이미지 미리보기
  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          _selectedImage!,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    }

    if (_selectedImages.isNotEmpty) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _selectedImages.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedImages[index],
              fit: BoxFit.cover,
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  /// 업로드된 이미지 미리보기
  Widget _buildUploadedImagePreview() {
    if (_uploadedUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          _uploadedUrl,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
      );
    }

    if (_uploadedUrls.isNotEmpty) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _uploadedUrls.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _uploadedUrls[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
