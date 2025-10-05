import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  // 音声ファイルのパス
  static const String _correctSoundPath = 'sounds/correct.mp3';
  static const String _incorrectSoundPath = 'sounds/beep4.mp3';
  static const String _startSoundPath = 'sounds/start.mp3';
  
  // 音声の有効/無効状態
  static bool _isSoundEnabled = true;
  
  static bool get isSoundEnabled => _isSoundEnabled;
  
  // 音声の有効/無効を切り替え
  static Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', enabled);
  }
  
  // 音声設定を読み込み
  static Future<void> loadSoundSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
  }
  
  // 正解音を再生
  static Future<void> playCorrectSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource(_correctSoundPath));
    } catch (e) {
      print('Failed to play correct sound: $e');
    }
  }
  
  // 不正解音を再生
  static Future<void> playIncorrectSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource(_incorrectSoundPath));
    } catch (e) {
      print('Failed to play incorrect sound: $e');
    }
  }
  
  // スタート音を再生
  static Future<void> playStartSound() async {
    if (!_isSoundEnabled) return;
    
    try {
      await _audioPlayer.play(AssetSource(_startSoundPath));
    } catch (e) {
      print('Failed to play start sound: $e');
    }
  }
  
  // 音声を停止
  static Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Failed to stop sound: $e');
    }
  }
  
  // リソースの解放
  static void dispose() {
    _audioPlayer.dispose();
  }
}
