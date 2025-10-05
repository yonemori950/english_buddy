import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool _isInitializing = false;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Wait for ongoing initialization to complete
      while (_isInitializing && !_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    
    _isInitializing = true;
    
    try {
      print('Initializing Firebase...');
      await Firebase.initializeApp();
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      
      print('Firebase initialized successfully');
      _isInitialized = true;
    } catch (e) {
      print('Firebase initialization failed: $e');
      // Firebase初期化に失敗してもアプリは動作するようにする
      print('Continuing without Firebase...');
    } finally {
      _isInitializing = false;
    }
  }

  static FirebaseAuth? get auth {
    if (!_isInitialized || _auth == null) {
      print('Firebase Auth not available');
      return null;
    }
    return _auth;
  }

  static FirebaseFirestore? get firestore {
    if (!_isInitialized || _firestore == null) {
      print('Firebase Firestore not available');
      return null;
    }
    return _firestore;
  }

  static FirebaseStorage? get storage {
    if (!_isInitialized || _storage == null) {
      print('Firebase Storage not available');
      return null;
    }
    return _storage;
  }

  static bool get isInitialized => _isInitialized;
}
