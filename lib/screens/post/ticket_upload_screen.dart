import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../services/image_service.dart';
import '../../services/ocr_service.dart';
import '../../services/ticket_parser_service.dart';
import '../../models/game_info.dart';
import '../../providers/theme_provider.dart';

/// 티켓 이미지 업로드 화면
class TicketUploadScreen extends StatefulWidget {
  const TicketUploadScreen({super.key});

  @override
  State<TicketUploadScreen> createState() => _TicketUploadScreenState();
}

class _TicketUploadScreenState extends State<TicketUploadScreen> {
  final ImageService _imageService = ImageService();
  final OcrService _ocrService = OcrService();
  final TicketParserService _parserService = TicketParserService();
  File? _ticketImage;
  RecognizedText? _recognizedText;
  GameInfo? _parsedGameInfo;
  bool _isLoading = false;
  bool _isProcessingOcr = false;

  /// 이미지 선택 및 크롭
  Future<void> _pickImage() async {
    setState(() => _isLoading = true);

    final File? imageFile = await _imageService.pickAndCropImage(
      context,
      showCrop: true,
    );

    setState(() {
      _ticketImage = imageFile;
      _isLoading = false;
    });
  }

  /// 이미지 재선택
  Future<void> _rePickImage() async {
    await _pickImage();
  }

  /// OCR 처리 실행
  Future<void> _processOcr() async {
    if (_ticketImage == null) return;

    setState(() => _isProcessingOcr = true);

    try {
      // 1. OCR 처리
      final RecognizedText recognizedText = await _ocrService.recognizeText(_ticketImage!);

      // 2. 경기 정보 파싱
      final GameInfo gameInfo = _parserService.parseTicketInfo(recognizedText);

      // 3. 결과 저장
      setState(() {
        _recognizedText = recognizedText;
        _parsedGameInfo = gameInfo;
      });

      // 4. 상세 로그 출력 (OCR + 파싱)
      _ocrService.printDetailedLog(recognizedText);
      _parserService.printParsingDetails(recognizedText, gameInfo);

      // 5. OCR 결과 확인 화면으로 이동
      if (mounted) {
        context.push('/ocr-result', extra: {
          'ticketImage': _ticketImage!,
          'gameInfo': gameInfo,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR 처리 중 오류 발생: $e')),
        );
      }
    } finally {
      setState(() => _isProcessingOcr = false);
    }
  }

  /// 다음 단계로 이동 (OCR 처리)
  void _goToNext() {
    if (_ticketImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('티켓 이미지를 선택해주세요')),
      );
      return;
    }

    _processOcr();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('티켓 업로드'),
        backgroundColor: colorScheme.surface,
      ),
      body: SafeArea(
        child: _isLoading || _isProcessingOcr
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isProcessingOcr ? 'OCR 처리 중...' : '이미지 로딩 중...',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              )
            : _ticketImage == null
                ? _buildEmptyState(colorScheme)
                : _buildImagePreview(colorScheme),
      ),
    );
  }

  /// 빈 상태 (이미지 미선택)
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘
            Icon(
              Icons.confirmation_number_outlined,
              size: 120,
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),

            // 안내 텍스트
            Text(
              '티켓 이미지를 추가해주세요',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '카메라로 촬영하거나\n갤러리에서 선택할 수 있습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // 이미지 선택 버튼
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate, size: 28),
              label: const Text(
                '이미지 선택',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 이미지 미리보기
  Widget _buildImagePreview(ColorScheme colorScheme) {
    return Column(
      children: [
        // 이미지 표시 영역
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _ticketImage!,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),

        // 버튼 영역
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 재선택 버튼
              OutlinedButton.icon(
                onPressed: _rePickImage,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 선택'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 다음 단계 버튼
              ElevatedButton.icon(
                onPressed: _goToNext,
                icon: const Icon(Icons.arrow_forward),
                label: const Text(
                  '다음 단계',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
