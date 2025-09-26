import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class AudioPlayerButton extends StatefulWidget {
  final String? audioPath;
  final String? textToSpeak;
  final double size;
  final Color? color;

  const AudioPlayerButton({
    super.key,
    this.audioPath,
    this.textToSpeak,
    this.size = 48.0,
    this.color,
  });

  @override
  State<AudioPlayerButton> createState() => _AudioPlayerButtonState();
}

class _AudioPlayerButtonState extends State<AudioPlayerButton>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (widget.audioPath == null && widget.textToSpeak == null) {
      _showNoAudioDialog();
      return;
    }

    if (_isPlaying) {
      // 停止
      setState(() {
        _isPlaying = false;
      });
      _animationController.stop();
      _animationController.reset();
      await AudioService.stopAudio();
    } else {
      // 再生開始
      setState(() {
        _isPlaying = true;
      });
      _animationController.repeat(reverse: true);
      
      // 音声ファイルまたはTTSで再生
      await AudioService.playAudioOrSpeak(widget.audioPath, widget.textToSpeak);
      
      // 再生完了を監視
      _monitorPlayback();
    }
  }

  void _monitorPlayback() {
    // 定期的に再生状態をチェック
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !AudioService.isPlaying && _isPlaying) {
        setState(() {
          _isPlaying = false;
        });
        _animationController.stop();
        _animationController.reset();
      }
    });
  }

  void _showNoAudioDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('音声なし'),
        content: const Text('この問題には音声ファイルもテキストもありません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPlaying ? _animation.value : 1.0,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color ?? Colors.blue[600],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(widget.size / 2),
                onTap: _toggleAudio,
                child: Icon(
                  _isPlaying ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: widget.size * 0.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

