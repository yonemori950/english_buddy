import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class InterstitialAdService {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoaded = false;
  static bool _isShowingAd = false;

  // インタースティシャル広告ID
  static const String _androidAdUnitId = 'ca-app-pub-8148356110096114/9020297510';
  static const String _iosAdUnitId = 'ca-app-pub-8148356110096114/1747763417';

  static String get adUnitId {
    if (Platform.isAndroid) {
      return _androidAdUnitId;
    } else if (Platform.isIOS) {
      return _iosAdUnitId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static Future<void> loadInterstitialAd() async {
    if (_isAdLoaded) return;

    try {
      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isAdLoaded = true;
            print('Interstitial Ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            print('Interstitial Ad failed to load: $error');
            _isAdLoaded = false;
          },
        ),
      );
    } catch (e) {
      print('Error loading Interstitial Ad: $e');
      _isAdLoaded = false;
    }
  }

  static Future<bool> showInterstitialAd() async {
    if (_isShowingAd || !_isAdLoaded || _interstitialAd == null) {
      return false;
    }

    try {
      _isShowingAd = true;
      
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('Interstitial Ad showed full screen content');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('Interstitial Ad dismissed');
          _isShowingAd = false;
          _isAdLoaded = false;
          ad.dispose();
          _interstitialAd = null;
          
          // 次の広告を事前読み込み
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Interstitial Ad failed to show: $error');
          _isShowingAd = false;
          _isAdLoaded = false;
          ad.dispose();
          _interstitialAd = null;
        },
      );

      await _interstitialAd!.show();
      return true;
    } catch (e) {
      print('Error showing Interstitial Ad: $e');
      _isShowingAd = false;
      return false;
    }
  }

  static bool get isAdLoaded => _isAdLoaded;
  static bool get isShowingAd => _isShowingAd;
}
