import 'dart:convert';
import 'package:flutter/services.dart';

class Explanation {
  final int id;
  final String question;
  final String explanation;

  Explanation({
    required this.id,
    required this.question,
    required this.explanation,
  });

  factory Explanation.fromJson(Map<String, dynamic> json) {
    return Explanation(
      id: json['id'],
      question: json['question'],
      explanation: json['explanation'],
    );
  }
}

class ExplanationService {
  static List<Explanation> _explanations = [];
  static bool _isLoaded = false;

  // 解説データを読み込み
  static Future<void> loadExplanations() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/explanations.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _explanations = jsonList.map((json) => Explanation.fromJson(json)).toList();
      _isLoaded = true;
      
      print('Loaded ${_explanations.length} explanations');
    } catch (e) {
      print('Error loading explanations: $e');
    }
  }

  // IDで解説を取得
  static Explanation? getExplanationById(int id) {
    try {
      return _explanations.firstWhere((exp) => exp.id == id);
    } catch (e) {
      print('Explanation not found for ID: $id');
      return null;
    }
  }

  // 問題文で解説を検索
  static Explanation? getExplanationByQuestion(String question) {
    try {
      return _explanations.firstWhere((exp) => 
        exp.question.toLowerCase().contains(question.toLowerCase()) ||
        question.toLowerCase().contains(exp.question.toLowerCase())
      );
    } catch (e) {
      print('Explanation not found for question: $question');
      return null;
    }
  }

  // すべての解説を取得
  static List<Explanation> getAllExplanations() {
    return List.from(_explanations);
  }

  // 解説が読み込まれているかチェック
  static bool get isLoaded => _isLoaded;
}
