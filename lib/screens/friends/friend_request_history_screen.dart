import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/friendship_model.dart';
import '../../models/user_model.dart';
import '../../services/friend_service.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart';

/// 친구 요청 이력 화면
class FriendRequestHistoryScreen extends StatefulWidget {
  const FriendRequestHistoryScreen({super.key});

  @override
  State<FriendRequestHistoryScreen> createState() =>
      _FriendRequestHistoryScreenState();
}

class _FriendRequestHistoryScreenState
    extends State<FriendRequestHistoryScreen> {
  final FriendService _friendService = FriendService();
  final UserService _userService = UserService();

  List<Friendship> _requestHistory = [];
  Map<String, UserModel> _usersCache = {}; // 사용자 정보 캐시
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// 이력 로드
  Future<void> _loadHistory() async {
    final currentUser = context.read<AuthProvider>().userModel;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final history = await _friendService.getRequestHistory(currentUser.uid);

      // 관련된 사용자 정보 로드 (receiverId)
      final userIds = history.map((h) => h.receiverId).toSet();
      final usersCache = <String, UserModel>{};

      for (final userId in userIds) {
        try {
          final user = await _userService.getUser(userId);
          if (user != null) {
            usersCache[userId] = user;
          }
        } catch (e) {
          debugPrint('사용자 정보 로드 실패 ($userId): $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _requestHistory = history;
        _usersCache = usersCache;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 친구 요청 취소
  Future<void> _cancelRequest(Friendship friendship) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('친구 요청 취소'),
        content: const Text('친구 요청을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('취소', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _friendService.removeFriend(friendship.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('친구 요청을 취소했습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadHistory();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('친구 요청 이력'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requestHistory.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requestHistory.length,
                    itemBuilder: (context, index) {
                      final friendship = _requestHistory[index];
                      final user = _usersCache[friendship.receiverId];

                      return _RequestHistoryCard(
                        friendship: friendship,
                        user: user,
                        onCancel: friendship.isPending
                            ? () => _cancelRequest(friendship)
                            : null,
                      );
                    },
                  ),
                ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '친구 요청 이력이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '최근 2주 이내의 요청만 표시됩니다\n(대기 중인 요청은 기간 제한 없음)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 요청 이력 카드 위젯
class _RequestHistoryCard extends StatelessWidget {
  final Friendship friendship;
  final UserModel? user;
  final VoidCallback? onCancel;

  const _RequestHistoryCard({
    required this.friendship,
    required this.user,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    // 상태에 따른 스타일
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (friendship.status) {
      case FriendshipStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = '대기 중';
        break;
      case FriendshipStatus.accepted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = '수락됨';
        break;
      case FriendshipStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = '거절됨';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = '알 수 없음';
    }

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
                  radius: 25,
                  backgroundImage: user?.profileImageUrl.isNotEmpty == true
                      ? CachedNetworkImageProvider(user!.profileImageUrl)
                      : null,
                  child: user?.profileImageUrl.isEmpty ?? true
                      ? const Icon(Icons.person, size: 25)
                      : null,
                ),
                const SizedBox(width: 12),

                // 사용자 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? '알 수 없음',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user?.favoriteTeams.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          user!.favoriteTeams.join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 상태 배지
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 날짜 정보
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '요청: ${dateFormat.format(friendship.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            // 수정일 (수락/거절된 경우)
            if (friendship.updatedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.update, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '응답: ${dateFormat.format(friendship.updatedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],

            // 취소 버튼 (대기 중인 경우만)
            if (onCancel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('요청 취소'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
