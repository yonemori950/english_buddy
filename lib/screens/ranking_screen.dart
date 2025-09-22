import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/ranking_service.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _overallRankings = [];
  List<Map<String, dynamic>> _weeklyRankings = [];
  List<Map<String, dynamic>> _monthlyRankings = [];
  int _userRank = -1;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRankings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 各ランキングを並行して取得
      final futures = await Future.wait([
        RankingService.getScoreRanking(limit: 50),
        RankingService.getWeeklyRanking(limit: 50),
        RankingService.getMonthlyRanking(limit: 50),
      ]);

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.currentUser;
      
      int userRank = -1;
      if (currentUser != null) {
        userRank = await RankingService.getUserRank(currentUser.uid);
      }

      setState(() {
        _overallRankings = futures[0];
        _weeklyRankings = futures[1];
        _monthlyRankings = futures[2];
        _userRank = userRank;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'ランキングの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '総合'),
            Tab(text: '今週'),
            Tab(text: '今月'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRankings,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[50]!, Colors.white],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRankingTab('総合', _overallRankings),
            _buildRankingTab('今週', _weeklyRankings),
            _buildRankingTab('今月', _monthlyRankings),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingTab(String period, List<Map<String, dynamic>> rankings) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRankings,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ユーザーの順位表示
        if (_userRank > 0) _buildUserRankCard(),
        
        // ランキングリスト
        Expanded(
          child: rankings.isEmpty
              ? _buildEmptyState()
              : _buildRankingList(rankings),
        ),
      ],
    );
  }

  Widget _buildUserRankCard() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.purple[600]!],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$_userRank',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'あなたの順位',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  currentUser.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'レベル ${currentUser.level} • ${currentUser.exp} EXP',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.emoji_events,
            color: Colors.amber[300],
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'まだランキングデータがありません',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'クイズを解いてスコアを獲得しましょう！',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(List<Map<String, dynamic>> rankings) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final ranking = rankings[index];
        final rank = index + 1;
        final isCurrentUser = _isCurrentUser(ranking['uid']);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildRankingItem(ranking, rank, isCurrentUser),
        );
      },
    );
  }

  Widget _buildRankingItem(Map<String, dynamic> ranking, int rank, bool isCurrentUser) {
    final name = ranking['name'] as String;
    final score = ranking['score'] as int;
    final level = ranking['level'] as int;
    
    Color backgroundColor = Colors.white;
    Color textColor = Colors.black87;
    
    if (isCurrentUser) {
      backgroundColor = Colors.purple[50]!;
      textColor = Colors.purple[800]!;
    } else if (rank <= 3) {
      backgroundColor = _getRankColor(rank).withOpacity(0.1);
      textColor = _getRankColor(rank);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser 
            ? Border.all(color: Colors.purple[300]!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 順位
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3 ? _getRankColor(rank) : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      _getRankIcon(rank),
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          
          // ユーザー情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple[600],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'あなた',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'レベル $level • $score EXP',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // スコア
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Text(
                'EXP',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isCurrentUser(String uid) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    return currentUser?.uid == uid;
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1: return Colors.amber[600]!; // 金
      case 2: return Colors.grey[400]!;  // 銀
      case 3: return Colors.orange[600]!; // 銅
      default: return Colors.grey[300]!;
    }
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1: return Icons.emoji_events; // 金メダル
      case 2: return Icons.emoji_events; // 銀メダル
      case 3: return Icons.emoji_events; // 銅メダル
      default: return Icons.person;
    }
  }
}