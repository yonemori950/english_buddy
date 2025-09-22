import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart' as app_user;
import 'firebase_service.dart';
import 'ranking_service.dart';

class UserService {
  static final FirebaseAuth _auth = FirebaseService.auth;
  static final FirebaseFirestore _firestore = FirebaseService.firestore;

  // 匿名ログイン
  static Future<app_user.User?> signInAnonymously() async {
    try {
      final UserCredential userCredential = await _auth.signInAnonymously();
      final User? user = userCredential.user;
      
      if (user != null) {
        // ユーザーデータをFirestoreに保存
        final app_user.User appUser = app_user.User(
          uid: user.uid,
          name: '匿名ユーザー',
          level: 1,
          exp: 0,
          scores: {
            'grammar': {'correct': 0, 'wrong': 0},
            'vocabulary': {'correct': 0, 'wrong': 0},
            'reading': {'correct': 0, 'wrong': 0},
            'listening': {'correct': 0, 'wrong': 0},
          },
          updated: DateTime.now(),
        );
        
        await _firestore.collection('users').doc(user.uid).set(appUser.toJson());
        return appUser;
      }
      return null;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return null;
    }
  }

  // ユーザーデータを取得
  static Future<app_user.User?> getUserData(String uid) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return app_user.User.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // ユーザーデータを更新
  static Future<void> updateUserData(app_user.User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toJson());
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  // スコアを更新
  static Future<void> updateScore(String uid, String tag, bool isCorrect) async {
    try {
      final DocumentReference userRef = _firestore.collection('users').doc(uid);
      final DocumentSnapshot doc = await userRef.get();
      
      if (doc.exists) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final Map<String, Map<String, int>> scores = Map<String, Map<String, int>>.from(
          data['scores'].map(
            (key, value) => MapEntry(
              key,
              Map<String, int>.from(value),
            ),
          ),
        );
        
        if (scores.containsKey(tag)) {
          if (isCorrect) {
            scores[tag]!['correct'] = (scores[tag]!['correct'] ?? 0) + 1;
          } else {
            scores[tag]!['wrong'] = (scores[tag]!['wrong'] ?? 0) + 1;
          }
        }
        
        // 経験値とレベルを計算
        int totalCorrect = scores.values.fold(0, (sum, tagScores) => sum + (tagScores['correct'] ?? 0));
        int newExp = totalCorrect * 10;
        int newLevel = (newExp / 100).floor() + 1;
        
        await userRef.update({
          'scores': scores,
          'exp': newExp,
          'level': newLevel,
          'updated': DateTime.now().toIso8601String(),
        });

        // ランキングも更新
        await RankingService.updateRanking(uid, data['name'] ?? '匿名ユーザー', newExp, newLevel);
      }
    } catch (e) {
      print('Error updating score: $e');
    }
  }

  // 現在のユーザーを取得
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ログアウト
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
