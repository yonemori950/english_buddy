import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart' as app_user;
import 'firebase_service.dart';
import 'ranking_service.dart';

class UserService {
  static FirebaseAuth? get _auth => FirebaseService.auth;
  static FirebaseFirestore? get _firestore => FirebaseService.firestore;
  
  // Google Sign-In インスタンス
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // 匿名ログイン
  static Future<app_user.User?> signInAnonymously() async {
    try {
      if (_auth == null) {
        print('Firebase Auth not available');
        return null;
      }
      
      final UserCredential userCredential = await _auth!.signInAnonymously();
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
        
        if (_firestore != null) {
          await _firestore!.collection('users').doc(user.uid).set(appUser.toJson());
        }
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
      if (_firestore == null) {
        print('Firebase Firestore not available');
        return null;
      }
      
      final DocumentSnapshot doc = await _firestore!.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return app_user.User.fromJson(data);
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
      if (_firestore == null) {
        print('Firebase Firestore not available');
        return;
      }
      
      await _firestore!.collection('users').doc(user.uid).update(user.toJson());
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  // ユーザー名を更新
  static Future<void> updateUserName(String uid, String newName) async {
    try {
      if (_firestore == null) {
        print('Firebase Firestore not available');
        return;
      }
      
      await _firestore!.collection('users').doc(uid).update({
        'name': newName,
        'updated': DateTime.now().toIso8601String(),
      });
      
      // ランキングの名前も更新
      final doc = await _firestore!.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        await RankingService.updateRanking(uid, newName, data['exp'] ?? 0, data['level'] ?? 1);
      }
    } catch (e) {
      print('Error updating user name: $e');
      throw e;
    }
  }

  // スコアを更新
  static Future<void> updateScore(String uid, String tag, bool isCorrect) async {
    try {
      if (_firestore == null) {
        print('Firebase Firestore not available');
        return;
      }
      
      final DocumentReference userRef = _firestore!.collection('users').doc(uid);
      final DocumentSnapshot doc = await userRef.get();
      
      if (doc.exists) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final Map<String, Map<String, int>> scores = Map<String, Map<String, int>>.from(
          (data['scores'] as Map).map(
            (key, value) => MapEntry(
              key as String,
              Map<String, int>.from(value as Map),
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
    return _auth?.currentUser;
  }

  // Googleログイン
  static Future<app_user.User?> signInWithGoogle() async {
    try {
      if (_auth == null) {
        print('Firebase Auth not available');
        return null;
      }

      // Googleアカウントを選択
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google sign-in cancelled');
        return null;
      }

      // 認証情報を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase用に変換
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebaseにログイン
      final UserCredential userCredential = await _auth!.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // ユーザーデータをFirestoreに保存または更新
        final app_user.User appUser = app_user.User(
          uid: user.uid,
          name: user.displayName ?? 'Googleユーザー',
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

        if (_firestore != null) {
          // 既存のデータがあるかチェック
          final DocumentSnapshot doc = await _firestore!.collection('users').doc(user.uid).get();
          if (!doc.exists) {
            // 新規ユーザーの場合のみデータを作成
            await _firestore!.collection('users').doc(user.uid).set(appUser.toJson());
          }
        }
        return appUser;
      }
      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // ゲストアカウントをGoogleアカウントにリンク
  static Future<app_user.User?> linkGuestToGoogle() async {
    try {
      if (_auth == null) {
        print('Firebase Auth not available');
        return null;
      }

      final User? currentUser = _auth!.currentUser;
      if (currentUser == null || !currentUser.isAnonymous) {
        print('Current user is not anonymous');
        return null;
      }

      // Googleアカウントを選択
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google sign-in cancelled');
        return null;
      }

      // 認証情報を取得
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase用に変換
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // アカウントリンク
      final UserCredential result = await currentUser.linkWithCredential(credential);
      final User? linkedUser = result.user;

      if (linkedUser != null) {
        print('Guest account linked to Google: ${linkedUser.uid}');
        
        // ユーザー名をGoogleアカウントの名前に更新
        if (_firestore != null) {
          await _firestore!.collection('users').doc(linkedUser.uid).update({
            'name': linkedUser.displayName ?? 'Googleユーザー',
            'updated': DateTime.now().toIso8601String(),
          });
        }

        // 更新されたユーザーデータを取得
        return await getUserData(linkedUser.uid);
      }
      return null;
    } catch (e) {
      print('Error linking guest to Google: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'credential-already-in-use') {
          print('Google account is already linked to another user');
          throw Exception('このGoogleアカウントは既に別のアカウントにリンクされています');
        } else if (e.code == 'email-already-in-use') {
          print('Email is already in use');
          throw Exception('このメールアドレスは既に使用されています');
        }
      }
      throw e;
    }
  }

  // 現在のユーザーがゲストかどうかチェック
  static bool isCurrentUserGuest() {
    final User? user = _auth?.currentUser;
    return user?.isAnonymous ?? false;
  }

  // メールリンクログイン - メールリンクを送信
  static Future<bool> sendSignInLinkToEmail(String email) async {
    try {
      if (_auth == null) {
        print('Firebase Auth not available');
        return false;
      }

      final ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        url: 'https://englishbuddy.page.link/login',
        handleCodeInApp: true,
        androidPackageName: 'com.gamelab.englishBuddy',
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: 'com.gamelab.englishBuddy',
      );

      await _auth!.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      print('Sign-in link sent to: $email');
      return true;
    } catch (e) {
      print('Error sending sign-in link: $e');
      return false;
    }
  }

  // メールリンクログイン - リンクでサインイン
  static Future<app_user.User?> signInWithEmailLink(String email, String link) async {
    try {
      if (_auth == null) {
        print('Firebase Auth not available');
        return null;
      }

      final UserCredential userCredential = await _auth!.signInWithEmailLink(
        email: email,
        emailLink: link,
      );
      final User? user = userCredential.user;

      if (user != null) {
        // ユーザーデータをFirestoreに保存または更新
        final app_user.User appUser = app_user.User(
          uid: user.uid,
          name: user.displayName ?? user.email?.split('@')[0] ?? 'メールユーザー',
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

        if (_firestore != null) {
          // 既存のデータがあるかチェック
          final DocumentSnapshot doc = await _firestore!.collection('users').doc(user.uid).get();
          if (!doc.exists) {
            // 新規ユーザーの場合のみデータを作成
            await _firestore!.collection('users').doc(user.uid).set(appUser.toJson());
          }
        }
        return appUser;
      }
      return null;
    } catch (e) {
      print('Error signing in with email link: $e');
      return null;
    }
  }

  // ゲストアカウントをメールアカウントにリンク
  static Future<app_user.User?> linkGuestToEmail(String email, String link) async {
    try {
      if (_auth == null) {
        print('Firebase Auth not available');
        return null;
      }

      final User? currentUser = _auth!.currentUser;
      if (currentUser == null || !currentUser.isAnonymous) {
        print('Current user is not anonymous');
        return null;
      }

      // メールリンクでアカウントリンク（EmailAuthProviderを使用）
      final AuthCredential credential = EmailAuthProvider.credentialWithLink(
        email: email,
        emailLink: link,
      );
      
      final UserCredential result = await currentUser.linkWithCredential(credential);
      final User? linkedUser = result.user;

      if (linkedUser != null) {
        print('Guest account linked to email: ${linkedUser.uid}');
        
        // ユーザー名をメールアドレスから更新
        if (_firestore != null) {
          await _firestore!.collection('users').doc(linkedUser.uid).update({
            'name': linkedUser.email?.split('@')[0] ?? 'メールユーザー',
            'updated': DateTime.now().toIso8601String(),
          });
        }

        // 更新されたユーザーデータを取得
        return await getUserData(linkedUser.uid);
      }
      return null;
    } catch (e) {
      print('Error linking guest to email: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'credential-already-in-use') {
          print('Email account is already linked to another user');
          throw Exception('このメールアドレスは既に別のアカウントにリンクされています');
        } else if (e.code == 'email-already-in-use') {
          print('Email is already in use');
          throw Exception('このメールアドレスは既に使用されています');
        }
      }
      throw e;
    }
  }

  // メールリンクが有効かチェック
  static bool isSignInWithEmailLink(String link) {
    if (_auth == null) return false;
    return _auth!.isSignInWithEmailLink(link);
  }

  // ログアウト
  static Future<void> signOut() async {
    await _auth?.signOut();
    await _googleSignIn.signOut();
  }
}
