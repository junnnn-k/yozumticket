/// 공유 아카이브 생성 화면
///
/// 친구들과 함께 보는 공동 앨범을 만드는 화면입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/sizes.dart';
import '../../models/user_model.dart';
import '../../services/friend_service.dart';
import '../../providers/shared_archives_provider.dart';

class CreateSharedArchiveScreen extends StatefulWidget {
  const CreateSharedArchiveScreen({super.key});

  @override
  State<CreateSharedArchiveScreen> createState() =>
      _CreateSharedArchiveScreenState();
}

class _CreateSharedArchiveScreenState extends State<CreateSharedArchiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FriendService _friendService = FriendService();

  List<UserModel> _friends = [];
  Set<String> _selectedFriends = {};
  bool _isLoading = false;
  bool _isLoadingFriends = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  /// 친구 목록 로드
  Future<void> _loadFriends() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final friends = await _friendService.getFriends(user.uid);
      setState(() {
        _friends = friends;
        _isLoadingFriends = false;
      });
    } catch (e) {
      setState(() => _isLoadingFriends = false);
    }
  }

  /// 아카이브 생성
  Future<void> _createArchive() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final archivesProvider = context.read<SharedArchivesProvider>();

      final archiveId = await archivesProvider.createArchive(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        createdBy: user.uid,
        members: _selectedFriends.toList(),
      );

      if (!mounted) return;

      if (archiveId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유 아카이브가 생성되었습니다')),
        );
        Navigator.of(context).pop(archiveId);
      } else {
        throw Exception('Failed to create archive');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('아카이브 생성에 실패했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('공유 아카이브 만들기'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.lg),
          children: [
            // 설명 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        '친구들과 함께 경기 기록을 모아보세요!',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // 아카이브 이름
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '아카이브 이름',
                hintText: '예: 2025 우리의 야구 여정',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder_special),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '아카이브 이름을 입력해주세요';
                }
                return null;
              },
              maxLength: 30,
            ),

            const SizedBox(height: AppSizes.md),

            // 설명 (선택)
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명 (선택)',
                hintText: '이 아카이브에 대한 설명을 입력하세요',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              maxLength: 200,
            ),

            const SizedBox(height: AppSizes.lg),

            // 친구 초대 섹션
            Text(
              '친구 초대',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              '함께 기록을 공유할 친구를 선택하세요',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: AppSizes.md),

            // 친구 목록
            if (_isLoadingFriends)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_friends.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '친구가 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '먼저 친구를 추가해주세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._friends.map((friend) {
                final isSelected = _selectedFriends.contains(friend.uid);

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedFriends.add(friend.uid);
                        } else {
                          _selectedFriends.remove(friend.uid);
                        }
                      });
                    },
                    title: Text(friend.username),
                    subtitle: friend.favoriteTeams.isNotEmpty
                        ? Text('응원팀: ${friend.favoriteTeams.join(', ')}')
                        : null,
                    secondary: CircleAvatar(
                      backgroundImage: friend.profileImageUrl != null
                          ? NetworkImage(friend.profileImageUrl!)
                          : null,
                      child: friend.profileImageUrl == null
                          ? Text(friend.username[0].toUpperCase())
                          : null,
                    ),
                  ),
                );
              }),

            const SizedBox(height: AppSizes.lg),

            // 선택된 친구 수
            if (_selectedFriends.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: Text(
                  '${_selectedFriends.length}명의 친구를 초대합니다',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // 생성 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _createArchive,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '아카이브 만들기',
                      style: TextStyle(fontSize: 16),
                    ),
            ),

            const SizedBox(height: AppSizes.md),

            // 취소 버튼
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
  }
}
