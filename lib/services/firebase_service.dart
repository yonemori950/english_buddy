import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;
  static FirebaseStorage? _storage;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Firebase.initializeApp();
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
    
    _isInitialized = true;
  }

  static FirebaseAuth get auth {
    if (!_isInitialized || _auth == null) {
      throw Exception('Firebase not initialized');
    }
    return _auth!;
  }

  static FirebaseFirestore get firestore {
    if (!_isInitialized || _firestore == null) {
      throw Exception('Firebase not initialized');
    }
    return _firestore!;
  }

  static FirebaseStorage get storage {
    if (!_isInitialized || _storage == null) {
      throw Exception('Firebase not initialized');
    }
    return _storage!;
  }

  static bool get isInitialized => _isInitialized;
}
