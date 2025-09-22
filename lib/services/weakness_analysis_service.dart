import '../models/user.dart' as app_user;

class WeaknessAnalysisService {
  // 苦手分野を分析
  static Map<String, dynamic> analyzeWeakness(app_user.User user) {
    final scores = user.scores;
    final totalQuestions = scores.values.fold(0, (sum, tagScores) => 
      sum + (tagScores['correct'] ?? 0) + (tagScores['wrong'] ?? 0));
    
    if (totalQuestions == 0) {
      return {
        'weakestTag': null,
        'weaknessLevel': 'none',
        'recommendations': ['まずはクイズを解いてみましょう！'],
        'tagAnalysis': {},
        'overallScore': 0.0,
      };
    }

    // タグ別の正答率を計算
    final tagAnalysis = <String, Map<String, dynamic>>{};
    double totalCorrect = 0;
    double totalQuestionsDouble = totalQuestions.toDouble();

    scores.forEach((tag, tagScores) {
      final correct = tagScores['correct'] ?? 0;
      final wrong = tagScores['wrong'] ?? 0;
      final total = correct + wrong;
      
      if (total > 0) {
        final accuracy = correct / total;
        totalCorrect += correct;
        
        tagAnalysis[tag] = {
          'correct': correct,
          'wrong': wrong,
          'total': total,
          'accuracy': accuracy,
          'level': _getLevelFromAccuracy(accuracy),
          'recommendation': _getRecommendation(tag, accuracy),
        };
      }
    });

    final overallScore = totalCorrect / totalQuestionsDouble;
    final weakestTag = _findWeakestTag(tagAnalysis);
    final weaknessLevel = _getWeaknessLevel(overallScore);

    return {
      'weakestTag': weakestTag,
      'weaknessLevel': weaknessLevel,
      'recommendations': _getRecommendations(weakestTag, weaknessLevel),
      'tagAnalysis': tagAnalysis,
      'overallScore': overallScore,
    };
  }

  // 正答率からレベルを判定
  static String _getLevelFromAccuracy(double accuracy) {
    if (accuracy >= 0.8) return 'excellent';
    if (accuracy >= 0.6) return 'good';
    if (accuracy >= 0.4) return 'fair';
    return 'weak';
  }

  // タグ別の推奨事項
  static String _getRecommendation(String tag, double accuracy) {
    switch (tag) {
      case 'grammar':
        if (accuracy < 0.4) {
          return '基本的な文法を復習しましょう';
        } else if (accuracy < 0.6) {
          return '時制や語順を重点的に学習';
        } else if (accuracy < 0.8) {
          return '複雑な文法構造を練習';
        } else {
          return '文法は得意分野です！';
        }
      case 'vocabulary':
        if (accuracy < 0.4) {
          return '基本単語から覚え直しましょう';
        } else if (accuracy < 0.6) {
          return '語彙力を向上させる練習を';
        } else if (accuracy < 0.8) {
          return '高度な語彙を学習';
        } else {
          return '語彙力は十分です！';
        }
      case 'reading':
        if (accuracy < 0.4) {
          return '短文から読解練習を始めましょう';
        } else if (accuracy < 0.6) {
          return '長文読解のコツを学習';
        } else if (accuracy < 0.8) {
          return '複雑な文章を読む練習';
        } else {
          return '読解力は優秀です！';
        }
      case 'listening':
        if (accuracy < 0.4) {
          return '基本的なリスニング練習から';
        } else if (accuracy < 0.6) {
          return '聞き取りのコツを学習';
        } else if (accuracy < 0.8) {
          return '高速リスニングに挑戦';
        } else {
          return 'リスニング力は完璧です！';
        }
      default:
        return '継続的な学習を心がけましょう';
    }
  }

  // 最も苦手な分野を特定
  static String? _findWeakestTag(Map<String, Map<String, dynamic>> tagAnalysis) {
    if (tagAnalysis.isEmpty) return null;
    
    String? weakestTag;
    double lowestAccuracy = 1.0;
    
    tagAnalysis.forEach((tag, analysis) {
      final accuracy = analysis['accuracy'] as double;
      if (accuracy < lowestAccuracy) {
        lowestAccuracy = accuracy;
        weakestTag = tag;
      }
    });
    
    return weakestTag;
  }

  // 全体の苦手レベルを判定
  static String _getWeaknessLevel(double overallScore) {
    if (overallScore >= 0.8) return 'excellent';
    if (overallScore >= 0.6) return 'good';
    if (overallScore >= 0.4) return 'fair';
    return 'weak';
  }

  // 推奨事項を生成
  static List<String> _getRecommendations(String? weakestTag, String weaknessLevel) {
    final recommendations = <String>[];
    
    switch (weaknessLevel) {
      case 'excellent':
        recommendations.addAll([
          '素晴らしい成績です！',
          'より高度な問題に挑戦してみましょう',
          '他の学習者をサポートしてみてはいかがですか？',
        ]);
        break;
      case 'good':
        recommendations.addAll([
          '良い成績を維持しています！',
          '苦手分野を重点的に学習しましょう',
          '定期的な復習を心がけてください',
        ]);
        break;
      case 'fair':
        recommendations.addAll([
          '基礎を固めることが重要です',
          '毎日少しずつ学習を続けましょう',
          '苦手分野の基本から見直してください',
        ]);
        break;
      case 'weak':
        recommendations.addAll([
          '基礎からしっかりと学習しましょう',
          '焦らずに一歩ずつ進んでください',
          '毎日継続することが大切です',
        ]);
        break;
    }
    
    if (weakestTag != null) {
      switch (weakestTag) {
        case 'grammar':
          recommendations.add('文法問題を重点的に練習しましょう');
          break;
        case 'vocabulary':
          recommendations.add('語彙力を向上させる学習をしましょう');
          break;
        case 'reading':
          recommendations.add('読解問題を多く解いてみましょう');
          break;
        case 'listening':
          recommendations.add('リスニング練習を増やしましょう');
          break;
      }
    }
    
    return recommendations;
  }

  // タグ名を日本語に変換
  static String getTagDisplayName(String tag) {
    switch (tag) {
      case 'grammar': return '文法';
      case 'vocabulary': return '語彙';
      case 'reading': return '読解';
      case 'listening': return 'リスニング';
      default: return tag;
    }
  }

  // レベル名を日本語に変換
  static String getLevelDisplayName(String level) {
    switch (level) {
      case 'excellent': return '優秀';
      case 'good': return '良好';
      case 'fair': return '普通';
      case 'weak': return '要改善';
      default: return level;
    }
  }
}
