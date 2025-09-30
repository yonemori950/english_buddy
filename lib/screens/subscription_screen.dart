import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import '../services/premium_service.dart';
import '../services/progress_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeSubscription();
  }

  Future<void> _initializeSubscription() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await SubscriptionService.initialize();
    } catch (e) {
      setState(() {
        _error = 'サブスクリプションの初期化に失敗しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プレミアム機能'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildSubscriptionContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializeSubscription,
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionContent() {
    final isPremium = PremiumService.hasPremiumAccess;
    final isAdsRemoved = PremiumService.hasAdsRemoved;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ヘッダー
          _buildHeader(isPremium),
          const SizedBox(height: 24),
          
          // 現在の状態
          _buildCurrentStatus(isPremium, isAdsRemoved),
          const SizedBox(height: 24),
          
          // プレミアム機能の説明
          if (!isPremium) _buildPremiumFeatures(),
          const SizedBox(height: 24),
          
          // 購入オプション
          if (!isPremium) _buildPurchaseOptions(),
          const SizedBox(height: 24),
          
          // 広告削除オプション
          if (!isAdsRemoved) _buildRemoveAdsOption(),
          const SizedBox(height: 24),
          
          // 学習進捗（プレミアムユーザーのみ）
          if (isPremium) _buildProgressSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[600]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            isPremium ? Icons.star : Icons.star_border,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            isPremium ? 'プレミアム会員' : 'プレミアムにアップグレード',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? '全機能をご利用いただけます'
                : 'より効果的な学習のために',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(bool isPremium, bool isAdsRemoved) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '現在の状態',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusItem(
              'プレミアム機能',
              isPremium ? '利用可能' : '制限あり',
              isPremium ? Colors.green : Colors.orange,
            ),
            _buildStatusItem(
              '広告表示',
              isAdsRemoved ? '非表示' : '表示中',
              isAdsRemoved ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'プレミアム機能',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(PremiumService.getPremiumFeaturesDescription()),
            const SizedBox(height: 16),
            const Text(
              '無料版の制限',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(PremiumService.getFreeVersionLimitations()),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'サブスクリプション',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSubscriptionOption(
          title: '月額プラン',
          price: '¥400',
          period: '月額',
          onTap: _purchaseMonthlySubscription,
        ),
        const SizedBox(height: 12),
        _buildSubscriptionOption(
          title: '年額プラン',
          price: '¥3,500',
          period: '年額（20%お得）',
          isRecommended: true,
          onTap: _purchaseYearlySubscription,
        ),
      ],
    );
  }

  Widget _buildSubscriptionOption({
    required String title,
    required String price,
    required String period,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    return Card(
      elevation: isRecommended ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isRecommended ? Border.all(color: Colors.purple, width: 2) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'おすすめ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$price / $period',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemoveAdsOption() {
    return Card(
      child: InkWell(
        onTap: _purchaseRemoveAds,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.block, color: Colors.red),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '広告削除',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '¥400 - 買い切り',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ProgressService.getWeeklyStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = snapshot.data ?? {};
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '学習進捗',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressItem('今週の問題数', '${stats['totalQuestions'] ?? 0}問'),
                _buildProgressItem('正答率', '${((stats['accuracy'] ?? 0) * 100).toStringAsFixed(1)}%'),
                _buildProgressItem('学習時間', '${(stats['totalTimeSpent'] ?? 0) ~/ 60}分'),
                _buildProgressItem('学習日数', '${stats['studyDays'] ?? 0}日'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseMonthlySubscription() async {
    setState(() => _isLoading = true);
    try {
      final success = await SubscriptionService.purchaseMonthlySubscription();
      if (success) {
        _showSuccessDialog('月額サブスクリプションを購入しました！');
      } else {
        _showErrorDialog('購入に失敗しました');
      }
    } catch (e) {
      _showErrorDialog('エラーが発生しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchaseYearlySubscription() async {
    setState(() => _isLoading = true);
    try {
      final success = await SubscriptionService.purchaseYearlySubscription();
      if (success) {
        _showSuccessDialog('年額サブスクリプションを購入しました！');
      } else {
        _showErrorDialog('購入に失敗しました');
      }
    } catch (e) {
      _showErrorDialog('エラーが発生しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchaseRemoveAds() async {
    setState(() => _isLoading = true);
    try {
      final success = await SubscriptionService.purchaseRemoveAds();
      if (success) {
        _showSuccessDialog('広告削除を購入しました！');
      } else {
        _showErrorDialog('購入に失敗しました');
      }
    } catch (e) {
      _showErrorDialog('エラーが発生しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('購入完了'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {}); // 状態を更新
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
