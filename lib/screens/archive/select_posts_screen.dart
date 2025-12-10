/// 게시물 선택 화면
///
/// 공유 아카이브에 추가할 게시물을 선택하는 화면입니다.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/sizes.dart';
import '../../models/post_model.dart';
import '../../services/post_service.dart';
import '../../providers/shared_archives_provider.dart';

class SelectPostsScreen extends StatefulWidget {
  final String archiveId;

  const SelectPostsScreen({
    super.key,
    required this.archiveId,
  });

  @override
  State<SelectPostsScreen> createState() => _SelectPostsScreenState();
}

class _SelectPostsScreenState extends State<SelectPostsScreen> {
  final PostService _postService = PostService();
  List<Post> _myPosts = [];
  Set<String> _selectedPostIds = {};
  bool _isLoading = true;
  bool _isAddingPosts = false;

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  /// 내 게시물 로드
  Future<void> _loadMyPosts() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인이 필요합니다')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      final posts = await _postService.getMyPosts(user.uid);

      if (mounted) {
        setState(() {
          _myPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시물 로드 실패: $e')),
        );
      }
    }
  }

  /// 선택한 게시물 추가
  Future<void> _addSelectedPosts() async {
    if (_selectedPostIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시물을 선택해주세요')),
      );
      return;
    }

    setState(() => _isAddingPosts = true);

    try {
      final archivesProvider = context.read<SharedArchivesProvider>();

      // 선택한 모든 게시물 추가
      for (final postId in _selectedPostIds) {
        await archivesProvider.addPost(
          archiveId: widget.archiveId,
          postId: postId,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedPostIds.length}개의 게시물을 추가했습니다')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAddingPosts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시물 추가 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시물 선택'),
        centerTitle: true,
        actions: [
          if (_selectedPostIds.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_selectedPostIds.length}개 선택',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myPosts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '아직 게시물이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSizes.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _myPosts.length,
                  itemBuilder: (context, index) {
                    final post = _myPosts[index];
                    final isSelected = _selectedPostIds.contains(post.id);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedPostIds.remove(post.id);
                          } else {
                            _selectedPostIds.add(post.id);
                          }
                        });
                      },
                      child: Stack(
                        children: [
                          // 게시물 이미지
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                            child: CachedNetworkImage(
                              imageUrl: post.ticketImageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.confirmation_number,
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ),
                          ),

                          // 선택 표시
                          if (isSelected)
                            Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.7),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            ),

                          // 날짜 표시
                          Positioned(
                            bottom: 4,
                            left: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                post.gameInfo.date != null
                                    ? DateFormat('MM.dd')
                                        .format(post.gameInfo.date!)
                                    : '-',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: _selectedPostIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isAddingPosts ? null : _addSelectedPosts,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isAddingPosts
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '${_selectedPostIds.length}개 추가하기',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            )
          : null,
    );
  }
}
