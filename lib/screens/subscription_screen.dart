import 'package:flutter/material.dart';
import '../services/purchase_service.dart';
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
    _setupPurchaseCallback();
  }

  Future<void> _initializeSubscription() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await PurchaseService.initialize();
    } catch (e) {
      setState(() {
        _error = '購入サービスの初期化に失敗しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupPurchaseCallback() {
    PurchaseService.setPurchaseCompletedCallback((String productId) {
      String message;
      switch (productId) {
        case 'remove_ads':
          message = '広告削除を購入しました！';
          break;
        case 'premium_pack':
          message = 'プレミアムパックを購入しました！';
          break;
        case 'monthly_premium':
          message = '月額プレミアムを購入しました！';
          break;
        default:
          message = '購入が完了しました！';
      }
      
      if (mounted) {
        _showSuccessDialog(message);
        setState(() {}); // UIを更新
      }
    });
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
    final isPremium = PurchaseService.hasAllFeatures;
    final isAdsRemoved = PurchaseService.hasAdsRemoved;

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
          
          // 学習進捗（プレミアムユーザーのみ）
          if (isPremium) _buildProgressSection(),
          if (isPremium) const SizedBox(height: 24),
          
          // サブスク解約（月額プレミアムユーザーのみ）
          if (PurchaseService.isMonthlyPremiumActive) _buildCancelSubscription(),
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
          '購入オプション',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildPurchaseOption(
          title: '広告削除',
          description: 'すべての広告を非表示にします',
          price: '¥400',
          period: '買い切り',
          isPurchased: PurchaseService.isRemoveAdsPurchased,
          onTap: _purchaseRemoveAds,
        ),
        const SizedBox(height: 12),
        _buildPurchaseOption(
          title: 'プレミアムパック',
          description: '追加問題＋リスニング解説を開放',
          price: '¥600',
          period: '買い切り',
          isPurchased: PurchaseService.isPremiumPackPurchased,
          onTap: _purchasePremiumPack,
        ),
        const SizedBox(height: 12),
        _buildPurchaseOption(
          title: '月額プレミアム',
          description: '全機能を含む月額サブスクリプション',
          price: '¥400',
          period: '月額',
          isPurchased: PurchaseService.isMonthlyPremiumActive,
          isRecommended: true,
          onTap: _purchaseMonthlyPremium,
        ),
        const SizedBox(height: 16),
        // 復元ボタン
        Center(
          child: OutlinedButton.icon(
            onPressed: _restorePurchases,
            icon: const Icon(Icons.restore),
            label: const Text('購入を復元'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseOption({
    required String title,
    required String description,
    required String price,
    required String period,
    required bool isPurchased,
    required VoidCallback onTap,
    bool isRecommended = false,
  }) {
    return Card(
      elevation: isRecommended ? 4 : 1,
      child: InkWell(
        onTap: isPurchased ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isRecommended ? Border.all(color: Colors.purple, width: 2) : null,
            color: isPurchased ? Colors.green[50] : null,
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
                        if (isPurchased) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '購入済み',
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
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$price / $period',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPurchased)
                const Icon(Icons.check_circle, color: Colors.green, size: 24)
              else
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

  Widget _buildCancelSubscription() {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'サブスクリプション管理',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'サブスクリプションの解約や管理は、各ストアで行う必要があります。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openSubscriptionManagement,
                icon: const Icon(Icons.open_in_new),
                label: const Text('サブスク管理ページを開く'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[400]!),
                ),
              ),
            ),
          ],
        ),
      ),
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

  Future<void> _purchaseRemoveAds() async {
    setState(() => _isLoading = true);
    try {
      final success = await PurchaseService.purchaseRemoveAds();
      if (success) {
        // 購入フローが開始されただけなので、ここではダイアログを表示しない
        // 実際の購入完了は purchaseStream で監視される
        print('PurchaseService: Remove ads purchase flow started');
      } else {
        _showErrorDialog('購入に失敗しました');
      }
    } catch (e) {
      _showErrorDialog('エラーが発生しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchasePremiumPack() async {
    setState(() => _isLoading = true);
    try {
      final success = await PurchaseService.purchasePremiumPack();
      if (success) {
        // 購入フローが開始されただけなので、ここではダイアログを表示しない
        // 実際の購入完了は purchaseStream で監視される
        print('PurchaseService: Premium pack purchase flow started');
      } else {
        _showErrorDialog('購入に失敗しました');
      }
    } catch (e) {
      _showErrorDialog('エラーが発生しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchaseMonthlyPremium() async {
    setState(() => _isLoading = true);
    try {
      final success = await PurchaseService.purchaseMonthlyPremium();
      if (success) {
        // 購入フローが開始されただけなので、ここではダイアログを表示しない
        // 実際の購入完了は purchaseStream で監視される
        print('PurchaseService: Monthly premium purchase flow started');
      } else {
        _showErrorDialog('購入に失敗しました');
      }
    } catch (e) {
      _showErrorDialog('エラーが発生しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      // 復元前の状態を記録
      final bool hadRemoveAds = PurchaseService.isRemoveAdsPurchased;
      final bool hadPremiumPack = PurchaseService.isPremiumPackPurchased;
      final bool hadMonthlyPremium = PurchaseService.isMonthlyPremiumActive;
      
      await PurchaseService.restorePurchases();
      
      // 復元後の状態を確認
      final bool nowHasRemoveAds = PurchaseService.isRemoveAdsPurchased;
      final bool nowHasPremiumPack = PurchaseService.isPremiumPackPurchased;
      final bool nowHasMonthlyPremium = PurchaseService.isMonthlyPremiumActive;
      
      // 実際に復元されたかチェック
      final bool somethingRestored = 
          (!hadRemoveAds && nowHasRemoveAds) ||
          (!hadPremiumPack && nowHasPremiumPack) ||
          (!hadMonthlyPremium && nowHasMonthlyPremium);
      
      if (somethingRestored) {
        _showSuccessDialog('購入履歴を復元しました！');
      } else {
        _showErrorDialog('復元できる購入履歴がありません');
      }
      
      setState(() {}); // UIを更新
    } catch (e) {
      _showErrorDialog('復元に失敗しました: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openSubscriptionManagement() async {
    try {
      await PurchaseService.openSubscriptionManagement();
    } catch (e) {
      _showErrorDialog('サブスク管理ページを開けませんでした: $e');
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
