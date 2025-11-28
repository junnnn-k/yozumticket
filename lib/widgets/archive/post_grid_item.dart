import 'package:flutter/material.dart';
import '../../core/constants/sizes.dart';

/// 그리드 뷰용 게시글 카드
class PostGridItem extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostGridItem({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: 게시글 상세 화면으로 이동
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${post['homeTeam']} vs ${post['awayTeam']}')),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 티켓 이미지 (플레이스홀더)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Icon(
                    Icons.confirmation_number,
                    size: 48,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ),

            // 게시글 정보
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 경기 타이틀
                    Text(
                      '${post['homeTeam']} vs ${post['awayTeam']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 날짜
                    Text(
                      post['date'],
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),

                    // 별점
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < post['rating']
                              ? Icons.star
                              : Icons.star_border,
                          size: 12,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
