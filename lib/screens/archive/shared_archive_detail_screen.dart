/// 공유 아카이브 상세 화면
///
/// 공유 아카이브의 멤버와 게시물을 보여주는 화면입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/sizes.dart';
import '../../models/shared_archive_model.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../services/shared_archive_service.dart';
import '../../services/user_service.dart';
import '../../services/post_service.dart';
import '../../providers/shared_archives_provider.dart';

class SharedArchiveDetailScreen extends StatefulWidget {
  final String archiveId;

  const SharedArchiveDetailScreen({
    super.key,
    required this.archiveId,
  });

  @override
  State<SharedArchiveDetailScreen> createState() =>
      _SharedArchiveDetailScreenState();
}

class _SharedArchiveDetailScreenState extends State<SharedArchiveDetailScreen> {
  final SharedArchiveService _archiveService = SharedArchiveService();
  final UserService _userService = UserService();
  final PostService _postService = PostService();

  SharedArchive? _archive;
  List<UserModel> _members = [];
  List<Post> _posts = [];
  bool _isLoading = true;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _loadArchiveData();
  }

  /// 아카이브 데이터 로드
  Future<void> _loadArchiveData() async {
    setState(() => _isLoading = true);

    try {
      final archive = await _archiveService.getArchive(widget.archiveId);
      if (archive == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('아카이브를 찾을 수 없습니다')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // 멤버 정보 로드
      final members = <UserModel>[];
      for (final memberId in archive.members) {
        final user = await _userService.getUser(memberId);
        if (user != null) {
          members.add(user);
        }
      }

      // 게시물 로드
      final posts = <Post>[];
      for (final postId in archive.posts) {
        final post = await _postService.getPost(postId);
        if (post != null) {
          posts.add(post);
        }
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final isCreator = currentUser != null && archive.isCreator(currentUser.uid);

      if (mounted) {
        setState(() {
          _archive = archive;
          _members = members;
          _posts = posts;
          _isCreator = isCreator;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로드 실패: $e')),
        );
      }
    }
  }

  /// 아카이브 나가기
  Future<void> _leaveArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아카이브 나가기'),
        content: const Text('정말 이 아카이브를 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final archivesProvider = context.read<SharedArchivesProvider>();
      final success = await archivesProvider.leaveArchive(
        archiveId: widget.archiveId,
        userId: user.uid,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아카이브를 나갔습니다')),
        );
        Navigator.of(context).pop();
      } else {
        final error = archivesProvider.errorMessage ?? '알 수 없는 오류';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }

  /// 아카이브 삭제
  Future<void> _deleteArchive() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아카이브 삭제'),
        content: const Text('정말 이 아카이브를 삭제하시겠습니까?\n모든 데이터가 영구적으로 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final archivesProvider = context.read<SharedArchivesProvider>();
      final success = await archivesProvider.deleteArchive(widget.archiveId);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('아카이브가 삭제되었습니다')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('공유 아카이브')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_archive == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('공유 아카이브')),
        body: const Center(child: Text('아카이브를 찾을 수 없습니다')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_archive!.name),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'leave') {
                _leaveArchive();
              } else if (value == 'delete') {
                _deleteArchive();
              }
            },
            itemBuilder: (context) => [
              if (!_isCreator)
                const PopupMenuItem(
                  value: 'leave',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, size: 20),
                      SizedBox(width: 8),
                      Text('아카이브 나가기'),
                    ],
                  ),
                ),
              if (_isCreator)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('아카이브 삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadArchiveData,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            // 아카이브 정보 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_archive!.description.isNotEmpty) ...[
                      Text(
                        _archive!.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSizes.md),
                    ],
                    Row(
                      children: [
                        Icon(Icons.people, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('멤버 ${_members.length}명'),
                        const SizedBox(width: 16),
                        Icon(Icons.photo_library, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text('게시물 ${_posts.length}개'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // 멤버 섹션
            Text(
              '멤버',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            if (_members.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('멤버가 없습니다')),
                ),
              )
            else
              ..._members.map((member) {
                final isCreator = _archive!.isCreator(member.uid);

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.profileImageUrl != null
                          ? NetworkImage(member.profileImageUrl!)
                          : null,
                      child: member.profileImageUrl == null
                          ? Text(member.username[0].toUpperCase())
                          : null,
                    ),
                    title: Row(
                      children: [
                        Text(member.username),
                        if (isCreator) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '생성자',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: member.favoriteTeams.isNotEmpty
                        ? Text('응원팀: ${member.favoriteTeams.join(', ')}')
                        : null,
                  ),
                );
              }),

            const SizedBox(height: AppSizes.lg),

            // 게시물 섹션
            Text(
              '게시물',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            if (_posts.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '아직 게시물이 없습니다',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '첫 기록을 추가해보세요!',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return GestureDetector(
                    onTap: () => context.push('/post-detail/${post.id}'),
                    child: Image.network(
                      post.ticketImageUrl,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push(
            '/select-posts/${widget.archiveId}',
          );
          // 게시물 추가 후 새로고침
          if (result == true) {
            _loadArchiveData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('게시물 추가'),
      ),
    );
  }
}
