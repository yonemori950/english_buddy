import 'package:flutter/material.dart';
import '../services/rewarded_ad_service.dart';
import '../services/explanation_service.dart';
import '../widgets/explanation_dialog.dart';

class QuizResultScreen extends StatefulWidget {
  final int correctAnswers;
  final int totalQuestions;
  final int score;
  final int expGained;
  final Map<String, int> tagResults;
  final List<Map<String, dynamic>> wrongAnswers;

  const QuizResultScreen({
    super.key,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.score,
    required this.expGained,
    required this.tagResults,
    required this.wrongAnswers,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _hasWatchedAd = false;

  @override
  void initState() {
    super.initState();
    // リワード広告を事前読み込み
    RewardedAdService.loadRewardedAd();
    // 解説データを読み込み
    ExplanationService.loadExplanations();
  }

  void _showRewardedAd() {
    RewardedAdService.showRewardedAd(
      onRewarded: () {
        setState(() {
          _hasWatchedAd = true;
        });
        _showExplanationDialog();
      },
      onAdFailedToShow: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('広告の読み込みに失敗しました。しばらくしてから再試行してください。'),
          ),
        );
      },
    );
  }

  void _showExplanationDialog() {
    if (widget.wrongAnswers.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('解説'),
          content: const Text('間違えた問題がありません。\n素晴らしい結果です！'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('間違えた問題の解説'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: widget.wrongAnswers.length,
            itemBuilder: (context, index) {
              final wrongAnswer = widget.wrongAnswers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    '問題 ${wrongAnswer['id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    wrongAnswer['question'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pop(context);
                    ExplanationDialog.show(
                      context,
                      questionId: wrongAnswer['id'],
                      questionText: wrongAnswer['question'],
                      userAnswer: wrongAnswer['userAnswer'],
                      correctAnswer: wrongAnswer['correctAnswer'],
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.totalQuestions > 0 ? widget.correctAnswers / widget.totalQuestions : 0.0;
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
          child: SingleChildScrollView(
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
                            _buildScoreItem('正解数', '${widget.correctAnswers} / ${widget.totalQuestions}', Icons.check_circle),
                            _buildScoreItem('スコア', '${widget.score}', Icons.star),
                            _buildScoreItem('獲得EXP', '+${widget.expGained}', Icons.trending_up),
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
                        ...widget.tagResults.entries.map((entry) {
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
                          // 苦手分野をリスト形式で表示
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _getWeakAreas().map((area) => Chip(
                              label: Text(
                                area,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.red[50],
                              side: BorderSide(color: Colors.red[200]!),
                              labelStyle: TextStyle(color: Colors.red[700]),
                            )).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '復習をおすすめします',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // リワード広告ボタン
                          if (!_hasWatchedAd)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showRewardedAd,
                                icon: const Icon(Icons.play_circle_outline),
                                label: const Text('広告を見て解説を確認'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          if (_hasWatchedAd)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    '解説を確認済み',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
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
                
                const SizedBox(height: 24), // 下部の余白
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
    // 各タグの総問題数を計算（500問中125問ずつ）
    return 125;
  }

  bool _hasWeakAreas() {
    return widget.tagResults.entries.any((entry) {
      final correctCount = entry.value;
      final totalCount = _getTotalQuestionsForTag(entry.key);
      final accuracy = totalCount > 0 ? correctCount / totalCount : 0.0;
      return accuracy < 0.6;
    });
  }

  List<String> _getWeakAreas() {
    return widget.tagResults.entries.where((entry) {
      final correctCount = entry.value;
      final totalCount = _getTotalQuestionsForTag(entry.key);
      final accuracy = totalCount > 0 ? correctCount / totalCount : 0.0;
      return accuracy < 0.6;
    }).map((entry) => _getTagName(entry.key)).toList();
  }
}
