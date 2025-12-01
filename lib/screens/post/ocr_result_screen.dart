import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_info.dart';
import '../../core/constants/baseball_data.dart';
import '../../providers/theme_provider.dart';

/// OCR 결과 확인 및 수정 화면
class OcrResultScreen extends StatefulWidget {
  final File ticketImage;
  final GameInfo gameInfo;

  const OcrResultScreen({
    super.key,
    required this.ticketImage,
    required this.gameInfo,
  });

  @override
  State<OcrResultScreen> createState() => _OcrResultScreenState();
}

class _OcrResultScreenState extends State<OcrResultScreen> {
  late TextEditingController _dateController;
  late TextEditingController _seatController;
  late TextEditingController _priceController;

  String? _selectedHomeTeam;
  String? _selectedAwayTeam;
  String? _selectedStadium;

  @override
  void initState() {
    super.initState();

    // 컨트롤러 초기화
    _dateController = TextEditingController(
      text: widget.gameInfo.date?.toString().split(' ')[0] ?? '',
    );
    _seatController = TextEditingController(
      text: widget.gameInfo.seat ?? '',
    );
    _priceController = TextEditingController(
      text: widget.gameInfo.price?.toString() ?? '',
    );

    // 드롭다운 초기값
    _selectedHomeTeam = widget.gameInfo.homeTeam;
    _selectedAwayTeam = widget.gameInfo.awayTeam;
    _selectedStadium = widget.gameInfo.stadium;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _seatController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// 날짜 선택 다이얼로그
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.gameInfo.date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _dateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  /// 정보 확인 및 다음 단계
  void _confirmAndNext() {
    // 필수 필드 검증
    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('날짜를 입력해주세요')),
      );
      return;
    }

    // TODO: 15일차에 게시글 작성 화면으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('15일차에 게시글 작성 화면이 추가됩니다')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('경기 정보 확인'),
        backgroundColor: colorScheme.surface,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 티켓 이미지 미리보기
            _buildTicketPreview(colorScheme),

            // 신뢰도 표시
            _buildConfidenceBanner(colorScheme),

            // 경기 정보 편집 폼
            _buildGameInfoForm(colorScheme),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(colorScheme),
    );
  }

  /// 티켓 이미지 미리보기
  Widget _buildTicketPreview(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: 200,
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
          widget.ticketImage,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// 신뢰도 배너
  Widget _buildConfidenceBanner(ColorScheme colorScheme) {
    final confidence = widget.gameInfo.confidence;
    final isHighConfidence = confidence >= 0.7;
    final isMediumConfidence = confidence >= 0.4;

    // 누락된 필수 정보 확인
    final missingFields = <String>[];
    if (widget.gameInfo.date == null) missingFields.add('날짜');
    if (widget.gameInfo.homeTeam == null) missingFields.add('홈팀');
    if (widget.gameInfo.awayTeam == null) missingFields.add('원정팀');
    if (widget.gameInfo.stadium == null) missingFields.add('구장');

    String message;
    if (isHighConfidence) {
      message = '신뢰도: ${(confidence * 100).toStringAsFixed(0)}% - 정보가 정확히 인식되었습니다';
    } else if (isMediumConfidence) {
      message = '신뢰도: ${(confidence * 100).toStringAsFixed(0)}% - 일부 정보를 확인해주세요';
      if (missingFields.isNotEmpty) {
        message += '\n누락: ${missingFields.join(", ")}';
      }
    } else {
      message = '신뢰도: ${(confidence * 100).toStringAsFixed(0)}% - 티켓 정보를 수동으로 입력해주세요';
      if (missingFields.isNotEmpty) {
        message += '\n누락: ${missingFields.join(", ")}';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighConfidence
            ? Colors.green.withValues(alpha: 0.1)
            : isMediumConfidence
                ? Colors.orange.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighConfidence
              ? Colors.green.withValues(alpha: 0.3)
              : isMediumConfidence
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHighConfidence
                ? Icons.check_circle
                : isMediumConfidence
                    ? Icons.info_outline
                    : Icons.warning,
            color: isHighConfidence
                ? Colors.green
                : isMediumConfidence
                    ? Colors.orange
                    : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isHighConfidence
                    ? Colors.green
                    : isMediumConfidence
                        ? Colors.orange
                        : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 경기 정보 편집 폼
  Widget _buildGameInfoForm(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '경기 정보',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // 날짜
          _buildDateField(colorScheme),
          const SizedBox(height: 16),

          // 홈팀
          _buildTeamDropdown(
            label: '홈팀',
            value: _selectedHomeTeam,
            onChanged: (value) => setState(() => _selectedHomeTeam = value),
          ),
          const SizedBox(height: 16),

          // 원정팀
          _buildTeamDropdown(
            label: '원정팀',
            value: _selectedAwayTeam,
            onChanged: (value) => setState(() => _selectedAwayTeam = value),
          ),
          const SizedBox(height: 16),

          // 구장
          _buildStadiumDropdown(colorScheme),
          const SizedBox(height: 16),

          // 좌석
          _buildTextField(
            label: '좌석',
            controller: _seatController,
            hint: '예: 1루 블루존 203-5',
          ),
          const SizedBox(height: 16),

          // 가격
          _buildTextField(
            label: '가격',
            controller: _priceController,
            hint: '예: 15000',
            keyboardType: TextInputType.number,
            suffix: const Text('원'),
          ),
        ],
      ),
    );
  }

  /// 날짜 필드
  Widget _buildDateField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '날짜',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _dateController,
          readOnly: true,
          onTap: _selectDate,
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            suffixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  /// 팀 선택 드롭다운
  Widget _buildTeamDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text('$label 선택'),
          items: BaseballData.teams.keys.map((team) {
            return DropdownMenuItem(
              value: team,
              child: Text(BaseballData.teams[team]!),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  /// 구장 선택 드롭다운
  Widget _buildStadiumDropdown(ColorScheme colorScheme) {
    final stadiums = BaseballData.teamHomeStadium.values.toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '구장',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedStadium,
          hint: const Text('구장 선택'),
          items: stadiums.map((stadium) {
            return DropdownMenuItem(
              value: stadium,
              child: Text(stadium),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedStadium = value),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  /// 텍스트 필드
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            suffix: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  /// 하단 버튼 (다시 스캔 + 정보 확인)
  Widget _buildBottomButton(ColorScheme colorScheme) {
    return Container(
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
      child: Row(
        children: [
          // 다시 스캔 버튼
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 스캔'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 정보 확인 버튼
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _confirmAndNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '정보 확인',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
