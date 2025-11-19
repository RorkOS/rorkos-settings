import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../../core/providers/settings_provider.dart';

class SoundSettingsPage extends StatefulWidget {
  const SoundSettingsPage({super.key});

  @override
  State<SoundSettingsPage> createState() => _SoundSettingsPageState();
}

class _SoundSettingsPageState extends State<SoundSettingsPage> {
  final List<String> _outputDevices = [
    'Встроенный аудио',
    'HDMI',
    'USB-наушники',
    'Bluetooth-колонка'
  ];
  final List<String> _inputDevices = [
    'Встроенный микрофон',
    'USB-микрофон',
    'Bluetooth-гарнитура'
  ];

  String _selectedOutput = 'Встроенный аудио';
  String _selectedInput = 'Встроенный микрофон';
  double _notificationVolume = 0.5;
  double _systemVolume = 0.8;

  Future<void> _playTestSound() async {
    try {
      // Пробуем разные команды для воспроизведения звука
      final ProcessResult result1 = await Process.run('paplay', ['/usr/share/sounds/freedesktop/stereo/message.ogg']);
      if (result1.exitCode != 0) {
        final ProcessResult result2 = await Process.run('aplay', ['/usr/share/sounds/alsa/Front_Left.wav']);
        if (result2.exitCode != 0) {
          await Process.run('speaker-test', ['-t', 'sine', '-f', '1000', '-l', '1']);
        }
      }
    } catch (e) {
      print('Ошибка воспроизведения звука: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось воспроизвести тестовый звук. Проверьте аудиосистему.')),
      );
    }
  }

  Future<void> _setSystemVolume(double volume) async {
    try {
      final int volumePercent = (volume * 100).round();
      final ProcessResult result1 = await Process.run('amixer', ['-D', 'pulse', 'sset', 'Master', '$volumePercent%']);
      if (result1.exitCode != 0) {
        await Process.run('pactl', ['set-sink-volume', '@DEFAULT_SINK@', '$volumePercent%']);
      }
    } catch (e) {
      print('Ошибка установки громкости: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Звук'),
      ),
      body: ListView(
        children: [
          _VolumeSection(
            title: 'Микшер громкости',
            children: [
              _VolumeSlider(
                title: 'Основная громкость',
                value: settingsProvider.masterVolume,
                onChanged: (value) {
                  settingsProvider.setMasterVolume(value);
                  _setSystemVolume(value);
                },
                onTest: _playTestSound,
              ),
              _VolumeSlider(
                title: 'Громкость уведомлений',
                value: _notificationVolume,
                onChanged: (value) {
                  setState(() {
                    _notificationVolume = value;
                  });
                },
              ),
              _VolumeSlider(
                title: 'Системные звуки',
                value: _systemVolume,
                onChanged: (value) {
                  setState(() {
                    _systemVolume = value;
                  });
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Устройства вывода',
            children: [
              _DropdownSetting(
                title: 'Выходное устройство',
                value: _selectedOutput,
                options: _outputDevices,
                onChanged: (value) {
                  setState(() {
                    _selectedOutput = value!;
                  });
                },
              ),
              _DropdownSetting(
                title: 'Устройство ввода',
                value: _selectedInput,
                options: _inputDevices,
                onChanged: (value) {
                  setState(() {
                    _selectedInput = value!;
                  });
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Настройки',
            children: [
              SwitchListTile(
                title: const Text('Отключить все звуки'),
                subtitle: const Text('Полностью отключить системные звуки'),
                value: false,
                onChanged: (value) {
                },
              ),
              ListTile(
                title: const Text('Звуковые эффекты'),
                subtitle: const Text('Системные звуки и обратная связь'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Тестовый звук'),
                        onPressed: _playTestSound,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Process.run('pkill', ['speaker-test']);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stop),
                            SizedBox(width: 8),
                            Text('Остановить'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VolumeSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _VolumeSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: title,
      children: children,
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback? onTest;

  const _VolumeSlider({
    required this.title,
    required this.value,
    required this.onChanged,
    this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Row(
        children: [
          Expanded(
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
              divisions: 10,
              label: '${(value * 100).round()}%',
            ),
          ),
          Text('${(value * 100).round()}%'),
          if (onTest != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.volume_up, size: 20),
              onPressed: onTest,
              tooltip: 'Проверить звук',
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownSetting({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
    );
  }
}
