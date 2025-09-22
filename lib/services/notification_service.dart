import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  // 通知を初期化
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // タイムゾーンデータを初期化
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    // Android初期化設定
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS初期化設定
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  // 通知タップ時の処理
  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // 必要に応じてアプリの特定画面に遷移
  }

  // 毎日の学習リマインダー通知を設定
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String? customMessage,
  }) async {
    await _notifications.cancel(1); // 既存の通知をキャンセル

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // 過去の時間の場合は翌日に設定
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final messages = [
      '英検2級の学習時間です！今日も頑張りましょう 📚',
      'クイズで英語力を向上させませんか？ 🎯',
      '継続は力なり！今日の学習を始めましょう 💪',
      '英検2級合格に向けて、一歩前進しましょう 🏆',
      '毎日の積み重ねが大きな成果につながります ✨',
    ];

    final message = customMessage ?? messages[DateTime.now().day % messages.length];

    await _notifications.zonedSchedule(
      1,
      '英検2級クイズ',
      message,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          '毎日の学習リマインダー',
          channelDescription: '毎日の学習を促すリマインダー通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );

    // 設定を保存
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', hour);
    await prefs.setInt('reminder_minute', minute);
  }

  // 1日開いていない場合の通知を設定
  static Future<void> scheduleInactivityReminder() async {
    await _notifications.cancel(2); // 既存の通知をキャンセル

    final now = DateTime.now();
    final scheduledDate = now.add(const Duration(days: 1));

    await _notifications.zonedSchedule(
      2,
      '英検2級クイズ',
      '1日お疲れ様でした！明日も学習を続けましょう 🌟',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'inactivity_reminder',
          '非アクティブリマインダー',
          channelDescription: '1日開いていない場合のリマインダー通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'inactivity_reminder',
    );
  }

  // アプリが開かれた時に非アクティブ通知をキャンセル
  static Future<void> cancelInactivityReminder() async {
    await _notifications.cancel(2);
  }

  // 学習完了時の励まし通知
  static Future<void> showEncouragementNotification() async {
    final messages = [
      '素晴らしい！学習を続けていますね 🎉',
      '今日もお疲れ様でした！継続が力になります 💪',
      '着実に英語力が向上しています 📈',
      '毎日の積み重ねが素晴らしいです ✨',
      '英検2級合格に向けて順調です 🏆',
    ];

    final message = messages[DateTime.now().millisecond % messages.length];

    await _notifications.show(
      3,
      '英検2級クイズ',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'encouragement',
          '励まし通知',
          channelDescription: '学習完了時の励まし通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'encouragement',
    );
  }

  // 通知の許可をリクエスト
  static Future<bool> requestPermission() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    return result ?? false;
  }

  // 通知設定を取得
  static Future<Map<String, int>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hour': prefs.getInt('reminder_hour') ?? 19,
      'minute': prefs.getInt('reminder_minute') ?? 0,
    };
  }

  // 通知設定を更新
  static Future<void> updateNotificationSettings(int hour, int minute) async {
    await scheduleDailyReminder(hour: hour, minute: minute);
  }

  // すべての通知をキャンセル
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // 通知の有効/無効を切り替え
  static Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    
    if (enabled) {
      final settings = await getNotificationSettings();
      await scheduleDailyReminder(
        hour: settings['hour']!,
        minute: settings['minute']!,
      );
    } else {
      await cancelAllNotifications();
    }
  }

  // 通知が有効かどうかを確認
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }
}
