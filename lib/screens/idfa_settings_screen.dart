import 'dart:io';
import 'package:flutter/material.dart';
import '../services/idfa_service.dart';

class IDFASettingsScreen extends StatefulWidget {
  const IDFASettingsScreen({super.key});

  @override
  State<IDFASettingsScreen> createState() => _IDFASettingsScreenState();
}

class _IDFASettingsScreenState extends State<IDFASettingsScreen> {
  bool _isLoading = true;
  String _statusDescription = '';
  String _statusColor = 'grey';

  @override
  void initState() {
    super.initState();
    _loadIDFAStatus();
  }

  Future<void> _loadIDFAStatus() async {
    setState(() {
      _isLoading = true;
    });

    // 少し待ってからステータスを更新
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _statusDescription = IDFAService.getTrackingStatusDescription();
      _statusColor = IDFAService.getTrackingStatusColor();
      _isLoading = false;
    });
  }

  Future<void> _requestIDFAAgain() async {
    setState(() {
      _isLoading = true;
    });

    await IDFAService.requestIDFAAgain();
    await _loadIDFAStatus();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_statusDescription),
          backgroundColor: _getStatusColor(),
        ),
      );
    }
  }

  Color _getStatusColor() {
    switch (_statusColor) {
      case 'green': return Colors.green;
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('広告追跡設定'),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 現在のステータス
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
                              Icons.track_changes,
                              color: Colors.indigo[600],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '現在の設定',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoading)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getStatusColor().withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(),
                                  color: _getStatusColor(),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _statusDescription,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _getStatusColor(),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 説明
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
                              '広告追跡について',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoItem(
                          icon: Icons.ads_click,
                          title: '関連性の高い広告',
                          description: 'あなたの興味に合った広告を表示します',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          icon: Icons.analytics,
                          title: '広告効果の測定',
                          description: '広告の効果を測定して改善します',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          icon: Icons.school,
                          title: '学習体験の向上',
                          description: 'より良い学習アプリの開発に活用します',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // プライバシー情報
                Card(
                  elevation: 4,
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.privacy_tip,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'プライバシーについて',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• あなたの個人情報は保護されます\n'
                          '• 広告の表示のみに使用されます\n'
                          '• いつでも設定から変更できます\n'
                          '• 学習データとは分離して管理されます',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // アクションボタン
                if (Platform.isIOS) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _requestIDFAAgain,
                      icon: const Icon(Icons.settings),
                      label: const Text(
                        '設定を変更する',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Androidでは広告追跡の設定は不要です',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
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

  IconData _getStatusIcon() {
    switch (_statusColor) {
      case 'green': return Icons.check_circle;
      case 'red': return Icons.cancel;
      case 'orange': return Icons.warning;
      default: return Icons.help;
    }
  }
}
