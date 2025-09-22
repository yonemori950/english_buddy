import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _isInitialized = false;
  
  // テスト用広告ID（本番では実際のIDに変更）
  static const String _bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  static String get bannerAdUnitId => _bannerAdUnitId;
  static String get rewardedAdUnitId => _rewardedAdUnitId;
  static String get interstitialAdUnitId => _interstitialAdUnitId;
}
