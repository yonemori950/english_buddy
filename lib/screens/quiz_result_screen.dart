import 'package:flutter/material.dart';

class QuizResultScreen extends StatelessWidget {
  final int correctAnswers;
  final int totalQuestions;
  final int score;
  final int expGained;
  final Map<String, int> tagResults;

  const QuizResultScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.score,
    required this.expGained,
    required this.tagResults,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
    final accuracyPercentage = (accuracy * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('結果'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 結果サマリー
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // 正解率の円グラフ風表示
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: CircularProgressIndicator(
                                value: accuracy,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getAccuracyColor(accuracy),
                                ),
                              ),
                            ),
                            Text(
                              '$accuracyPercentage%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // スコア情報
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildScoreItem('正解数', '$correctAnswers / $totalQuestions', Icons.check_circle),
                            _buildScoreItem('スコア', '$score', Icons.star),
                            _buildScoreItem('獲得EXP', '+$expGained', Icons.trending_up),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 分野別結果
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '分野別結果',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...tagResults.entries.map((entry) {
                          final tagName = _getTagName(entry.key);
                          final correctCount = entry.value;
                          final totalCount = _getTotalQuestionsForTag(entry.key);
                          final tagAccuracy = totalCount > 0 ? correctCount / totalCount : 0.0;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getTagColor(entry.key),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tagName,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Text(
                                  '$correctCount / $totalCount',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(tagAccuracy * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getAccuracyColor(tagAccuracy),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 苦手分野の表示
                if (_hasWeakAreas())
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '苦手分野',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getWeakAreasText(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const Spacer(),
                
                // アクションボタン
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/quiz',
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('もう一度'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('ホームに戻る'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue[600], size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getTagColor(String tag) {
    switch (tag) {
      case 'grammar':
        return Colors.blue;
      case 'vocabulary':
        return Colors.green;
      case 'reading':
        return Colors.orange;
      case 'listening':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTagName(String tag) {
    switch (tag) {
      case 'grammar':
        return '文法';
      case 'vocabulary':
        return '語彙';
      case 'reading':
        return '長文';
      case 'listening':
        return 'リスニング';
      default:
        return tag;
    }
  }

  int _getTotalQuestionsForTag(String tag) {
    // 実際の実装では、各タグの総問題数を計算する必要があります
    // ここでは簡易的に正解数から推定します
    return tagResults[tag] ?? 0;
  }

  bool _hasWeakAreas() {
    return tagResults.entries.any((entry) {
      final correctCount = entry.value;
      final totalCount = _getTotalQuestionsForTag(entry.key);
      final accuracy = totalCount > 0 ? correctCount / totalCount : 0.0;
      return accuracy < 0.6;
    });
  }

  String _getWeakAreasText() {
    final weakAreas = tagResults.entries.where((entry) {
      final correctCount = entry.value;
      final totalCount = _getTotalQuestionsForTag(entry.key);
      final accuracy = totalCount > 0 ? correctCount / totalCount : 0.0;
      return accuracy < 0.6;
    }).map((entry) => _getTagName(entry.key)).toList();

    return weakAreas.join('、') + 'の復習をおすすめします。';
  }
}
