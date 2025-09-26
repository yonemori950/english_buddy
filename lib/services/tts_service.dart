import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isPlaying = false;

  // TTSを初期化
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 利用可能な言語を確認
      final languages = await _flutterTts.getLanguages;
      print('Available TTS languages: $languages');
      
      // 言語設定（英語）
      await _flutterTts.setLanguage("en-US");
      
      // 音声設定
      await _flutterTts.setSpeechRate(0.5); // 少しゆっくりめ
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // 音声完了時のコールバック
      _flutterTts.setCompletionHandler(() {
        print('TTS completed');
        _isPlaying = false;
      });
      
      // エラー時のコールバック
      _flutterTts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        _isPlaying = false;
      });
      
      // 開始時のコールバック
      _flutterTts.setStartHandler(() {
        print('TTS started');
        _isPlaying = true;
      });
      
      _isInitialized = true;
      print('TTS initialized successfully');
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  // テキストを音声で再生
  static Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (_isPlaying) {
        await stop();
      }
      
      print('TTS speaking: $text');
      _isPlaying = true;
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking text: $e');
      _isPlaying = false;
    }
  }

  // 音声を停止
  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error stopping TTS: $e');
    }
  }

  // 音声を一時停止
  static Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      print('Error pausing TTS: $e');
    }
  }

  // 音声を再開（flutter_ttsではresumeメソッドが利用できないため削除）
  // static Future<void> resume() async {
  //   try {
  //     await _flutterTts.resume();
  //   } catch (e) {
  //     print('Error resuming TTS: $e');
  //   }
  // }

  // 再生中かどうか
  static bool get isPlaying => _isPlaying;

  // 利用可能な言語を取得
  static Future<List<dynamic>> getLanguages() async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      print('Error getting languages: $e');
      return [];
    }
  }

  // 利用可能な音声を取得
  static Future<List<dynamic>> getVoices() async {
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      print('Error getting voices: $e');
      return [];
    }
  }

  // 音声設定を変更
  static Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      print('Error setting speech rate: $e');
    }
  }

  // 音量を変更
  static Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  // 音程を変更
  static Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      print('Error setting pitch: $e');
    }
  }

  // 言語を変更
  static Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      print('Error setting language: $e');
    }
  }

  // リソースを解放
  static Future<void> dispose() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error disposing TTS: $e');
    }
  }
}
