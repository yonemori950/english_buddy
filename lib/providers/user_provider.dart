import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart' as app_user;
import '../services/user_service.dart';
import '../services/notification_service.dart';

class UserProvider with ChangeNotifier {
  app_user.User? _currentUser;
  bool _isLoading = true;
  String? _error;

  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ユーザー認証状態を監視
  void initAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        // ユーザーがログインしている場合
        await _loadUserData(user.uid);
        // 非アクティブ通知をキャンセル
        await NotificationService.cancelInactivityReminder();
      } else {
        // ユーザーがログアウトしている場合
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // ユーザーデータを読み込み
  Future<void> _loadUserData(String uid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userData = await UserService.getUserData(uid);
      if (userData != null) {
        _currentUser = userData;
      } else {
        _error = 'ユーザーデータの読み込みに失敗しました';
      }
    } catch (e) {
      _error = 'エラーが発生しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 匿名ログイン
  Future<bool> signInAnonymously() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await UserService.signInAnonymously();
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'ログインに失敗しました';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'ログインエラー: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // スコアを更新
  Future<void> updateScore(String tag, bool isCorrect) async {
    if (_currentUser == null) return;

    try {
      await UserService.updateScore(_currentUser!.uid, tag, isCorrect);
      // ユーザーデータを再読み込み
      await _loadUserData(_currentUser!.uid);
      // 励まし通知を表示
      await NotificationService.showEncouragementNotification();
    } catch (e) {
      _error = 'スコア更新エラー: $e';
      notifyListeners();
    }
  }

  // ログアウト
  Future<void> signOut() async {
    try {
      await UserService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _error = 'ログアウトエラー: $e';
      notifyListeners();
    }
  }

  // エラーをクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
