import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/sizes.dart';

/// 설정 화면
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 알림 설정
  bool _pushNotificationEnabled = true;
  bool _newPostNotification = true;
  bool _friendRequestNotification = true;

  // 프라이버시 설정
  bool _showProfile = true;
  bool _allowFriendRequests = true;

  // 앱 정보
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  /// 앱 정보 로드
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      print('앱 정보 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 알림 설정 섹션
          _SectionHeader(title: '알림 설정'),
          SwitchListTile(
            title: const Text('푸시 알림'),
            subtitle: const Text('앱의 모든 알림을 받습니다'),
            value: _pushNotificationEnabled,
            onChanged: (value) {
              setState(() {
                _pushNotificationEnabled = value;
                if (!value) {
                  _newPostNotification = false;
                  _friendRequestNotification = false;
                }
              });
            },
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('새 게시글 알림'),
            subtitle: const Text('친구의 새 게시글 알림'),
            value: _newPostNotification,
            onChanged: _pushNotificationEnabled
                ? (value) {
                    setState(() => _newPostNotification = value);
                  }
                : null,
            secondary: const Icon(Icons.post_add),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('친구 요청 알림'),
            subtitle: const Text('새로운 친구 요청 알림'),
            value: _friendRequestNotification,
            onChanged: _pushNotificationEnabled
                ? (value) {
                    setState(() => _friendRequestNotification = value);
                  }
                : null,
            secondary: const Icon(Icons.person_add),
          ),

          const SizedBox(height: 24),

          // 프라이버시 설정 섹션
          _SectionHeader(title: '프라이버시'),
          SwitchListTile(
            title: const Text('프로필 공개'),
            subtitle: const Text('다른 사용자에게 프로필을 공개합니다'),
            value: _showProfile,
            onChanged: (value) {
              setState(() => _showProfile = value);
            },
            secondary: const Icon(Icons.visibility),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('친구 요청 허용'),
            subtitle: const Text('다른 사용자가 친구 요청을 보낼 수 있습니다'),
            value: _allowFriendRequests,
            onChanged: (value) {
              setState(() => _allowFriendRequests = value);
            },
            secondary: const Icon(Icons.group_add),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('차단 목록'),
            subtitle: const Text('차단한 사용자 관리'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('차단 목록 (추후 구현)')),
              );
            },
          ),

          const SizedBox(height: 24),

          // 앱 정보 섹션
          _SectionHeader(title: '앱 정보'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('버전 정보'),
            subtitle: Text(
              _appVersion.isNotEmpty
                  ? 'v$_appVersion (빌드 $_buildNumber)'
                  : '로딩 중...',
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('이용약관'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showInfoDialog(
                context,
                '이용약관',
                '요즘티켓 서비스 이용약관입니다.\n\n(내용은 추후 작성될 예정입니다)',
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('개인정보 처리방침'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showInfoDialog(
                context,
                '개인정보 처리방침',
                '요즘티켓의 개인정보 처리방침입니다.\n\n(내용은 추후 작성될 예정입니다)',
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('오픈소스 라이선스'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: '요즘티켓',
                applicationVersion:
                    _appVersion.isNotEmpty ? 'v$_appVersion' : '',
                applicationIcon: const FlutterLogo(size: 64),
              );
            },
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('문의하기'),
            subtitle: const Text('support@yozumticket.com'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('이메일 클라이언트를 열 수 없습니다')),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 정보 다이얼로그 표시
  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

/// 섹션 헤더
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
