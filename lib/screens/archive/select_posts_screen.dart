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
  Set<String> _selectedPostIds = {}; // 새로 추가할 게시물
  Set<String> _existingPostIds = {}; // 이미 아카이브에 있는 게시물
  Set<String> _postsToRemove = {}; // 제거할 게시물
  bool _isLoading = true;
  bool _isAddingPosts = false;

  @override
  void initState() {
    super.initState();
    _loadExistingPosts();
    _loadMyPosts();
  }

  /// 아카이브의 기존 게시물 로드
  void _loadExistingPosts() {
    final archivesProvider = context.read<SharedArchivesProvider>();
    final archive = archivesProvider.getArchiveById(widget.archiveId);

    if (archive != null) {
      setState(() {
        _existingPostIds = Set<String>.from(archive.posts);
      });
    }
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

  /// 선택한 게시물 추가 및 제거
  Future<void> _addSelectedPosts() async {
    if (_selectedPostIds.isEmpty && _postsToRemove.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('변경사항이 없습니다')),
      );
      return;
    }

    setState(() => _isAddingPosts = true);

    try {
      final archivesProvider = context.read<SharedArchivesProvider>();

      // 1. 제거할 게시물 처리
      for (final postId in _postsToRemove) {
        await archivesProvider.removePost(
          archiveId: widget.archiveId,
          postId: postId,
        );
      }

      // 2. 새로 추가할 게시물 처리
      for (final postId in _selectedPostIds) {
        await archivesProvider.addPost(
          archiveId: widget.archiveId,
          postId: postId,
        );
      }

      if (!mounted) return;

      // 성공 메시지
      final addedCount = _selectedPostIds.length;
      final removedCount = _postsToRemove.length;

      String message;
      if (addedCount > 0 && removedCount > 0) {
        message = '$addedCount개 추가, $removedCount개 제거했습니다';
      } else if (addedCount > 0) {
        message = '$addedCount개의 게시물을 추가했습니다';
      } else {
        message = '$removedCount개의 게시물을 제거했습니다';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAddingPosts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('작업 실패: $e')),
      );
    }
  }

  /// 버튼 텍스트 생성
  String _getButtonText() {
    final addedCount = _selectedPostIds.length;
    final removedCount = _postsToRemove.length;

    if (addedCount > 0 && removedCount > 0) {
      return '$addedCount개 추가, $removedCount개 제거';
    } else if (addedCount > 0) {
      return '$addedCount개 추가하기';
    } else {
      return '$removedCount개 제거하기';
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
          if (_selectedPostIds.isNotEmpty || _postsToRemove.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  _selectedPostIds.isNotEmpty && _postsToRemove.isNotEmpty
                      ? '+${_selectedPostIds.length} -${_postsToRemove.length}'
                      : _selectedPostIds.isNotEmpty
                          ? '+${_selectedPostIds.length}'
                          : '-${_postsToRemove.length}',
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
                    final isExisting = _existingPostIds.contains(post.id);
                    final isSelected = _selectedPostIds.contains(post.id);
                    final isToRemove = _postsToRemove.contains(post.id);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isExisting) {
                            // 이미 추가된 게시물: 제거 토글
                            if (isToRemove) {
                              _postsToRemove.remove(post.id);
                            } else {
                              _postsToRemove.add(post.id);
                            }
                          } else {
                            // 새 게시물: 추가 토글
                            if (isSelected) {
                              _selectedPostIds.remove(post.id);
                            } else {
                              _selectedPostIds.add(post.id);
                            }
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

                          // 선택 상태 표시
                          if (isToRemove)
                            // 제거할 게시물 (빨간색 오버레이)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.7),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.remove_circle,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            )
                          else if (isSelected)
                            // 새로 추가할 게시물 (초록색 체크)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.7),
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              ),
                            )
                          else if (isExisting)
                            // 이미 추가된 게시물 (파란색 배지)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '추가됨',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
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
      bottomNavigationBar:
          (_selectedPostIds.isNotEmpty || _postsToRemove.isNotEmpty)
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
                              _getButtonText(),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                )
              : null,
    );
  }
}
