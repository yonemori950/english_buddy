class QuizResult {
  final int correctAnswers;
  final int totalQuestions;
  final int score;
  final int expGained;
  final Map<String, int> tagResults;
  final DateTime completedAt;

  QuizResult({
    required this.correctAnswers,
    required this.totalQuestions,
    required this.score,
    required this.expGained,
    required this.tagResults,
    required this.completedAt,
  });

  double get accuracy => totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'score': score,
      'expGained': expGained,
      'tagResults': tagResults,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      correctAnswers: json['correctAnswers'],
      totalQuestions: json['totalQuestions'],
      score: json['score'],
      expGained: json['expGained'],
      tagResults: Map<String, int>.from(json['tagResults']),
      completedAt: DateTime.parse(json['completedAt']),
    );
  }
}
