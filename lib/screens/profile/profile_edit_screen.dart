import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart' as auth;
import '../../services/user_service.dart';
import '../../services/storage_service.dart';
import '../../services/image_service.dart';
import '../../core/constants/baseball_data.dart';
import '../../core/constants/sizes.dart';

/// 프로필 수정 화면
///
/// 사용자 프로필 정보 수정 기능 제공:
/// - 프로필 이미지 변경
/// - 이름 수정
/// - 응원팀 선택 (최대 3개)
/// - 자기소개 입력
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _storageService = StorageService();
  final _imageService = ImageService();

  // 폼 필드 컨트롤러
  late TextEditingController _usernameController;
  late TextEditingController _bioController;

  // 상태 변수
  File? _selectedImage;
  String? _currentImageUrl;
  List<String> _selectedTeams = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _bioController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  /// 현재 사용자 데이터 로드
  Future<void> _loadUserData() async {
    final authProvider = context.read<auth.AuthProvider>();
    final user = authProvider.userModel;

    if (user != null) {
      setState(() {
        _usernameController.text = user.username;
        _bioController.text = user.bio;
        _currentImageUrl = user.profileImageUrl;
        _selectedTeams = List.from(user.favoriteTeams);
      });
    }
  }

  /// 프로필 이미지 선택
  Future<void> _pickImage() async {
    final image = await _imageService.pickAndCropImage(context);
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _hasChanges = true;
      });
    }
  }

  /// 응원팀 선택/해제
  void _toggleTeam(String team) {
    setState(() {
      if (_selectedTeams.contains(team)) {
        _selectedTeams.remove(team);
      } else {
        if (_selectedTeams.length < 3) {
          _selectedTeams.add(team);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('응원팀은 최대 3개까지 선택할 수 있습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      _hasChanges = true;
    });
  }

  /// 프로필 저장
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<auth.AuthProvider>();
      final userId = authProvider.userId;

      if (userId == null) {
        throw Exception('사용자 ID를 찾을 수 없습니다');
      }

      // 1. 프로필 이미지 업로드 (변경된 경우)
      String? newImageUrl;
      if (_selectedImage != null) {
        newImageUrl = await _storageService.uploadProfileImage(
          userId: userId,
          imageFile: _selectedImage!,
        );
      }

      // 2. Firestore 업데이트
      final updates = <String, dynamic>{};

      if (_usernameController.text != authProvider.userModel?.username) {
        updates['username'] = _usernameController.text.trim();
      }

      if (_bioController.text != authProvider.userModel?.bio) {
        updates['bio'] = _bioController.text.trim();
      }

      if (newImageUrl != null) {
        updates['profileImageUrl'] = newImageUrl;
      }

      if (_selectedTeams.toString() !=
          authProvider.userModel?.favoriteTeams.toString()) {
        updates['favoriteTeams'] = _selectedTeams;
      }

      if (updates.isNotEmpty) {
        await _userService.updateUser(userId, updates);
      }

      // 3. AuthProvider 새로고침
      await authProvider.refreshUserModel();

      if (!mounted) return;

      // 4. 성공 메시지 및 이전 화면으로 이동
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필이 저장되었습니다'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프로필 저장 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 수정'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _hasChanges ? _saveProfile : null,
              child: const Text(
                '저장',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        onChanged: () {
          setState(() => _hasChanges = true);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            // 프로필 이미지
            _buildProfileImage(theme),
            const SizedBox(height: AppSizes.xxl),

            // 이름
            _buildUsernameField(),
            const SizedBox(height: AppSizes.lg),

            // 응원팀 선택
            _buildTeamSelector(theme),
            const SizedBox(height: AppSizes.lg),

            // 자기소개
            _buildBioField(),
            const SizedBox(height: AppSizes.xxl),

            // 저장 버튼 (하단)
            if (!_isLoading)
              ElevatedButton(
                onPressed: _hasChanges ? _saveProfile : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 프로필 이미지 위젯
  Widget _buildProfileImage(ThemeData theme) {
    return Center(
      child: Stack(
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 60,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (_currentImageUrl?.isNotEmpty == true
                    ? NetworkImage(_currentImageUrl!)
                    : null) as ImageProvider?,
            child: (_selectedImage == null && _currentImageUrl?.isEmpty != false)
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: theme.colorScheme.primary,
                  )
                : null,
          ),

          // 편집 버튼
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _pickImage,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.camera_alt,
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 이름 입력 필드
  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      decoration: const InputDecoration(
        labelText: '이름',
        hintText: '사용자 이름을 입력하세요',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '이름을 입력해주세요';
        }
        if (value.trim().length < 2) {
          return '이름은 2자 이상이어야 합니다';
        }
        if (value.trim().length > 20) {
          return '이름은 20자 이하여야 합니다';
        }
        return null;
      },
      maxLength: 20,
    );
  }

  /// 응원팀 선택 위젯
  Widget _buildTeamSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '응원팀 (최대 3개)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          '선택된 팀: ${_selectedTeams.length}/3',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BaseballData.teams.keys.map((team) {
            final isSelected = _selectedTeams.contains(team);
            return FilterChip(
              label: Text(team),
              selected: isSelected,
              onSelected: (_) => _toggleTeam(team),
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 자기소개 입력 필드
  Widget _buildBioField() {
    return TextFormField(
      controller: _bioController,
      decoration: const InputDecoration(
        labelText: '자기소개',
        hintText: '자신을 소개해주세요',
        prefixIcon: Icon(Icons.edit_note),
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      maxLength: 200,
      validator: (value) {
        if (value != null && value.trim().length > 200) {
          return '자기소개는 200자 이하여야 합니다';
        }
        return null;
      },
    );
  }
}
