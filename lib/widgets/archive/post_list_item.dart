import 'package:flutter/material.dart';
import '../../core/constants/sizes.dart';

/// 리스트 뷰용 게시글 카드
class PostListItem extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostListItem({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () {
          // TODO: 게시글 상세 화면으로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${post['homeTeam']} vs ${post['awayTeam']}')),
          );
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 티켓 썸네일
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Center(
                  child: Icon(
                    Icons.confirmation_number,
                    size: 32,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),

              // 게시글 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 경기 타이틀
                    Text(
                      '${post['homeTeam']} vs ${post['awayTeam']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 날짜 및 장소
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post['date'],
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),

                    Row(
                      children: [
                        Icon(
                          Icons.stadium,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${post['stadium']} · ${post['seat']}',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 메모
                    if (post['memo'] != null)
                      Text(
                        post['memo'],
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),

                    // 별점
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < post['rating']
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
