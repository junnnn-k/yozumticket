import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/friendship_model.dart';
import '../../models/user_model.dart';
import '../../services/friend_service.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';

/// 친구 요청 목록 화면
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final FriendService _friendService = FriendService();
  final UserService _userService = UserService();

  List<Friendship> _receivedRequests = [];
  List<Friendship> _sentRequests = [];
  final Map<String, UserModel> _userCache = {};
  final Map<String, bool> _loadingStates = {};
  bool _isLoading = true;
  int _selectedTab = 0; // 0: 받은 요청, 1: 보낸 요청

  @override
  void initState() {
    super.initState();
    // initState에서는 context를 사용하지 않고, 다음 프레임에서 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  /// 친구 요청 목록 로드
  Future<void> _loadRequests() async {
    if (!mounted) return;
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 받은 요청과 보낸 요청 동시 로드
      final results = await Future.wait([
        _friendService.getPendingRequests(currentUser.uid),
        _friendService.getSentRequests(currentUser.uid),
      ]);

      _receivedRequests = results[0];
      _sentRequests = results[1];

      // 사용자 정보 캐시
      final allUserIds = <String>{
        ..._receivedRequests.map((f) => f.requesterId),
        ..._sentRequests.map((f) => f.receiverId),
      };

      for (final userId in allUserIds) {
        final user = await _userService.getUser(userId);
        if (user != null) {
          _userCache[userId] = user;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 친구 요청 수락
  Future<void> _acceptRequest(Friendship friendship) async {
    setState(() {
      _loadingStates[friendship.id] = true;
    });

    try {
      await _friendService.acceptFriendRequest(friendship.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 요청을 수락했습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        // 목록 새로고침
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loadingStates[friendship.id] = false;
      });
    }
  }

  /// 친구 요청 거절
  Future<void> _rejectRequest(Friendship friendship) async {
    setState(() {
      _loadingStates[friendship.id] = true;
    });

    try {
      await _friendService.rejectFriendRequest(friendship.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 요청을 거절했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        // 목록 새로고침
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loadingStates[friendship.id] = false;
      });
    }
  }

  /// 보낸 친구 요청 취소
  Future<void> _cancelRequest(Friendship friendship) async {
    setState(() {
      _loadingStates[friendship.id] = true;
    });

    try {
      await _friendService.removeFriend(friendship.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 요청을 취소했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        // 목록 새로고침
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loadingStates[friendship.id] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('친구 요청'),
          backgroundColor: theme.colorScheme.surface,
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                context.push('/friend-request-history');
              },
              tooltip: '요청 이력',
            ),
          ],
          bottom: TabBar(
          onTap: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('받은 요청'),
                  if (_receivedRequests.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_receivedRequests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('보낸 요청'),
                  if (_sentRequests.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_sentRequests.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadRequests,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    // 받은 요청 탭
                    _buildReceivedRequests(),
                    // 보낸 요청 탭
                    _buildSentRequests(),
                  ],
                ),
        ),
      ),
    );
  }

  /// 받은 요청 목록
  Widget _buildReceivedRequests() {
    if (_receivedRequests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '받은 친구 요청이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _receivedRequests.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final friendship = _receivedRequests[index];
        final user = _userCache[friendship.requesterId];

        if (user == null) {
          return const SizedBox.shrink();
        }

        return _ReceivedRequestCard(
          user: user,
          friendship: friendship,
          isLoading: _loadingStates[friendship.id] ?? false,
          onAccept: () => _acceptRequest(friendship),
          onReject: () => _rejectRequest(friendship),
        );
      },
    );
  }

  /// 보낸 요청 목록
  Widget _buildSentRequests() {
    if (_sentRequests.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '보낸 친구 요청이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _sentRequests.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final friendship = _sentRequests[index];
        final user = _userCache[friendship.receiverId];

        if (user == null) {
          return const SizedBox.shrink();
        }

        return _SentRequestCard(
          user: user,
          friendship: friendship,
          isLoading: _loadingStates[friendship.id] ?? false,
          onCancel: () => _cancelRequest(friendship),
        );
      },
    );
  }
}

/// 받은 친구 요청 카드
class _ReceivedRequestCard extends StatelessWidget {
  final UserModel user;
  final Friendship friendship;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ReceivedRequestCard({
    required this.user,
    required this.friendship,
    required this.isLoading,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 프로필 이미지
                CircleAvatar(
                  radius: 30,
                  backgroundImage: user.profileImageUrl.isNotEmpty
                      ? NetworkImage(user.profileImageUrl)
                      : null,
                  child: user.profileImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),

                // 사용자 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.favoriteTeams.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.favoriteTeams.join(', '),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            if (user.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                user.bio,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 16),

            // 수락/거절 버튼
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('거절'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : onAccept,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('수락'),
                  ),
                ),
              ],
            ),

            // 요청 시간
            const SizedBox(height: 8),
            Text(
              _formatTimestamp(friendship.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 보낸 친구 요청 카드
class _SentRequestCard extends StatelessWidget {
  final UserModel user;
  final Friendship friendship;
  final bool isLoading;
  final VoidCallback onCancel;

  const _SentRequestCard({
    required this.user,
    required this.friendship,
    required this.isLoading,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 30,
              backgroundImage: user.profileImageUrl.isNotEmpty
                  ? NetworkImage(user.profileImageUrl)
                  : null,
              child: user.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(width: 16),

            // 사용자 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(friendship.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 취소 버튼
            OutlinedButton(
              onPressed: isLoading ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('취소'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 시간 포맷팅
String _formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inMinutes < 1) {
    return '방금 전';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes}분 전';
  } else if (difference.inDays < 1) {
    return '${difference.inHours}시간 전';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}일 전';
  } else {
    return '${timestamp.year}.${timestamp.month}.${timestamp.day}';
  }
}
