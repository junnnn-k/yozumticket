import 'package:go_router/go_router.dart';

/// 알림 클릭 시 네비게이션 헬퍼
///
/// FCM 및 로컬 알림에서 사용자를 적절한 화면으로 이동시킵니다.
class NotificationNavigationHelper {
  /// 알림 데이터에 따라 적절한 화면으로 이동
  ///
  /// [context] - GoRouter를 가져올 수 있는 BuildContext
  /// [data] - 알림 데이터 (type, postId, archiveId 등)
  static void navigate(GoRouter router, Map<String, dynamic> data) {
    final type = data['type'];
    print('[NotificationNavigation] Type: $type, Data: $data');

    switch (type) {
      case 'friend_request':
        // 친구 요청 화면으로 이동
        router.push('/friend-requests');
        break;

      case 'friend_accepted':
        // 친구 목록 화면으로 이동 (메인 화면의 Friends 탭)
        router.go('/main');
        break;

      case 'new_post':
        // 게시글 상세 화면으로 이동
        final postId = data['postId'];
        if (postId != null) {
          router.push('/post-detail/$postId');
        } else {
          router.go('/main');
        }
        break;

      case 'archive_invite':
        // 공유 아카이브 상세 화면으로 이동
        final archiveId = data['archiveId'];
        if (archiveId != null) {
          router.push('/shared-archive/$archiveId');
        } else {
          router.go('/main');
        }
        break;

      default:
        // 알 수 없는 타입이면 메인 화면으로
        print('[NotificationNavigation] Unknown type: $type');
        router.go('/main');
    }
  }

  /// 문자열 데이터를 Map으로 변환
  ///
  /// LocalNotificationService에서 전달한 payload 문자열을 파싱
  static Map<String, dynamic> parsePayload(String payload) {
    final result = <String, dynamic>{};
    final entries = payload.split('|');

    for (final entry in entries) {
      final parts = entry.split('=');
      if (parts.length == 2) {
        result[parts[0]] = parts[1];
      }
    }

    return result;
  }
}
