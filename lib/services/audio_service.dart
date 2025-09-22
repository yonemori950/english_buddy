import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> playAudio(String audioPath) async {
    try {
      if (_isPlaying) {
        await stopAudio();
      }
      
      _isPlaying = true;
      await _audioPlayer.play(AssetSource(audioPath));
      
      // 再生完了を監視
      _audioPlayer.onPlayerComplete.listen((event) {
        _isPlaying = false;
      });
      
    } catch (e) {
      print('Error playing audio: $e');
      _isPlaying = false;
    }
  }

  static Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  static Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  static Future<void> resumeAudio() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      print('Error resuming audio: $e');
    }
  }

  static bool get isPlaying => _isPlaying;

  static Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}

