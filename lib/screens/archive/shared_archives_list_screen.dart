/// 공유 아카이브 목록 화면
///
/// 사용자가 속한 모든 공유 아카이브를 보여주는 화면입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/sizes.dart';
import '../../providers/shared_archives_provider.dart';
import '../../providers/auth_provider.dart' as auth;

class SharedArchivesListScreen extends StatefulWidget {
  const SharedArchivesListScreen({super.key});

  @override
  State<SharedArchivesListScreen> createState() =>
      _SharedArchivesListScreenState();
}

class _SharedArchivesListScreenState extends State<SharedArchivesListScreen> {
  @override
  void initState() {
    super.initState();
    _initializeArchives();
  }

  /// 아카이브 목록 초기화
  void _initializeArchives() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Provider의 userId 설정 (실시간 스트림 구독 시작)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<SharedArchivesProvider>().setUserId(user.uid);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final archivesProvider = context.watch<SharedArchivesProvider>();
    final currentUser = context.watch<auth.AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('공유 아카이브'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await context.push('/create-shared-archive');
              // 아카이브 생성 후 자동으로 업데이트됨 (실시간 스트림)
            },
            tooltip: '새 아카이브 만들기',
          ),
        ],
      ),
      body: archivesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : archivesProvider.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          archivesProvider.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializeArchives,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : archivesProvider.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSizes.md),
                      itemCount: archivesProvider.archiveCount,
                      itemBuilder: (context, index) {
                        final archive = archivesProvider.archives[index];
                        final isCreator =
                            currentUser != null && archive.isCreator(currentUser.uid);

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSizes.md),
                          child: InkWell(
                            onTap: () {
                              context.push('/shared-archive/${archive.id}');
                            },
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 헤더: 이름 + 생성자 배지
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          archive.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (isCreator)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme.primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '생성자',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  // 설명
                                  if (archive.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      archive.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],

                                  const SizedBox(height: 12),

                                  // 통계 정보
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '멤버 ${archive.memberCount}명',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.photo_library,
                                        size: 16,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '게시물 ${archive.postCount}개',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('yyyy.MM.dd')
                                            .format(archive.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_shared_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              '아직 공유 아카이브가 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '친구들과 함께 경기 기록을 모아보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/create-shared-archive');
              },
              icon: const Icon(Icons.add),
              label: const Text('첫 아카이브 만들기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
