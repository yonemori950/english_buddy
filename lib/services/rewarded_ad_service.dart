import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';

class RewardedAdService {
  static RewardedAd? _rewardedAd;
  static bool _isAdLoaded = false;

  static Future<void> loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: AdService.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  static Future<bool> showRewardedAd({
    required Function() onRewarded,
    required Function() onAdFailedToShow,
  }) async {
    if (!_isAdLoaded || _rewardedAd == null) {
      await loadRewardedAd();
      if (!_isAdLoaded || _rewardedAd == null) {
        onAdFailedToShow();
        return false;
      }
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isAdLoaded = false;
        loadRewardedAd(); // 次の広告を事前読み込み
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isAdLoaded = false;
        onAdFailedToShow();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onRewarded();
      },
    );

    return true;
  }

  static bool get isAdLoaded => _isAdLoaded;
}
