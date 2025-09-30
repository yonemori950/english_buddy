import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/question.dart';
import '../services/quiz_service.dart';
import '../services/premium_service.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../widgets/audio_player_button.dart';
import '../providers/user_provider.dart';
import 'quiz_result_screen.dart';
import 'subscription_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> questions = [];
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  Map<String, int> tagResults = {};
  bool isAnswered = false;
  String? selectedAnswer;
  bool isLoading = true;
  List<Map<String, dynamic>> wrongAnswers = []; // 間違えた問題の情報を記録
  DateTime? _quizStartTime; // クイズ開始時間

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final loadedQuestions = await QuizService.loadQuestions();
    
    // プレミアム機能の制限を適用
    final filteredQuestions = PremiumService.filterQuestionsForUser(loadedQuestions);
    
    setState(() {
      questions = QuizService.getRandomQuestionsFromList(filteredQuestions, 10); // 10問ランダム出題
      isLoading = false;
      _quizStartTime = DateTime.now(); // クイズ開始時間を記録
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

    // 音声効果を再生
    if (isCorrect) {
      SoundService.playCorrectSound();
      correctAnswers++;
    } else {
      SoundService.playIncorrectSound();
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
    final score = correctAnswers * 10; // 正解1問につき10点
    final expGained = correctAnswers * 10 + (questions.length - correctAnswers) * 2; // 正解+10、不正解+2

    // 学習進捗を保存
    if (_quizStartTime != null) {
      final timeSpent = DateTime.now().difference(_quizStartTime!).inSeconds;
      await ProgressService.saveDailyProgress(
        questionsAnswered: questions.length,
        correctAnswers: correctAnswers,
        timeSpent: timeSpent,
        categoryResults: tagResults,
      );
    }

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
          title: const Text('クイズ'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('問題を読み込めませんでした'),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('クイズ'),
        backgroundColor: Colors.blue[600],
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                ),
              ],
            ),
          ),
          
          // 問題文
          Expanded(
            child: Padding(
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
                                  textToSpeak: null, // 音声ファイルを優先するためTTSを無効化
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
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentQuestion.choices.length,
                      itemBuilder: (context, index) {
                        final choice = currentQuestion.choices[index];
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
                          backgroundColor = Colors.blue[100];
                          textColor = Colors.blue[800];
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
                      },
                    ),
                  ),
                  
                  // 次へボタン
                  if (isAnswered)
                    ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
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
    
    // フォールバック: 質問文全体を返す
    return questionText;
  }

  // リスニング問題用の会話を生成
  String _generateListeningConversation(Question question) {
    final questionText = question.question;
    final answer = question.answer;
    
    // 質問の内容に基づいて会話を生成
    if (questionText.contains('What does the man want to do?')) {
      if (answer.contains('dinner')) {
        return "What would you like to do tonight? I'm hungry, let's have dinner.";
      } else if (answer.contains('shopping')) {
        return "What would you like to do? I need to go shopping for groceries.";
      } else if (answer.contains('movie')) {
        return "What would you like to do? Let's watch a movie at home.";
      } else if (answer.contains('walk')) {
        return "What would you like to do? Let's take a walk in the park.";
      }
    } else if (questionText.contains('Where are the speakers going?')) {
      if (answer.contains('restaurant')) {
        return "Where should we go for lunch? How about the restaurant on Main Street?";
      } else if (answer.contains('park')) {
        return "Where should we go? Let's go to the park for a picnic.";
      } else if (answer.contains('library')) {
        return "Where should we go? I need to return some books to the library.";
      } else if (answer.contains('station')) {
        return "Where should we go? We need to catch the train at the station.";
      }
    } else if (questionText.contains('What time is the appointment?')) {
      if (answer.contains('2:00 PM')) {
        return "What time is your appointment? It's at 2:00 PM.";
      } else if (answer.contains('3:00 PM')) {
        return "What time is your appointment? It's at 3:00 PM.";
      } else if (answer.contains('4:00 PM')) {
        return "What time is your appointment? It's at 4:00 PM.";
      } else if (answer.contains('5:00 PM')) {
        return "What time is your appointment? It's at 5:00 PM.";
      }
    } else if (questionText.contains('What does the woman suggest?')) {
      if (answer.contains('taxi')) {
        return "How should we get there? Let's take a taxi.";
      } else if (answer.contains('bus')) {
        return "How should we get there? Let's take the bus.";
      } else if (answer.contains('walking')) {
        return "How should we get there? It's not far, let's walk.";
      } else if (answer.contains('driving')) {
        return "How should we get there? I can drive us there.";
      }
    } else if (questionText.contains('What is the weather like?')) {
      if (answer.contains('Sunny')) {
        return "How's the weather today? It's sunny and warm.";
      } else if (answer.contains('Rainy')) {
        return "How's the weather today? It's rainy and cold.";
      } else if (answer.contains('Cloudy')) {
        return "How's the weather today? It's cloudy and cool.";
      } else if (answer.contains('Snowy')) {
        return "How's the weather today? It's snowy and freezing.";
      }
    }
    
    // デフォルト: 質問文をそのまま返す
    return _extractListeningText(questionText);
  }
}
