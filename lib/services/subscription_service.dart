/// 구독 및 인앱 결제 서비스
///
/// in_app_purchase 패키지를 사용하여 구독 및 결제를 처리합니다.

import 'dart:async';
import 'dart:developer' as dev;
import 'package:in_app_purchase/in_app_purchase.dart';
import '../core/constants/subscription_config.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// 구매 가능 여부
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  /// 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 상품 목록
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  /// 구독 상품만
  List<ProductDetails> get subscriptions => _products
      .where((p) => SubscriptionConfig.subscriptionIds.contains(p.id))
      .toList();

  /// 일회성 상품만
  List<ProductDetails> get consumables => _products
      .where((p) => SubscriptionConfig.consumableIds.contains(p.id))
      .toList();

  /// 구매 완료 콜백
  Function(PurchaseDetails)? onPurchaseCompleted;

  /// 구매 에러 콜백
  Function(String)? onPurchaseError;

  /// 초기화
  Future<void> initialize() async {
    try {
      _isAvailable = await _inAppPurchase.isAvailable();

      if (!_isAvailable) {
        dev.log('In-app purchase not available', name: 'SubscriptionService');
        return;
      }

      // 구매 이벤트 리스닝
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          dev.log('Purchase stream error: $error', name: 'SubscriptionService');
          onPurchaseError?.call('구매 처리 중 오류가 발생했습니다');
        },
      );

      // 상품 정보 로드
      await loadProducts();

      // 미완료 구매 복원
      await restorePurchases();

      dev.log('SubscriptionService initialized', name: 'SubscriptionService');
    } catch (e, stackTrace) {
      dev.log(
        'Failed to initialize SubscriptionService: $e',
        name: 'SubscriptionService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 상품 정보 로드
  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    _isLoading = true;

    try {
      final ProductDetailsResponse response = await _inAppPurchase
          .queryProductDetails(SubscriptionConfig.allProductIds.toSet());

      if (response.notFoundIDs.isNotEmpty) {
        dev.log(
          'Products not found: ${response.notFoundIDs}',
          name: 'SubscriptionService',
        );
      }

      _products = response.productDetails;
      dev.log(
        'Loaded ${_products.length} products',
        name: 'SubscriptionService',
      );
    } catch (e) {
      dev.log('Failed to load products: $e', name: 'SubscriptionService');
    } finally {
      _isLoading = false;
    }
  }

  /// 구독 구매
  Future<bool> purchaseSubscription(String productId) async {
    if (!_isAvailable) {
      onPurchaseError?.call('결제 기능을 사용할 수 없습니다');
      return false;
    }

    try {
      final product = _products.firstWhere((p) => p.id == productId);

      final purchaseParam = PurchaseParam(productDetails: product);
      final bool success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        onPurchaseError?.call('구매를 시작할 수 없습니다');
      }

      return success;
    } catch (e) {
      dev.log('Purchase failed: $e', name: 'SubscriptionService');
      onPurchaseError?.call('구매 중 오류가 발생했습니다');
      return false;
    }
  }

  /// 일회성 상품 구매
  Future<bool> purchaseConsumable(String productId) async {
    if (!_isAvailable) {
      onPurchaseError?.call('결제 기능을 사용할 수 없습니다');
      return false;
    }

    try {
      final product = _products.firstWhere((p) => p.id == productId);

      final purchaseParam = PurchaseParam(productDetails: product);
      final bool success = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        onPurchaseError?.call('구매를 시작할 수 없습니다');
      }

      return success;
    } catch (e) {
      dev.log('Purchase failed: $e', name: 'SubscriptionService');
      onPurchaseError?.call('구매 중 오류가 발생했습니다');
      return false;
    }
  }

  /// 구매 업데이트 처리
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // 구매 대기 중
        dev.log('Purchase pending: ${purchaseDetails.productID}',
            name: 'SubscriptionService');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // 구매 실패
        dev.log('Purchase error: ${purchaseDetails.error}',
            name: 'SubscriptionService');
        onPurchaseError?.call('구매에 실패했습니다');
        _inAppPurchase.completePurchase(purchaseDetails);
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // 구매 성공 또는 복원
        dev.log('Purchase completed: ${purchaseDetails.productID}',
            name: 'SubscriptionService');

        // 서버에서 영수증 검증 (프로덕션에서는 필수)
        _verifyPurchase(purchaseDetails).then((verified) {
          if (verified) {
            onPurchaseCompleted?.call(purchaseDetails);
          } else {
            onPurchaseError?.call('구매 검증에 실패했습니다');
          }
          _inAppPurchase.completePurchase(purchaseDetails);
        });
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        // 구매 취소
        dev.log('Purchase canceled: ${purchaseDetails.productID}',
            name: 'SubscriptionService');
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  /// 영수증 검증 (서버에서 수행해야 함)
  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: 실제 프로덕션에서는 서버에서 영수증 검증
    // 현재는 테스트 모드이므로 항상 true 반환
    if (SubscriptionConfig.isTestMode) {
      dev.log(
        'Test mode: Skipping verification for ${purchaseDetails.productID}',
        name: 'SubscriptionService',
      );
      return true;
    }

    // 프로덕션에서는 Firebase Functions 등을 통해 검증
    // final response = await http.post(
    //   Uri.parse('https://your-server.com/verify-purchase'),
    //   body: {
    //     'receipt': purchaseDetails.verificationData.serverVerificationData,
    //     'productId': purchaseDetails.productID,
    //   },
    // );
    // return response.statusCode == 200;

    return true;
  }

  /// 구매 복원
  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _inAppPurchase.restorePurchases();
      dev.log('Purchases restored', name: 'SubscriptionService');
    } catch (e) {
      dev.log('Failed to restore purchases: $e', name: 'SubscriptionService');
      onPurchaseError?.call('구매 복원에 실패했습니다');
    }
  }

  /// ID로 상품 조회
  ProductDetails? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// 정리
  void dispose() {
    _subscription?.cancel();
  }
}
