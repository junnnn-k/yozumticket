import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/sizes.dart';

/// Splash 화면
/// - 앱 로고 표시
/// - Firebase 초기화 대기
/// - 로그인 상태 확인 후 자동 이동
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthAndNavigate();
  }

  /// 애니메이션 초기화
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  /// 인증 상태 확인 및 페이지 이동
  Future<void> _checkAuthAndNavigate() async {
    // 최소 2초 대기 (Splash 화면 표시 시간)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Firebase Auth 상태 확인
    User? user = FirebaseAuth.instance.currentUser;

    // 로그인되지 않은 경우 자동으로 익명 로그인
    if (user == null) {
      try {
        debugPrint('🔐 익명 로그인 시도 중...');
        final credential = await FirebaseAuth.instance.signInAnonymously();
        user = credential.user;
        debugPrint('✅ 익명 로그인 성공: ${user?.uid}');
      } catch (e) {
        debugPrint('❌ 익명 로그인 실패: $e');
        // Firebase Console에서 Anonymous Auth를 활성화해야 합니다
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('로그인 실패: Firebase Console에서 Anonymous 인증을 활성화해주세요'),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    if (!mounted) return;

    // 메인 화면으로 이동
    context.go('/main');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 앱 로고 (아이콘)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sports_baseball,
                        size: 64,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),

                    // 앱 타이틀
                    Text(
                      '요즘티켓',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),

                    // 서브타이틀
                    Text(
                      'Baseball Memory Archive',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),

                    // 로딩 인디케이터
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
