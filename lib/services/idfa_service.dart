import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class IDFAService {
  static bool _isInitialized = false;
  static TrackingStatus _trackingStatus = TrackingStatus.notDetermined;

  // IDFAの初期化
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (Platform.isIOS) {
      // iOSの場合のみIDFAをリクエスト
      await _requestIDFA();
    }

    _isInitialized = true;
  }

  // IDFAの許可をリクエスト
  static Future<void> _requestIDFA() async {
    try {
      // 現在のステータスを取得
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      _trackingStatus = status;

      // まだ決定されていない場合はリクエスト
      if (status == TrackingStatus.notDetermined) {
        final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
        _trackingStatus = newStatus;
      }

      // IDFAを取得（許可されている場合）
      if (_trackingStatus == TrackingStatus.authorized) {
        final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
        print('IDFA: $idfa');
        
        // AdMobにIDFAを設定
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: [],
            tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
            tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
            maxAdContentRating: MaxAdContentRating.g,
            sameAppKeyEnabled: true,
          ),
        );
      }
    } catch (e) {
      print('IDFA request error: $e');
    }
  }

  // 現在のトラッキングステータスを取得
  static TrackingStatus get trackingStatus => _trackingStatus;

  // IDFAが許可されているかチェック
  static bool get isIDFAAuthorized => _trackingStatus == TrackingStatus.authorized;

  // IDFAの許可を再リクエスト
  static Future<void> requestIDFAAgain() async {
    if (Platform.isIOS) {
      final status = await AppTrackingTransparency.requestTrackingAuthorization();
      _trackingStatus = status;
    }
  }

  // トラッキングステータスの説明を取得
  static String getTrackingStatusDescription() {
    switch (_trackingStatus) {
      case TrackingStatus.authorized:
        return '広告追跡が許可されています';
      case TrackingStatus.denied:
        return '広告追跡が拒否されています';
      case TrackingStatus.restricted:
        return '広告追跡が制限されています';
      case TrackingStatus.notDetermined:
        return '広告追跡の許可が未決定です';
    }
  }

  // トラッキングステータスの色を取得
  static String getTrackingStatusColor() {
    switch (_trackingStatus) {
      case TrackingStatus.authorized:
        return 'green';
      case TrackingStatus.denied:
        return 'red';
      case TrackingStatus.restricted:
        return 'orange';
      case TrackingStatus.notDetermined:
        return 'grey';
    }
  }
}
