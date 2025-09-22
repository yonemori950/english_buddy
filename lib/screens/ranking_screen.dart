import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // サンプルデータ（実際の実装ではFirestoreから取得）
    final rankings = [
      {'name': 'ユーザー1', 'score': 2500, 'level': 5},
      {'name': 'ユーザー2', 'score': 2300, 'level': 4},
      {'name': 'ユーザー3', 'score': 2100, 'level': 4},
      {'name': 'ユーザー4', 'score': 1900, 'level': 3},
      {'name': 'ユーザー5', 'score': 1700, 'level': 3},
      {'name': 'ユーザー6', 'score': 1500, 'level': 2},
      {'name': 'ユーザー7', 'score': 1300, 'level': 2},
      {'name': 'ユーザー8', 'score': 1100, 'level': 2},
      {'name': 'ユーザー9', 'score': 900, 'level': 1},
      {'name': 'あなた', 'score': 200, 'level': 1},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ランキング'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ヘッダー
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          size: 48,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'スコアランキング',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '上位10名を表示',
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
                
                // ランキングリスト
                Expanded(
                  child: ListView.builder(
                    itemCount: rankings.length,
                    itemBuilder: (context, index) {
                      final user = rankings[index];
                      final rank = index + 1;
                      final isCurrentUser = user['name'] == 'あなた';
                      
                      return Card(
                        elevation: isCurrentUser ? 6 : 2,
                        color: isCurrentUser ? Colors.blue[50] : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRankColor(rank),
                            child: Text(
                              rank.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user['name'] as String,
                            style: TextStyle(
                              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                              color: isCurrentUser ? Colors.blue[800] : null,
                            ),
                          ),
                          subtitle: Text('レベル ${user['level']}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${user['score']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'スコア',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // フッター
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'ランキング更新について',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'クイズを完了すると、スコアがランキングに反映されます。',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
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

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[700]!; // 金
      case 2:
        return Colors.grey[400]!; // 銀
      case 3:
        return Colors.brown[400]!; // 銅
      default:
        return Colors.blue[600]!;
    }
  }
}
