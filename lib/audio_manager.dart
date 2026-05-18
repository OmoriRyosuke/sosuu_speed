import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._();
  AudioManager._();

  AudioPlayer? _bgmPlayer;

  Future<void> playBgm(String filename) async {
    try {
      await stopBgm();
      _bgmPlayer = AudioPlayer();
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(0.5);
      await _bgmPlayer!.play(AssetSource('audio/$filename'));
    } catch (_) {}
  }

  Future<void> stopBgm() async {
    try {
      await _bgmPlayer?.stop();
      await _bgmPlayer?.dispose();
    } catch (_) {}
    _bgmPlayer = null;
  }

  Future<void> playSe(String filename) async {
    try {
      final p = AudioPlayer();
      await p.play(AssetSource('audio/$filename'));
      p.onPlayerComplete.listen((_) => p.dispose());
    } catch (_) {}
  }
}
