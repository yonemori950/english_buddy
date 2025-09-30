import 'subscription_service.dart';
import '../models/question.dart';

class PremiumService {
  // 無料版で利用可能な問題数
  static const int _freeQuestionsPerCategory = 25; // 各カテゴリ25問
  static const int _freeListeningQuestions = 10; // リスニング10問
  
  // プレミアム機能の確認
  static bool get hasPremiumAccess => SubscriptionService.isPremium;
  static bool get hasAdsRemoved => SubscriptionService.isAdsRemoved;
  
  // 問題の制限チェック
  static List<Question> filterQuestionsForUser(List<Question> allQuestions) {
    if (hasPremiumAccess) {
      // プレミアムユーザーは全問題にアクセス可能
      return allQuestions;
    }
    
    // 無料ユーザーは制限された問題のみ
    return _getFreeQuestions(allQuestions);
  }
  
  // 無料問題の取得
  static List<Question> _getFreeQuestions(List<Question> allQuestions) {
    final Map<String, List<Question>> questionsByTag = {};
    
    // カテゴリ別に問題を分類
    for (final question in allQuestions) {
      questionsByTag.putIfAbsent(question.tag, () => []);
      questionsByTag[question.tag]!.add(question);
    }
    
    final List<Question> freeQuestions = [];
    
    // 各カテゴリから制限数分の問題を取得
    for (final entry in questionsByTag.entries) {
      final String tag = entry.key;
      final List<Question> questions = entry.value;
      
      int limit = _freeQuestionsPerCategory;
      
      // リスニング問題は特別扱い
      if (tag == 'listening') {
        limit = _freeListeningQuestions;
      }
      
      // 制限数分の問題を追加
      final List<Question> limitedQuestions = questions.take(limit).toList();
      freeQuestions.addAll(limitedQuestions);
    }
    
    return freeQuestions;
  }
  
  // 特定の問題にアクセス可能かチェック
  static bool canAccessQuestion(Question question) {
    if (hasPremiumAccess) {
      return true;
    }
    
    // 無料版の制限チェック
    return _isQuestionInFreeTier(question);
  }
  
  // 問題が無料層に含まれるかチェック
  static bool _isQuestionInFreeTier(Question question) {
    // 実際の実装では、問題IDや順序に基づいて判定
    // ここでは簡易的に問題IDで判定
    final int questionId = question.id;
    
    switch (question.tag) {
      case 'grammar':
      case 'vocabulary':
      case 'reading':
        return questionId <= _freeQuestionsPerCategory;
      case 'listening':
        return questionId <= _freeListeningQuestions;
      default:
        return false;
    }
  }
  
  // 広告表示の制御
  static bool shouldShowAds() {
    return !hasAdsRemoved;
  }
  
  // プレミアム機能の説明
  static String getPremiumFeaturesDescription() {
    return '''
🎯 プレミアム機能

✅ 全問題パック（638問）
✅ リスニング問題フル解放
✅ 広告完全削除
✅ 詳細な学習分析
✅ 苦手分野の自動出題
✅ 学習進捗の可視化
✅ カスタム学習プラン
    ''';
  }
  
  // 無料版の制限説明
  static String getFreeVersionLimitations() {
    return '''
📱 無料版の制限

• 文法問題: 25問
• 語彙問題: 25問  
• 読解問題: 25問
• リスニング問題: 10問
• 広告表示あり
• 基本機能のみ
    ''';
  }
}

