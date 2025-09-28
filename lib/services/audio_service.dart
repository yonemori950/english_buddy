import 'package:audioplayers/audioplayers.dart';
import 'tts_service.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isPlaying = false;

  static Future<void> playAudio(String audioPath) async {
    try {
      if (_isPlaying) {
        await stopAudio();
      }
      
      _isPlaying = true;
      // 音声ファイルのパスを正しく設定
      final fullPath = 'audio/$audioPath';
      print('Playing audio: $fullPath');
      await _audioPlayer.play(AssetSource(fullPath));
      
      // 再生完了を監視
      _audioPlayer.onPlayerComplete.listen((event) {
        _isPlaying = false;
      });
      
    } catch (e) {
      print('Error playing audio: $e');
      _isPlaying = false;
      rethrow; // エラーを再スローしてフォールバック処理を可能にする
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

  // TTSでテキストを音声化
  static Future<void> speakText(String text) async {
    try {
      if (_isPlaying) {
        await stopAudio();
      }
      
      _isPlaying = true;
      await TTSService.speak(text);
      
      // TTSの再生状態を監視
      _monitorTTSStatus();
      
    } catch (e) {
      print('Error speaking text: $e');
      _isPlaying = false;
    }
  }

  // TTSの再生状態を監視
  static void _monitorTTSStatus() {
    // 定期的にTTSの状態をチェック
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!TTSService.isPlaying && _isPlaying) {
        _isPlaying = false;
      }
    });
  }

  // 音声ファイルまたはTTSで再生
  static Future<void> playAudioOrSpeak(String? audioPath, String? text) async {
    if (audioPath != null && audioPath.isNotEmpty) {
      // 存在する音声ファイルのリスト（1-45まで）
      final existingAudioFiles = [
        'listening_q1.mp3', 'listening_q2.mp3', 'listening_q3.mp3', 'listening_q4.mp3', 'listening_q5.mp3',
        'listening_q6.mp3', 'listening_q7.mp3', 'listening_q8.mp3', 'listening_q9.mp3', 'listening_q10.mp3',
        'listening_q11.mp3', 'listening_q12.mp3', 'listening_q13.mp3', 'listening_q14.mp3', 'listening_q15.mp3',
        'listening_q16.mp3', 'listening_q17.mp3', 'listening_q18.mp3', 'listening_q19.mp3', 'listening_q20.mp3',
        'listening_q21.mp3', 'listening_q22.mp3', 'listening_q23.mp3', 'listening_q24.mp3', 'listening_q25.mp3',
        'listening_q26.mp3', 'listening_q27.mp3', 'listening_q28.mp3', 'listening_q29.mp3', 'listening_q30.mp3',
        'listening_q31.mp3', 'listening_q32.mp3', 'listening_q33.mp3', 'listening_q34.mp3', 'listening_q35.mp3',
        'listening_q36.mp3', 'listening_q37.mp3', 'listening_q38.mp3', 'listening_q39.mp3', 'listening_q40.mp3',
        'listening_q41.mp3', 'listening_q42.mp3', 'listening_q43.mp3', 'listening_q44.mp3', 'listening_q45.mp3',
      ];
      
      if (existingAudioFiles.contains(audioPath)) {
        try {
          // 音声ファイルが存在する場合はファイルを再生
          print('Playing existing audio file: $audioPath');
          await playAudio(audioPath);
        } catch (e) {
          print('Error playing audio file, falling back to TTS: $e');
          // 音声ファイルの再生に失敗した場合はTTSで再生
          if (text != null && text.isNotEmpty) {
            await speakText(text);
          }
        }
      } else {
        // 音声ファイルが存在しない場合はTTSで再生
        print('Audio file $audioPath not found, using TTS for: $text');
        if (text != null && text.isNotEmpty) {
          await speakText(text);
        } else {
          print('No text provided for TTS fallback');
        }
      }
    } else if (text != null && text.isNotEmpty) {
      // 音声ファイルがない場合はTTSで再生
      print('No audio path provided, using TTS for: $text');
      await speakText(text);
    }
  }

  static Future<void> dispose() async {
    await _audioPlayer.dispose();
    await TTSService.dispose();
  }
}

