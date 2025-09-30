import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../services/quiz_service.dart';
import '../services/interstitial_ad_service.dart';
import '../widgets/audio_player_button.dart';
import '../providers/user_provider.dart';
import 'quiz_result_screen.dart';

class WeaknessQuizScreen extends StatefulWidget {
  const WeaknessQuizScreen({super.key});

  @override
  State<WeaknessQuizScreen> createState() => _WeaknessQuizScreenState();
}

class _WeaknessQuizScreenState extends State<WeaknessQuizScreen> {
  List<Question> questions = [];
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  Map<String, int> tagResults = {};
  bool isAnswered = false;
  String? selectedAnswer;
  bool isLoading = true;
  List<Map<String, dynamic>> wrongAnswers = []; // 間違えた問題の情報を記録

  @override
  void initState() {
    super.initState();
    // インタースティシャル広告を事前読み込み
    InterstitialAdService.loadInterstitialAd();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final loadedQuestions = await QuizService.loadQuestions();
    
    // ユーザーの苦手分野を分析
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    
    List<String> weakTags = ['vocabulary', 'listening']; // デフォルト
    
    if (user != null) {
      // 苦手分野を特定
      final scores = user.scores;
      final tagAccuracies = <String, double>{};
      
      scores.forEach((tag, tagScores) {
        final correct = tagScores['correct'] ?? 0;
        final wrong = tagScores['wrong'] ?? 0;
        final total = correct + wrong;
        
        if (total > 0) {
          final accuracy = correct / total;
          tagAccuracies[tag] = accuracy;
        }
      });
      
      // 正答率の低いタグを取得
      final sortedTags = tagAccuracies.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      weakTags = sortedTags.take(2).map((e) => e.key).toList();
    }
    
    setState(() {
      questions = QuizService.getWeaknessQuestions(weakTags, 10);
      isLoading = false;
    });
  }

  void _selectAnswer(String answer) {
    if (isAnswered) return;

    setState(() {
      selectedAnswer = answer;
      isAnswered = true;
    });

    final currentQuestion = questions[currentQuestionIndex];
    final isCorrect = answer == currentQuestion.answer;

    if (isCorrect) {
      correctAnswers++;
    } else {
      // 間違えた問題の情報を記録
      wrongAnswers.add({
        'id': currentQuestion.id,
        'question': currentQuestion.question,
        'userAnswer': answer,
        'correctAnswer': currentQuestion.answer,
        'tag': currentQuestion.tag,
      });
    }

    // タグ別の結果を記録
    final tag = currentQuestion.tag;
    tagResults[tag] = (tagResults[tag] ?? 0) + (isCorrect ? 1 : 0);

    // スコアをFirebaseに保存
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.updateScore(tag, isCorrect);
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        isAnswered = false;
        selectedAnswer = null;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() async {
    final score = correctAnswers * 10;
    final expGained = correctAnswers * 10 + (questions.length - correctAnswers) * 2;

    // インタースティシャル広告を表示
    await InterstitialAdService.showInterstitialAd();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            correctAnswers: correctAnswers,
            totalQuestions: questions.length,
            score: score,
            expGained: expGained,
            tagResults: tagResults,
            wrongAnswers: wrongAnswers, // 間違えた問題の情報を渡す
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('苦手克服'),
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('苦手分野の問題が見つかりませんでした'),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('苦手克服'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('クイズを終了しますか？'),
                content: const Text('現在の進捗は保存されません。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('終了'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Column(
        children: [
          // プログレスバー
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('問題 ${currentQuestionIndex + 1} / ${questions.length}'),
                    Text('正解: $correctAnswers'),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
                ),
              ],
            ),
          ),
          
          // 問題文
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // タグ表示
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTagColor(currentQuestion.tag),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _getTagName(currentQuestion.tag),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 問題文
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // リスニング問題の場合は音声再生ボタンを表示
                          if (currentQuestion.tag == 'listening' && currentQuestion.audio != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.volume_up,
                                  color: Colors.purple,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '音声を再生してください',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.purple,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                AudioPlayerButton(
                                  audioPath: currentQuestion.audio,
                                  textToSpeak: _extractListeningText(currentQuestion.question),
                                  size: 40,
                                  color: Colors.purple,
                                ),
                              ],
                            ),
                          if (currentQuestion.tag == 'listening' && currentQuestion.audio != null)
                            const SizedBox(height: 16),
                          Text(
                            currentQuestion.question,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 選択肢
                  ...currentQuestion.choices.asMap().entries.map((entry) {
                    final index = entry.key;
                    final choice = entry.value;
                    final isSelected = selectedAnswer == choice;
                    final isCorrect = choice == currentQuestion.answer;
                    
                    Color? backgroundColor;
                    Color? textColor;
                    
                    if (isAnswered) {
                      if (isCorrect) {
                        backgroundColor = Colors.green[100];
                        textColor = Colors.green[800];
                      } else if (isSelected && !isCorrect) {
                        backgroundColor = Colors.red[100];
                        textColor = Colors.red[800];
                      }
                    } else if (isSelected) {
                      backgroundColor = Colors.orange[100];
                      textColor = Colors.orange[800];
                    }
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        onPressed: () => _selectAnswer(choice),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: backgroundColor,
                          foregroundColor: textColor,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          choice,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }).toList(),
                  
                  // 次へボタン
                  if (isAnswered)
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        currentQuestionIndex < questions.length - 1 ? '次へ' : '結果を見る',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  
                  const SizedBox(height: 16), // 下部の余白
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  // リスニング問題から音声化するテキストを抽出
  String _extractListeningText(String questionText) {
    // リスニング問題の形式: "Q: What does the woman want to buy?\nA) A new bag\nB) A pair of shoes\nC) A hat\nD) A coat"
    // 質問部分のみを抽出して音声化
    final lines = questionText.split('\n');
    if (lines.isNotEmpty) {
      final questionLine = lines[0];
      if (questionLine.startsWith('Q: ')) {
        return questionLine.substring(3); // "Q: "を除去
      }
    }
    return questionText;
  }
}
