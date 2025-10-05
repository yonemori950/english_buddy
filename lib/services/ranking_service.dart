import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class RankingService {
  static FirebaseFirestore? get _firestore => FirebaseService.firestore;

  // スコアランキングを取得
  static Future<List<Map<String, dynamic>>> getScoreRanking({int limit = 10}) async {
    try {
      if (_firestore == null) {
        print('Firebase Firestore not available');
        return [];
      }
      
      final QuerySnapshot snapshot = await _firestore!
          .collection('users')
          .orderBy('exp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'name': data['name'] ?? '匿名ユーザー',
          'score': data['exp'] ?? 0,
          'level': data['level'] ?? 1,
          'updated': data['updated'],
        };
      }).toList();
    } catch (e) {
      print('Error getting ranking: $e');
      return [];
    }
  }

  // ユーザーの順位を取得
  static Future<int> getUserRank(String uid) async {
    try {
      final QuerySnapshot snapshot = await _firestore!
          .collection('users')
          .orderBy('exp', descending: true)
          .get();

      int rank = 1;
      for (final doc in snapshot.docs) {
        if (doc.id == uid) {
          return rank;
        }
        rank++;
      }
      return -1; // ユーザーが見つからない場合
    } catch (e) {
      print('Error getting user rank: $e');
      return -1;
    }
  }

  // ランキングデータを更新
  static Future<void> updateRanking(String uid, String name, int score, int level) async {
    try {
      await _firestore!.collection('scores').doc(uid).set({
        'uid': uid,
        'name': name,
        'score': score,
        'level': level,
        'updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating ranking: $e');
    }
  }

  // 週間ランキングを取得
  static Future<List<Map<String, dynamic>>> getWeeklyRanking({int limit = 10}) async {
    try {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final QuerySnapshot snapshot = await _firestore!
          .collection('users')
          .where('updated', isGreaterThan: weekAgo.toIso8601String())
          .orderBy('updated')
          .orderBy('exp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'name': data['name'] ?? '匿名ユーザー',
          'score': data['exp'] ?? 0,
          'level': data['level'] ?? 1,
          'updated': data['updated'],
        };
      }).toList();
    } catch (e) {
      print('Error getting weekly ranking: $e');
      return [];
    }
  }

  // 月間ランキングを取得
  static Future<List<Map<String, dynamic>>> getMonthlyRanking({int limit = 10}) async {
    try {
      final monthAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final QuerySnapshot snapshot = await _firestore!
          .collection('users')
          .where('updated', isGreaterThan: monthAgo.toIso8601String())
          .orderBy('updated')
          .orderBy('exp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'name': data['name'] ?? '匿名ユーザー',
          'score': data['exp'] ?? 0,
          'level': data['level'] ?? 1,
          'updated': data['updated'],
        };
      }).toList();
    } catch (e) {
      print('Error getting monthly ranking: $e');
      return [];
    }
  }
}
