import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._();
  AudioManager._();

  // Minimal silent WAV (48 bytes): 2 samples, 44100 Hz, 16-bit, mono
  static final _silentWav = [
    0x52, 0x49, 0x46, 0x46, 0x28, 0x00, 0x00, 0x00,
    0x57, 0x41, 0x56, 0x45,
    0x66, 0x6D, 0x74, 0x20, 0x10, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x01, 0x00,
    0x44, 0xAC, 0x00, 0x00, 0x88, 0x58, 0x01, 0x00,
    0x02, 0x00, 0x10, 0x00,
    0x64, 0x61, 0x74, 0x61, 0x04, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
  ];

  AudioPlayer? _bgmPlayer;

  Future<void> playBgm(String filename) async {
    try {
      await stopBgm();
      Uint8List bytes;
      String? mimeType;
      try {
        final data = await rootBundle.load('audio/$filename');
        bytes = data.buffer.asUint8List();
      } catch (_) {
        bytes = Uint8List.fromList(_silentWav);
        mimeType = 'audio/wav';
      }
      _bgmPlayer = AudioPlayer();
      _bgmPlayer!.eventStream.listen((_) {}, onError: (_) {}, cancelOnError: false);
      await _bgmPlayer!.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer!.setVolume(0.5);
      await _bgmPlayer!.play(BytesSource(bytes, mimeType: mimeType));
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
      Uint8List bytes;
      String? mimeType;
      try {
        final data = await rootBundle.load('audio/$filename');
        bytes = data.buffer.asUint8List();
      } catch (_) {
        bytes = Uint8List.fromList(_silentWav);
        mimeType = 'audio/wav';
      }
      final p = AudioPlayer();
      p.eventStream.listen((_) {}, onError: (_) {}, cancelOnError: false);
      await p.play(BytesSource(bytes, mimeType: mimeType));
      p.onPlayerComplete.listen((_) => p.dispose());
    } catch (_) {}
  }
}
