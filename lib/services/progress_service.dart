import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'premium_service.dart';

class ProgressService {
  static FirebaseFirestore? get _firestore => FirebaseService.firestore;
  static FirebaseAuth? get _auth => FirebaseService.auth;
  
  // 日別の学習記録を保存
  static Future<void> saveDailyProgress({
    required int questionsAnswered,
    required int correctAnswers,
    required int timeSpent, // 秒
    required Map<String, int> categoryResults,
  }) async {
    try {
      if (_auth == null || _firestore == null) {
        print('Firebase not available, skipping progress save');
        return;
      }
      
      final user = _auth!.currentUser;
      if (user == null) return;
      
      final today = DateTime.now();
      final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final progressData = {
        'date': dateString,
        'questions': questionsAnswered,
        'correct': correctAnswers,
        'timeSpent': timeSpent,
        'accuracy': questionsAnswered > 0 ? correctAnswers / questionsAnswered : 0.0,
        'categoryResults': categoryResults,
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      await _firestore!
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc(dateString)
          .set(progressData, SetOptions(merge: true));
      
      print('Daily progress saved: $progressData');
    } catch (e) {
      print('Failed to save daily progress: $e');
    }
  }
  
  // 過去30日の学習記録を取得
  static Future<List<Map<String, dynamic>>> getLast30DaysProgress() async {
    try {
      if (_auth == null || _firestore == null) {
        print('Firebase not available, returning empty progress');
        return [];
      }
      
      final user = _auth!.currentUser;
      if (user == null) return [];
      
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final startDate = '${thirtyDaysAgo.year}-${thirtyDaysAgo.month.toString().padLeft(2, '0')}-${thirtyDaysAgo.day.toString().padLeft(2, '0')}';
      
      final QuerySnapshot snapshot = await _firestore!
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .orderBy('date')
          .get();
      
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Failed to get progress data: $e');
      return [];
    }
  }
  
  // 週別の学習統計を取得
  static Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final progressData = await getLast30DaysProgress();
      if (progressData.isEmpty) return {};
      
      // 過去7日間のデータを取得
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentData = progressData.where((data) {
        final date = DateTime.parse(data['date']);
        return date.isAfter(sevenDaysAgo);
      }).toList();
      
      if (recentData.isEmpty) return {};
      
      int totalQuestions = 0;
      int totalCorrect = 0;
      int totalTimeSpent = 0;
      final Map<String, int> categoryStats = {};
      
      for (final data in recentData) {
        totalQuestions += (data['questions'] as int? ?? 0);
        totalCorrect += (data['correct'] as int? ?? 0);
        totalTimeSpent += (data['timeSpent'] as int? ?? 0);
        
        final categoryResults = data['categoryResults'] as Map<String, dynamic>?;
        if (categoryResults != null) {
          categoryResults.forEach((category, score) {
            categoryStats[category] = (categoryStats[category] ?? 0) + (score as int);
          });
        }
      }
      
      return {
        'totalQuestions': totalQuestions,
        'totalCorrect': totalCorrect,
        'totalTimeSpent': totalTimeSpent,
        'accuracy': totalQuestions > 0 ? totalCorrect / totalQuestions : 0.0,
        'averageTimePerQuestion': totalQuestions > 0 ? totalTimeSpent / totalQuestions : 0,
        'categoryStats': categoryStats,
        'studyDays': recentData.length,
      };
    } catch (e) {
      print('Failed to get weekly stats: $e');
      return {};
    }
  }
  
  // 苦手分野の分析
  static Future<List<String>> getWeakAreas() async {
    try {
      final progressData = await getLast30DaysProgress();
      if (progressData.isEmpty) return [];
      
      final Map<String, List<int>> categoryScores = {};
      
      // 各カテゴリのスコアを集計
      for (final data in progressData) {
        final categoryResults = data['categoryResults'] as Map<String, dynamic>?;
        if (categoryResults != null) {
          categoryResults.forEach((category, score) {
            categoryScores.putIfAbsent(category, () => []);
            categoryScores[category]!.add(score as int);
          });
        }
      }
      
      final List<String> weakAreas = [];
      
      // 各カテゴリの平均スコアを計算
      categoryScores.forEach((category, scores) {
        if (scores.isNotEmpty) {
          final averageScore = scores.reduce((a, b) => a + b) / scores.length;
          final totalQuestions = scores.length * 25; // 1日25問と仮定
          final accuracy = totalQuestions > 0 ? averageScore / totalQuestions : 0;
          
          if (accuracy < 0.6) { // 60%未満を苦手分野とする
            weakAreas.add(_getCategoryDisplayName(category));
          }
        }
      });
      
      return weakAreas;
    } catch (e) {
      print('Failed to analyze weak areas: $e');
      return [];
    }
  }
  
  // カテゴリ名の日本語表示
  static String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'grammar':
        return '文法';
      case 'vocabulary':
        return '語彙';
      case 'reading':
        return '読解';
      case 'listening':
        return 'リスニング';
      default:
        return category;
    }
  }
  
  // 学習ストリーク（連続学習日数）を取得
  static Future<int> getLearningStreak() async {
    try {
      final progressData = await getLast30DaysProgress();
      if (progressData.isEmpty) return 0;
      
      // 日付順にソート
      progressData.sort((a, b) => a['date'].compareTo(b['date']));
      
      int streak = 0;
      DateTime currentDate = DateTime.now();
      
      // 今日から逆算して連続学習日数を計算
      for (int i = 0; i < 30; i++) {
        final checkDate = currentDate.subtract(Duration(days: i));
        final dateString = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        
        final hasData = progressData.any((data) => data['date'] == dateString);
        
        if (hasData) {
          streak++;
        } else if (i > 0) { // 今日は学習していなくてもOK
          break;
        }
      }
      
      return streak;
    } catch (e) {
      print('Failed to get learning streak: $e');
      return 0;
    }
  }
  
  // 学習目標の達成状況を取得
  static Future<Map<String, dynamic>> getGoalProgress() async {
    try {
      final weeklyStats = await getWeeklyStats();
      if (weeklyStats.isEmpty) return {};
      
      // 目標設定（例）
      const int dailyGoal = 20; // 1日20問
      const int weeklyGoal = 140; // 1週間140問
      const double accuracyGoal = 0.7; // 70%の正答率
      
      final int totalQuestions = weeklyStats['totalQuestions'] ?? 0;
      final double accuracy = weeklyStats['accuracy'] ?? 0.0;
      final int studyDays = weeklyStats['studyDays'] ?? 0;
      
      return {
        'dailyGoal': dailyGoal,
        'weeklyGoal': weeklyGoal,
        'accuracyGoal': accuracyGoal,
        'currentQuestions': totalQuestions,
        'currentAccuracy': accuracy,
        'studyDays': studyDays,
        'dailyProgress': studyDays > 0 ? totalQuestions / studyDays : 0,
        'weeklyProgress': totalQuestions / weeklyGoal,
        'accuracyProgress': accuracy / accuracyGoal,
      };
    } catch (e) {
      print('Failed to get goal progress: $e');
      return {};
    }
  }
}
