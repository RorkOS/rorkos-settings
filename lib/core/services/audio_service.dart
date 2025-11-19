import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  double _volume = 0.7;

  double get volume => _volume;
  bool get isPlaying => _isPlaying;

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
  }

  Future<void> playTestSound() async {
    try {
      await _audioPlayer.play(DeviceFileSource('/usr/share/sounds/gnome/default/alerts/bark.ogg'));
      _isPlaying = true;
    } catch (e) {
      await _audioPlayer.play(UrlSource('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'));
      _isPlaying = true;
    }
  }

  Future<void> stopSound() async {
    await _audioPlayer.stop();
    _isPlaying = false;
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
