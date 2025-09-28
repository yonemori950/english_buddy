import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AppOpenAdService {
  static AppOpenAd? _appOpenAd;
  static bool _isAdLoaded = false;
  static bool _isShowingAd = false;

  // アプリ起動広告ID
  static const String _androidAdUnitId = 'ca-app-pub-8148356110096114/9855878791';
  static const String _iosAdUnitId = 'ca-app-pub-8148356110096114/9855878791';

  static String get adUnitId {
    if (Platform.isAndroid) {
      return _androidAdUnitId;
    } else if (Platform.isIOS) {
      return _iosAdUnitId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static Future<void> loadAppOpenAd() async {
    if (_isAdLoaded) return;

    try {
      await AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isAdLoaded = true;
            print('App Open Ad loaded successfully');
          },
          onAdFailedToLoad: (error) {
            print('App Open Ad failed to load: $error');
            _isAdLoaded = false;
          },
        ),
      );
    } catch (e) {
      print('Error loading App Open Ad: $e');
      _isAdLoaded = false;
    }
  }

  static Future<bool> showAppOpenAd() async {
    if (_isShowingAd || !_isAdLoaded || _appOpenAd == null) {
      return false;
    }

    try {
      _isShowingAd = true;
      
      await _appOpenAd!.show();
      
      // 広告が閉じられた後の処理
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('App Open Ad showed full screen content');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('App Open Ad dismissed');
          _isShowingAd = false;
          _isAdLoaded = false;
          ad.dispose();
          _appOpenAd = null;
          
          // 次の広告を事前読み込み
          loadAppOpenAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('App Open Ad failed to show: $error');
          _isShowingAd = false;
          _isAdLoaded = false;
          ad.dispose();
          _appOpenAd = null;
        },
      );

      return true;
    } catch (e) {
      print('Error showing App Open Ad: $e');
      _isShowingAd = false;
      return false;
    }
  }

  static bool get isAdLoaded => _isAdLoaded;
  static bool get isShowingAd => _isShowingAd;
}
