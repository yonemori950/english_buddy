import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _notificationsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 19, minute: 0);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await NotificationService.areNotificationsEnabled();
    final settings = await NotificationService.getNotificationSettings();
    
    setState(() {
      _notificationsEnabled = enabled;
      _reminderTime = TimeOfDay(
        hour: settings['hour']!,
        minute: settings['minute']!,
      );
      _isLoading = false;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      await _updateNotificationSettings();
    }
  }

  Future<void> _updateNotificationSettings() async {
    await NotificationService.updateNotificationSettings(
      _reminderTime.hour,
      _reminderTime.minute,
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    await NotificationService.toggleNotifications(value);
    
    if (value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('通知が有効になりました'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('通知が無効になりました'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 通知の有効/無効
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications,
                              color: Colors.indigo[600],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                '通知を有効にする',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Switch(
                              value: _notificationsEnabled,
                              onChanged: _toggleNotifications,
                              activeColor: Colors.indigo[600],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '毎日の学習リマインダーと励まし通知を受け取ります',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // リマインダー時間設定
                if (_notificationsEnabled) ...[
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.indigo[600],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'リマインダー時間',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _selectTime,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.indigo[600],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _reminderTime.format(context),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.arrow_forward_ios),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '毎日この時間に学習リマインダーが届きます',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 通知の種類
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.indigo[600],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '通知の種類',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildNotificationType(
                          icon: Icons.schedule,
                          title: '毎日の学習リマインダー',
                          description: '設定した時間に毎日通知が届きます',
                        ),
                        const SizedBox(height: 12),
                        _buildNotificationType(
                          icon: Icons.emoji_events,
                          title: '学習完了の励まし',
                          description: 'クイズを解いた後に励ましメッセージが届きます',
                        ),
                        const SizedBox(height: 12),
                        _buildNotificationType(
                          icon: Icons.timer_off,
                          title: '非アクティブリマインダー',
                          description: '1日開いていない場合に通知が届きます',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 注意事項
                Card(
                  elevation: 4,
                  color: Colors.amber[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Colors.amber[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '注意事項',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• 通知はアプリがバックグラウンドにある時に届きます\n'
                          '• 端末の通知設定で個別に無効にできます\n'
                          '• 学習を継続することで英語力が向上します',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationType({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.indigo[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
