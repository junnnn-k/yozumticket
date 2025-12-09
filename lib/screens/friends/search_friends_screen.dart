import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/friendship_model.dart';
import '../../services/user_service.dart';
import '../../services/friend_service.dart';
import '../../providers/auth_provider.dart';

/// 친구 검색 화면
class SearchFriendsScreen extends StatefulWidget {
  const SearchFriendsScreen({super.key});

  @override
  State<SearchFriendsScreen> createState() => _SearchFriendsScreenState();
}

class _SearchFriendsScreenState extends State<SearchFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final UserService _userService = UserService();
  final FriendService _friendService = FriendService();

  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String _errorMessage = '';

  // 각 사용자별 친구 관계 상태 캐시
  final Map<String, Friendship?> _friendshipCache = {};
  final Map<String, bool> _loadingStates = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 사용자 검색
  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
      _friendshipCache.clear();
    });

    try {
      final results = await _userService.searchUsersByName(query);
      final currentUser = context.read<AuthProvider>().userModel;

      // 자기 자신은 검색 결과에서 제외
      final filteredResults = results
          .where((user) => user.uid != currentUser?.uid)
          .toList();

      // 각 검색 결과에 대한 친구 관계 확인
      for (final user in filteredResults) {
        final friendship = await _friendService.checkFriendship(
          currentUser!.uid,
          user.uid,
        );
        _friendshipCache[user.uid] = friendship;
      }

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });

      if (filteredResults.isEmpty) {
        setState(() {
          _errorMessage = '검색 결과가 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = '검색 중 오류가 발생했습니다: $e';
      });
    }
  }

  /// 친구 요청 보내기
  Future<void> _sendFriendRequest(UserModel targetUser) async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    setState(() {
      _loadingStates[targetUser.uid] = true;
    });

    try {
      await _friendService.sendFriendRequest(
        currentUser.uid,
        targetUser.uid,
      );

      // 캐시 업데이트
      final friendship = await _friendService.checkFriendship(
        currentUser.uid,
        targetUser.uid,
      );
      setState(() {
        _friendshipCache[targetUser.uid] = friendship;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${targetUser.username}님에게 친구 요청을 보냈습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loadingStates[targetUser.uid] = false;
      });
    }
  }

  /// 친구 요청 취소
  Future<void> _cancelFriendRequest(UserModel targetUser) async {
    final friendship = _friendshipCache[targetUser.uid];
    if (friendship == null) return;

    setState(() {
      _loadingStates[targetUser.uid] = true;
    });

    try {
      await _friendService.removeFriend(friendship.id);

      // 캐시 업데이트
      setState(() {
        _friendshipCache[targetUser.uid] = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 요청을 취소했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
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
        _loadingStates[targetUser.uid] = false;
      });
    }
  }

  /// 친구 요청 수락
  Future<void> _acceptFriendRequest(UserModel targetUser) async {
    final friendship = _friendshipCache[targetUser.uid];
    if (friendship == null) return;

    setState(() {
      _loadingStates[targetUser.uid] = true;
    });

    try {
      await _friendService.acceptFriendRequest(friendship.id);

      // 캐시 업데이트
      final currentUser = context.read<AuthProvider>().userModel;
      if (currentUser != null) {
        final updatedFriendship = await _friendService.checkFriendship(
          currentUser.uid,
          targetUser.uid,
        );
        setState(() {
          _friendshipCache[targetUser.uid] = updatedFriendship;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${targetUser.username}님과 친구가 되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
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
        _loadingStates[targetUser.uid] = false;
      });
    }
  }

  /// 친구 요청 거절
  Future<void> _rejectFriendRequest(UserModel targetUser) async {
    final friendship = _friendshipCache[targetUser.uid];
    if (friendship == null) return;

    setState(() {
      _loadingStates[targetUser.uid] = true;
    });

    try {
      await _friendService.rejectFriendRequest(friendship.id);

      // 캐시 업데이트
      setState(() {
        _friendshipCache[targetUser.uid] = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 요청을 거절했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
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
        _loadingStates[targetUser.uid] = false;
      });
    }
  }

  /// 친구 삭제
  Future<void> _removeFriend(UserModel targetUser) async {
    final friendship = _friendshipCache[targetUser.uid];
    if (friendship == null) return;

    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('${targetUser.username}님을 친구 목록에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loadingStates[targetUser.uid] = true;
    });

    try {
      await _friendService.removeFriend(friendship.id);

      // 캐시 업데이트
      setState(() {
        _friendshipCache[targetUser.uid] = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구를 삭제했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
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
        _loadingStates[targetUser.uid] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 검색'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '사용자 이름으로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _errorMessage = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {}); // suffixIcon 표시를 위해
              },
              onSubmitted: (value) => _searchUsers(),
            ),
          ),

          // 검색 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSearching ? null : _searchUsers,
                icon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isSearching ? '검색 중...' : '검색'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 검색 결과
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  /// 검색 결과 위젯
  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '사용자 이름으로 친구를 검색하세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final currentUser = context.read<AuthProvider>().userModel;
        return _UserCard(
          user: user,
          currentUserId: currentUser?.uid ?? '',
          friendship: _friendshipCache[user.uid],
          isLoading: _loadingStates[user.uid] ?? false,
          onSendRequest: () => _sendFriendRequest(user),
          onAcceptRequest: () => _acceptFriendRequest(user),
          onRejectRequest: () => _rejectFriendRequest(user),
          onCancelRequest: () => _cancelFriendRequest(user),
          onRemoveFriend: () => _removeFriend(user),
        );
      },
    );
  }
}

/// 사용자 카드 위젯
class _UserCard extends StatelessWidget {
  final UserModel user;
  final String currentUserId;
  final Friendship? friendship;
  final bool isLoading;
  final VoidCallback onSendRequest;
  final VoidCallback onAcceptRequest;
  final VoidCallback onRejectRequest;
  final VoidCallback onCancelRequest;
  final VoidCallback onRemoveFriend;

  const _UserCard({
    required this.user,
    required this.currentUserId,
    required this.friendship,
    required this.isLoading,
    required this.onSendRequest,
    required this.onAcceptRequest,
    required this.onRejectRequest,
    required this.onCancelRequest,
    required this.onRemoveFriend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 친구 추가/상태 버튼
            _buildActionButton(theme),
          ],
        ),
      ),
    );
  }

  /// 액션 버튼 (친구 상태에 따라 다름)
  Widget _buildActionButton(ThemeData theme) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // 친구 관계가 없는 경우
    if (friendship == null) {
      return ElevatedButton(
        onPressed: onSendRequest,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('친구 추가'),
      );
    }

    // 친구 요청 대기 중
    if (friendship!.status == FriendshipStatus.pending) {
      // 내가 요청을 받은 경우 (상대방이 요청자)
      if (friendship!.receiverId == currentUserId) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: onRejectRequest,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                foregroundColor: Colors.red,
              ),
              child: const Text('거절'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAcceptRequest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('수락'),
            ),
          ],
        );
      }
      // 내가 요청을 보낸 경우
      else {
        return OutlinedButton(
          onPressed: onCancelRequest,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('요청 취소'),
        );
      }
    }

    // 이미 친구인 경우
    if (friendship!.status == FriendshipStatus.accepted) {
      return OutlinedButton(
        onPressed: onRemoveFriend,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          foregroundColor: Colors.grey,
        ),
        child: const Text('친구'),
      );
    }

    // 차단된 경우
    if (friendship!.status == FriendshipStatus.blocked) {
      return const Chip(
        label: Text('차단됨', style: TextStyle(fontSize: 12)),
        backgroundColor: Colors.red,
        labelStyle: TextStyle(color: Colors.white),
      );
    }

    return const SizedBox.shrink();
  }
}
