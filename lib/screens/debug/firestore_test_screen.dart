import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/post_model.dart';
import '../../models/game_info.dart';
import '../../services/post_service.dart';

/// Firestore 테스트 화면 (디버그용)
class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _isLoading = false;
  String _result = '';

  /// 테스트 게시글 생성
  Future<void> _createTestPost() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      final testPost = Post(
        id: '', // PostService에서 자동 생성
        userId: 'test_user_123', // TODO: 실제 인증된 사용자 ID 사용
        ticketImageUrl: 'https://example.com/ticket.jpg',
        additionalPhotoUrls: [
          'https://example.com/photo1.jpg',
          'https://example.com/photo2.jpg',
        ],
        gameInfo: GameInfo(
          date: DateTime(2025, 12, 1, 18, 30),
          homeTeam: '두산',
          awayTeam: 'LG',
          stadium: '잠실야구장',
          seat: '1루 블루존 203-5',
          price: 15000,
          confidence: 1.0,
        ),
        title: '잠실에서 본 두산 vs LG 경기!',
        content: '오늘 경기 정말 재밌었어요. 홈런이 3개나 나왔습니다!',
        tags: ['#승리', '#홈런', '#잠실'],
        rating: 4.5,
        privacy: Privacy.publicPost,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final postId = await _postService.createPost(testPost);

      setState(() {
        _result = '✅ 게시글 생성 성공!\nPost ID: $postId';
      });

      // 생성 후 목록 새로고침
      _loadPosts();
    } catch (e) {
      setState(() {
        _result = '❌ 게시글 생성 실패: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 게시글 목록 조회
  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      // PostService 사용 (인덱스 필요)
      final posts = await _postService.getMyPosts('test_user_123');

      setState(() {
        _posts = posts;
        _result = '✅ 게시글 ${posts.length}개 조회 성공! (PostService 사용)';
      });
    } catch (e) {
      setState(() {
        _result = '❌ 게시글 조회 실패: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 게시글 삭제
  Future<void> _deletePost(String postId) async {
    setState(() => _isLoading = true);

    try {
      await _postService.deletePost(postId);

      setState(() {
        _result = '✅ 게시글 삭제 성공! (ID: $postId)';
      });

      // 삭제 후 목록 새로고침
      _loadPosts();
    } catch (e) {
      setState(() {
        _result = '❌ 게시글 삭제 실패: $e';
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
        title: const Text('Firestore 테스트'),
        backgroundColor: colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 테스트 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createTestPost,
                    icon: const Icon(Icons.add),
                    label: const Text('게시글 생성'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loadPosts,
                    icon: const Icon(Icons.refresh),
                    label: const Text('목록 조회'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 결과 메시지
            if (_result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _result.startsWith('✅')
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _result.startsWith('✅')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _result,
                  style: TextStyle(
                    color: _result.startsWith('✅')
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 로딩 인디케이터
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            // 게시글 목록
            if (!_isLoading)
              Expanded(
                child: _posts.isEmpty
                    ? Center(
                        child: Text(
                          '게시글이 없습니다.\n"게시글 생성" 버튼을 눌러보세요.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(post.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${post.gameInfo.homeTeam} vs ${post.gameInfo.awayTeam}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  Text(
                                    '${post.gameInfo.stadium} • ${post.gameInfo.date?.toString().split(' ')[0]}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.star,
                                          size: 16, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text('${post.rating}',
                                          style: const TextStyle(fontSize: 12)),
                                      const SizedBox(width: 12),
                                      Icon(Icons.lock,
                                          size: 14,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5)),
                                      const SizedBox(width: 4),
                                      Text(
                                        Privacy.labels[post.privacy] ?? '',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePost(post.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
