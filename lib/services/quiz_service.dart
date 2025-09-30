import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/question.dart';

class QuizService {
  static List<Question> _questions = [];
  static bool _isLoaded = false;

  static Future<List<Question>> loadQuestions() async {
    if (_isLoaded) return _questions;

    try {
      final String jsonString = await rootBundle.loadString('assets/questions.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _questions = jsonList.map((json) => Question.fromJson(json)).toList();
      _isLoaded = true;
      
      return _questions;
    } catch (e) {
      print('Error loading questions: $e');
      return [];
    }
  }

  static List<Question> getQuestionsByTag(String tag) {
    return _questions.where((q) => q.tag == tag).toList();
  }

  static List<Question> getRandomQuestions(int count) {
    if (_questions.isEmpty) return [];
    
    final shuffled = List<Question>.from(_questions)..shuffle();
    return shuffled.take(count).toList();
  }

  static List<Question> getRandomQuestionsFromList(List<Question> questionList, int count) {
    if (questionList.isEmpty) return [];
    
    final shuffled = List<Question>.from(questionList)..shuffle();
    return shuffled.take(count).toList();
  }

  static List<Question> getWeaknessQuestions(List<String> weakTags, int count) {
    if (_questions.isEmpty) return [];
    
    final weaknessQuestions = <Question>[];
    for (final tag in weakTags) {
      final tagQuestions = getQuestionsByTag(tag);
      weaknessQuestions.addAll(tagQuestions);
    }
    
    weaknessQuestions.shuffle();
    return weaknessQuestions.take(count).toList();
  }

  static List<String> getAllTags() {
    return _questions.map((q) => q.tag).toSet().toList();
  }
}
