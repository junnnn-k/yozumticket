/// 프리미엄 구독 화면
///
/// 구독 상품을 보여주고 결제를 처리하는 화면입니다.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/constants/sizes.dart';
import '../../core/constants/subscription_config.dart';
import '../../services/subscription_service.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart' as auth;

class PremiumSubscriptionScreen extends StatefulWidget {
  const PremiumSubscriptionScreen({super.key});

  @override
  State<PremiumSubscriptionScreen> createState() =>
      _PremiumSubscriptionScreenState();
}

class _PremiumSubscriptionScreenState extends State<PremiumSubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final UserService _userService = UserService();

  bool _isLoading = false;
  String? _errorMessage;
  int _selectedPlanIndex = 0; // 0: 월간, 1: 연간

  @override
  void initState() {
    super.initState();
    _initializeSubscription();
  }

  /// 구독 서비스 초기화
  Future<void> _initializeSubscription() async {
    setState(() => _isLoading = true);

    // 구매 완료 콜백 설정
    _subscriptionService.onPurchaseCompleted = _handlePurchaseCompleted;
    _subscriptionService.onPurchaseError = _handlePurchaseError;

    await _subscriptionService.initialize();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// 구매 완료 처리
  void _handlePurchaseCompleted(PurchaseDetails purchaseDetails) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 구독 타입 결정
      final String subscriptionType = purchaseDetails.productID ==
              SubscriptionConfig.premiumMonthlyId
          ? 'premium_monthly'
          : 'premium_yearly';

      // 구독 기간 설정
      final DateTime startDate = DateTime.now();
      final DateTime endDate = subscriptionType == 'premium_monthly'
          ? startDate.add(const Duration(days: 30))
          : startDate.add(const Duration(days: 365));

      // Firestore 업데이트
      await _userService.activatePremiumSubscription(
        uid: user.uid,
        subscriptionType: subscriptionType,
        startDate: startDate,
        endDate: endDate,
      );

      // 구매 이력 추가
      await _userService.addPurchaseHistory(user.uid, purchaseDetails.productID);

      // AuthProvider 새로고침
      if (mounted) {
        await context.read<auth.AuthProvider>().refreshUserModel();

        if (!mounted || !context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프리미엄 구독이 활성화되었습니다! 🎉'),
            backgroundColor: Colors.green,
          ),
        );

        // 이전 화면으로 돌아가기
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('구독 활성화 실패: $e')),
        );
      }
    }
  }

  /// 구매 에러 처리
  void _handlePurchaseError(String error) {
    if (mounted) {
      setState(() => _errorMessage = error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 구독 시작
  Future<void> _startSubscription() async {
    final productId = _selectedPlanIndex == 0
        ? SubscriptionConfig.premiumMonthlyId
        : SubscriptionConfig.premiumYearlyId;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await _subscriptionService.purchaseSubscription(productId);

    if (mounted) {
      setState(() => _isLoading = false);

      if (!success) {
        setState(() => _errorMessage = '구매를 시작할 수 없습니다');
      }
    }
  }

  /// 구매 복원
  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    await _subscriptionService.restorePurchases();

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매 내역을 확인했습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = context.watch<auth.AuthProvider>().userModel;

    // 이미 프리미엄 사용자인 경우
    if (currentUser?.isPremium == true) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('프리미엄 구독'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified,
                  size: 100,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  '프리미엄 구독 중',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${currentUser!.subscriptionType} 구독을 이용하고 계십니다',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                if (currentUser.subscriptionEndDate != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '만료일: ${_formatDate(currentUser.subscriptionEndDate!)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('프리미엄 구독'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _restorePurchases,
            child: const Text('구매 복원'),
          ),
        ],
      ),
      body: _isLoading && _subscriptionService.products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.lg),
              children: [
                // 헤더
                Center(
                  child: Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '프리미엄으로 업그레이드',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '광고 없이 모든 기능을 제한 없이 사용하세요',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // 혜택 목록
                Text(
                  '프리미엄 혜택',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                ...SubscriptionConfig.premiumBenefits.map((benefit) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            benefit,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 32),

                // 요금제 선택
                Text(
                  '요금제 선택',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildPlanCard(
                  context,
                  index: 0,
                  productId: SubscriptionConfig.premiumMonthlyId,
                  name: '월간 구독',
                  price: '₩6,900',
                  period: '월',
                  description: '언제든지 해지 가능',
                ),

                const SizedBox(height: 12),

                _buildPlanCard(
                  context,
                  index: 1,
                  productId: SubscriptionConfig.premiumYearlyId,
                  name: '연간 구독',
                  price: '₩62,000',
                  period: '연',
                  description: '25% 할인 (₩20,800 절약)',
                  badge: '추천',
                ),

                const SizedBox(height: 32),

                // 에러 메시지
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 구독 버튼
                ElevatedButton(
                  onPressed: _isLoading ? null : _startSubscription,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _selectedPlanIndex == 0
                              ? '월간 구독 시작하기'
                              : '연간 구독 시작하기',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // 안내 문구
                Text(
                  '구독은 자동으로 갱신됩니다. 언제든지 설정에서 취소할 수 있습니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }

  /// 요금제 카드
  Widget _buildPlanCard(
    BuildContext context, {
    required int index,
    required String productId,
    required String name,
    required String price,
    required String period,
    required String description,
    String? badge,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlanIndex = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 라디오 버튼
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 16),

            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // 가격
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? theme.colorScheme.primary : null,
                  ),
                ),
                Text(
                  '/$period',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _subscriptionService.onPurchaseCompleted = null;
    _subscriptionService.onPurchaseError = null;
    super.dispose();
  }
}
