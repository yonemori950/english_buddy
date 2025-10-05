import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class PurchaseService {
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 購入完了時のコールバック
  static Function(String productId)? _onPurchaseCompleted;
  
  // 商品ID（プラットフォーム別）
  static String get _removeAdsProductId {
    if (Platform.isIOS) {
      return 'com.gamelab.englishBuddy.remove_ads';  // iOS App Store
    } else {
      return 'remove_ads';  // Android Google Play
    }
  }
  
  static const String _premiumPackProductId = 'premium_pack';  // 両方共通
  
  static String get _monthlyPremiumProductId {
    if (Platform.isIOS) {
      return 'com.gamelab.englishBuddy.monthly_premium';  // iOS App Store
    } else {
      return 'com.gamelab.englishbuddy.monthly_premium';  // Android Google Play（小文字のb）
    }
  }
  
  // 購入状態
  static bool _isRemoveAdsPurchased = false;
  static bool _isPremiumPackPurchased = false;
  static bool _isMonthlyPremiumActive = false;
  
  // 商品情報
  static List<ProductDetails> _products = [];
  static bool _isInitialized = false;
  
  // ゲッター
  static bool get isRemoveAdsPurchased => _isRemoveAdsPurchased;
  static bool get isPremiumPackPurchased => _isPremiumPackPurchased;
  static bool get isMonthlyPremiumActive => _isMonthlyPremiumActive;
  static List<ProductDetails> get products => _products;
  static bool get isInitialized => _isInitialized;
  
  // プレミアム機能の総合判定
  static bool get hasAllFeatures => _isMonthlyPremiumActive || (_isRemoveAdsPurchased && _isPremiumPackPurchased);
  static bool get hasAdsRemoved => _isMonthlyPremiumActive || _isRemoveAdsPurchased;
  static bool get hasPremiumPack => _isMonthlyPremiumActive || _isPremiumPackPurchased;
  
  // 初期化
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('PurchaseService: Initializing...');
      
      // 購入履歴を監視
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => print('PurchaseService: Purchase stream error: $error'),
      );
      
      // 利用可能な商品を取得
      await _loadProducts();
      
      // 既存の購入を復元
      await _restorePurchases();
      
      _isInitialized = true;
      print('PurchaseService: Initialized successfully');
    } catch (e) {
      print('PurchaseService: Failed to initialize: $e');
    }
  }
  
  // 商品情報を読み込み
  static Future<void> _loadProducts() async {
    try {
      final Set<String> productIds = {
        _removeAdsProductId,
        _premiumPackProductId,
        _monthlyPremiumProductId,
      };
      
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        print('PurchaseService: Products not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      print('PurchaseService: Loaded ${_products.length} products');
      
      // 商品情報をログ出力
      for (final product in _products) {
        print('PurchaseService: Product - ID: ${product.id}, Title: ${product.title}, Price: ${product.price}');
      }
    } catch (e) {
      print('PurchaseService: Failed to load products: $e');
    }
  }
  
  // 購入履歴の復元
  static Future<void> _restorePurchases() async {
    try {
      final bool isAvailable = await _inAppPurchase.isAvailable();
      if (!isAvailable) {
        print('PurchaseService: In-app purchase not available');
        return;
      }
      
      // ローカル保存から状態を復元
      await _loadLocalState();
      
      // プラットフォーム固有の復元処理
      if (Platform.isAndroid) {
        await _restoreAndroidPurchases();
      } else if (Platform.isIOS) {
        await _restoreIOSPurchases();
      }
      
      print('PurchaseService: Purchase state restored');
      _logPurchaseState();
    } catch (e) {
      print('PurchaseService: Failed to restore purchases: $e');
    }
  }
  
  // Android用の復元処理
  static Future<void> _restoreAndroidPurchases() async {
    try {
      // Android Play Billing の restorePurchases を使用
      await _inAppPurchase.restorePurchases();
      print('PurchaseService: Android purchases restored');
    } catch (e) {
      print('PurchaseService: Failed to restore Android purchases: $e');
    }
  }
  
  // iOS用の復元処理
  static Future<void> _restoreIOSPurchases() async {
    try {
      // iOS StoreKit2 の restorePurchases を使用
      await _inAppPurchase.restorePurchases();
      print('PurchaseService: iOS purchases restored');
    } catch (e) {
      print('PurchaseService: Failed to restore iOS purchases: $e');
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
    print('PurchaseService: Processing purchase - ID: ${purchaseDetails.productID}, Status: ${purchaseDetails.status}');
    
    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {
      
      // プラットフォーム別の商品IDに対応
      final String productId = purchaseDetails.productID;
      
      // 商品IDの検証を追加
      final bool isValidProduct = productId == _removeAdsProductId || 
                                 productId == _premiumPackProductId || 
                                 productId == _monthlyPremiumProductId;
      
      if (!isValidProduct) {
        print('PurchaseService: Invalid product ID: $productId');
        return;
      }
      
      // 購入の検証（Android用の追加チェック）
      if (Platform.isAndroid) {
        // Android Play Billing の検証を強化
        if (purchaseDetails.verificationData.serverVerificationData.isEmpty) {
          print('PurchaseService: Android purchase verification failed - no server data');
          return;
        }
      }
      
      if (productId == _removeAdsProductId) {
        _isRemoveAdsPurchased = true;
        await _saveLocalState();
        print('PurchaseService: Remove ads purchased');
        _onPurchaseCompleted?.call('remove_ads');
      } else if (productId == _premiumPackProductId) {
        _isPremiumPackPurchased = true;
        await _saveLocalState();
        print('PurchaseService: Premium pack purchased');
        _onPurchaseCompleted?.call('premium_pack');
      } else if (productId == _monthlyPremiumProductId) {
        _isMonthlyPremiumActive = true;
        // 月額サブスクリプションは全機能を含む
        _isRemoveAdsPurchased = true;
        _isPremiumPackPurchased = true;
        await _saveLocalState();
        print('PurchaseService: Monthly premium activated');
        _onPurchaseCompleted?.call('monthly_premium');
      }
      
      // 購入完了の確認
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
        print('PurchaseService: Purchase completed');
      }
    } else if (purchaseDetails.status == PurchaseStatus.error) {
      print('PurchaseService: Purchase error: ${purchaseDetails.error}');
    }
  }
  
  // 広告削除の購入
  static Future<bool> purchaseRemoveAds() async {
    try {
      print('PurchaseService: Attempting to purchase remove ads');
      
      // 既に購入済みかチェック
      if (_isRemoveAdsPurchased) {
        print('PurchaseService: Remove ads already purchased');
        return true;
      }
      
      final ProductDetails? product = _getProduct(_removeAdsProductId);
      
      if (product == null) {
        print('PurchaseService: Remove ads product not found');
        return false;
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      print('PurchaseService: Remove ads purchase result: $success');
      
      // 注意: 購入状態の更新は _processPurchase メソッドで行う
      // buyNonConsumable の戻り値は購入開始の成功のみを示す
      // 実際の購入完了は purchaseStream で監視される
      
      return success;
    } catch (e) {
      print('PurchaseService: Failed to purchase remove ads: $e');
      return false;
    }
  }
  
  // プレミアムパックの購入
  static Future<bool> purchasePremiumPack() async {
    try {
      print('PurchaseService: Attempting to purchase premium pack');
      
      // 既に購入済みかチェック
      if (_isPremiumPackPurchased) {
        print('PurchaseService: Premium pack already purchased');
        return true;
      }
      
      final ProductDetails? product = _getProduct(_premiumPackProductId);
      
      if (product == null) {
        print('PurchaseService: Premium pack product not found');
        return false;
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      print('PurchaseService: Premium pack purchase result: $success');
      
      // 注意: 購入状態の更新は _processPurchase メソッドで行う
      // buyNonConsumable の戻り値は購入開始の成功のみを示す
      // 実際の購入完了は purchaseStream で監視される
      
      return success;
    } catch (e) {
      print('PurchaseService: Failed to purchase premium pack: $e');
      return false;
    }
  }
  
  // 月額プレミアムの購入
  static Future<bool> purchaseMonthlyPremium() async {
    try {
      print('PurchaseService: Attempting to purchase monthly premium');
      
      // 既に購入済みかチェック
      if (_isMonthlyPremiumActive) {
        print('PurchaseService: Monthly premium already active');
        return true;
      }
      
      final ProductDetails? product = _getProduct(_monthlyPremiumProductId);
      
      if (product == null) {
        print('PurchaseService: Monthly premium product not found');
        return false;
      }
      
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      // in_app_purchaseパッケージは商品タイプから自動的にサブスクリプションか買い切りか判断
      final bool success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      print('PurchaseService: Monthly premium purchase result: $success');
      
      // 注意: 購入状態の更新は _processPurchase メソッドで行う
      // buyNonConsumable の戻り値は購入開始の成功のみを示す
      // 実際の購入完了は purchaseStream で監視される
      
      return success;
    } catch (e) {
      print('PurchaseService: Failed to purchase monthly premium: $e');
      return false;
    }
  }
  
  // 購入履歴の復元
  static Future<void> restorePurchases() async {
    try {
      print('PurchaseService: Restoring purchases...');
      await _inAppPurchase.restorePurchases();
      print('PurchaseService: Purchases restored');
    } catch (e) {
      print('PurchaseService: Failed to restore purchases: $e');
    }
  }
  
  // 商品情報を取得
  static ProductDetails? _getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }
  
  // ローカル状態の保存
  static Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isRemoveAdsPurchased', _isRemoveAdsPurchased);
    await prefs.setBool('isPremiumPackPurchased', _isPremiumPackPurchased);
    await prefs.setBool('isMonthlyPremiumActive', _isMonthlyPremiumActive);
    print('PurchaseService: Local state saved');
  }
  
  // ローカル状態の読み込み
  static Future<void> _loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    _isRemoveAdsPurchased = prefs.getBool('isRemoveAdsPurchased') ?? false;
    _isPremiumPackPurchased = prefs.getBool('isPremiumPackPurchased') ?? false;
    _isMonthlyPremiumActive = prefs.getBool('isMonthlyPremiumActive') ?? false;
    print('PurchaseService: Local state loaded');
  }
  
  // 購入状態をログ出力
  static void _logPurchaseState() {
    print('PurchaseService: Current purchase state:');
    print('  - Remove Ads: $_isRemoveAdsPurchased');
    print('  - Premium Pack: $_isPremiumPackPurchased');
    print('  - Monthly Premium: $_isMonthlyPremiumActive');
    print('  - Has All Features: $hasAllFeatures');
    print('  - Has Ads Removed: $hasAdsRemoved');
    print('  - Has Premium Pack: $hasPremiumPack');
  }
  
  // サブスクリプション状態の確認
  static Future<bool> checkSubscriptionStatus() async {
    try {
      print('PurchaseService: Checking subscription status...');
      
      // プラットフォーム固有のサブスク状態確認
      if (Platform.isAndroid) {
        return await _checkAndroidSubscription();
      } else if (Platform.isIOS) {
        return await _checkIOSSubscription();
      }
      
      return false;
    } catch (e) {
      print('PurchaseService: Failed to check subscription status: $e');
      return false;
    }
  }
  
  // Android用のサブスク状態確認
  static Future<bool> _checkAndroidSubscription() async {
    try {
      // Android Play Billing の購入状態は purchaseStream で監視
      // ローカル状態を確認
      return _isMonthlyPremiumActive;
    } catch (e) {
      print('PurchaseService: Failed to check Android subscription: $e');
      return false;
    }
  }
  
  // iOS用のサブスク状態確認
  static Future<bool> _checkIOSSubscription() async {
    try {
      // iOS StoreKit2 の購入状態は purchaseStream で監視
      // ローカル状態を確認
      return _isMonthlyPremiumActive;
    } catch (e) {
      print('PurchaseService: Failed to check iOS subscription: $e');
      return false;
    }
  }
  
  // サブスクリプションの定期確認
  static Future<void> validateSubscription() async {
    try {
      print('PurchaseService: Validating subscription...');
      
      final bool isActive = await checkSubscriptionStatus();
      
      if (!isActive && _isMonthlyPremiumActive) {
        // サブスクが無効になった場合
        _isMonthlyPremiumActive = false;
        await _saveLocalState();
        print('PurchaseService: Subscription expired, features disabled');
      } else if (isActive && !_isMonthlyPremiumActive) {
        // サブスクが有効になった場合
        _isMonthlyPremiumActive = true;
        _isRemoveAdsPurchased = true;
        _isPremiumPackPurchased = true;
        await _saveLocalState();
        print('PurchaseService: Subscription activated, all features enabled');
      }
      
      _logPurchaseState();
    } catch (e) {
      print('PurchaseService: Failed to validate subscription: $e');
    }
  }
  
  // デバッグ用：購入状態をリセット
  static Future<void> resetPurchaseState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isRemoveAdsPurchased');
    await prefs.remove('isPremiumPackPurchased');
    await prefs.remove('isMonthlyPremiumActive');
    
    _isRemoveAdsPurchased = false;
    _isPremiumPackPurchased = false;
    _isMonthlyPremiumActive = false;
    
    print('PurchaseService: Purchase state reset');
  }
  
  // デバッグ用：購入状態を強制設定
  static Future<void> setPurchaseState({
    bool removeAds = false,
    bool premiumPack = false,
    bool monthlyPremium = false,
  }) async {
    _isRemoveAdsPurchased = removeAds;
    _isPremiumPackPurchased = premiumPack;
    _isMonthlyPremiumActive = monthlyPremium;
    
    await _saveLocalState();
    _logPurchaseState();
    
    print('PurchaseService: Purchase state set manually');
  }
  
  // デバッグ用：商品情報を表示
  static void logProductInfo() {
    print('PurchaseService: Available products:');
    for (final product in _products) {
      print('  - ID: ${product.id}');
      print('    Title: ${product.title}');
      print('    Description: ${product.description}');
      print('    Price: ${product.price}');
      print('    Currency: ${product.currencyCode}');
    }
  }
  
  // デバッグ用：購入可能かチェック
  static Future<bool> canMakePurchases() async {
    return await _inAppPurchase.isAvailable();
  }
  
  // サブスクリプション解約ページを開く
  static Future<void> openSubscriptionManagement() async {
    try {
      Uri? uri;
      
      if (Platform.isIOS) {
        // iOS App Storeのサブスク管理ページ
        uri = Uri.parse('https://apps.apple.com/account/subscriptions');
      } else if (Platform.isAndroid) {
        // Android Google Playのサブスク管理ページ
        uri = Uri.parse('https://play.google.com/store/account/subscriptions?package=com.gamelab.englishBuddy');
      }
      
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('PurchaseService: Opened subscription management page');
      } else {
        print('PurchaseService: Could not launch subscription management URL');
      }
    } catch (e) {
      print('PurchaseService: Failed to open subscription management: $e');
    }
  }
  
  // 購入完了コールバックを設定
  static void setPurchaseCompletedCallback(Function(String productId) callback) {
    _onPurchaseCompleted = callback;
  }
  
  // リソースの解放
  static void dispose() {
    _subscription?.cancel();
  }
}