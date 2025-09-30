import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class SubscriptionService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 商品ID（実際のApp Store/Google Play Consoleで設定する必要があります）
  static const String _removeAdsProductId = 'remove_ads_400';
  static const String _monthlySubscriptionId = 'monthly_subscription_400';
  static const String _yearlySubscriptionId = 'yearly_subscription_3500';
  
  // プレミアム状態
  static bool _isPremium = false;
  static bool _isAdsRemoved = false;
  
  // 商品情報
  static List<ProductDetails> _products = [];
  static bool _isInitialized = false;
  
  static bool get isPremium => _isPremium;
  static bool get isAdsRemoved => _isAdsRemoved;
  static List<ProductDetails> get products => _products;
  static bool get isInitialized => _isInitialized;
  
  // 初期化
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 購入履歴を監視
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => print('Purchase stream error: $error'),
      );
      
      // 利用可能な商品を取得
      await _loadProducts();
      
      // 既存の購入を復元
      await _restorePurchases();
      
      _isInitialized = true;
      print('Subscription service initialized');
    } catch (e) {
      print('Failed to initialize subscription service: $e');
    }
  }
  
  // 商品情報を読み込み
  static Future<void> _loadProducts() async {
    try {
      final Set<String> productIds = {
        _removeAdsProductId,
        _monthlySubscriptionId,
        _yearlySubscriptionId,
      };
      
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        print('Products not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      print('Loaded ${_products.length} products');
    } catch (e) {
      print('Failed to load products: $e');
    }
  }
  
  // 購入履歴の復元
  static Future<void> _restorePurchases() async {
    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) return;
      
      // ローカル保存から状態を復元
      await _loadLocalState();
    } catch (e) {
      print('Failed to restore purchases: $e');
    }
  }
  
  // 購入更新の処理
  static void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      _processPurchase(purchaseDetails);
    }
  }
  
  // 購入の処理
  static Future<void> _processPurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      
      switch (purchaseDetails.productID) {
        case _removeAdsProductId:
          _isAdsRemoved = true;
          await _saveLocalState();
          break;
        case _monthlySubscriptionId:
        case _yearlySubscriptionId:
          _isPremium = true;
          await _saveLocalState();
          break;
      }
      
      // 購入完了の確認
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }
  
  // 広告削除の購入
  static Future<bool> purchaseRemoveAds() async {
    try {
      final ProductDetails? product = _products.firstWhere(
        (p) => p.id == _removeAdsProductId,
        orElse: () => throw Exception('Product not found'),
      );
      
      if (product == null) {
        print('Product not found: $_removeAdsProductId');
        return false;
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Failed to purchase remove ads: $e');
      return false;
    }
  }
  
  // 月額サブスクリプションの購入
  static Future<bool> purchaseMonthlySubscription() async {
    try {
      final ProductDetails? product = _products.firstWhere(
        (p) => p.id == _monthlySubscriptionId,
        orElse: () => throw Exception('Product not found'),
      );
      
      if (product == null) {
        print('Product not found: $_monthlySubscriptionId');
        return false;
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Failed to purchase monthly subscription: $e');
      return false;
    }
  }
  
  // 年額サブスクリプションの購入
  static Future<bool> purchaseYearlySubscription() async {
    try {
      final ProductDetails? product = _products.firstWhere(
        (p) => p.id == _yearlySubscriptionId,
        orElse: () => throw Exception('Product not found'),
      );
      
      if (product == null) {
        print('Product not found: $_yearlySubscriptionId');
        return false;
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      print('Failed to purchase yearly subscription: $e');
      return false;
    }
  }
  
  // 購入履歴の復元
  static Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      print('Failed to restore purchases: $e');
    }
  }
  
  // ローカル状態の保存
  static Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', _isPremium);
    await prefs.setBool('isAdsRemoved', _isAdsRemoved);
  }
  
  // ローカル状態の読み込み
  static Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('isPremium') ?? false;
    _isAdsRemoved = prefs.getBool('isAdsRemoved') ?? false;
  }
  
  // リソースの解放
  static void dispose() {
    _subscription?.cancel();
  }
}
