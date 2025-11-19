import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplaySettingsPage extends StatefulWidget {
  const DisplaySettingsPage({super.key});

  @override
  State<DisplaySettingsPage> createState() => _DisplaySettingsPageState();
}

class _DisplaySettingsPageState extends State<DisplaySettingsPage> {
  double _brightness = 0.7;
  bool _nightLightEnabled = false;
  String _resolution = '1920x1080';
  String _refreshRate = '60Hz';
  double _scale = 1.0;
  bool _autoRotate = true;
  bool _hdrEnabled = false;
  String _colorProfile = 'sRGB';

  final List<String> _resolutions = [
    '1024x768',
    '1280x720',
    '1366x768',
    '1600x900',
    '1920x1080',
    '2560x1440',
    '3840x2160'
  ];

  final List<String> _refreshRates = [
    '30Hz',
    '60Hz',
    '75Hz',
    '120Hz',
    '144Hz'
  ];

  final List<String> _colorProfiles = [
    'sRGB',
    'Adobe RGB',
    'DCI-P3',
    'Custom'
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _brightness = (prefs.getDouble('display_brightness') ?? 0.7).clamp(0.0, 1.0);
      _nightLightEnabled = prefs.getBool('night_light_enabled') ?? false;
      _resolution = prefs.getString('resolution') ?? '1920x1080';
      _refreshRate = prefs.getString('refresh_rate') ?? '60Hz';
      _scale = (prefs.getDouble('display_scale') ?? 1.0).clamp(0.5, 3.0);
      _autoRotate = prefs.getBool('auto_rotate') ?? true;
      _hdrEnabled = prefs.getBool('hdr_enabled') ?? false;
      _colorProfile = prefs.getString('color_profile') ?? 'sRGB';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('display_brightness', _brightness);
    await prefs.setBool('night_light_enabled', _nightLightEnabled);
    await prefs.setString('resolution', _resolution);
    await prefs.setString('refresh_rate', _refreshRate);
    await prefs.setDouble('display_scale', _scale);
    await prefs.setBool('auto_rotate', _autoRotate);
    await prefs.setBool('hdr_enabled', _hdrEnabled);
    await prefs.setString('color_profile', _colorProfile);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки сохранены')),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String? label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(label ?? '${(value * 100).round()}%'),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        DropdownButtonFormField<String>(
          value: value,
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дисплей'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Сохранить настройки',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog(context);
            },
            tooltip: 'Справка',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Яркость и освещение', [
                _buildSliderSetting(
                  title: 'Яркость',
                  value: _brightness,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _brightness = value;
                    });
                  },
                  label: '${(_brightness * 100).round()}%',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Автоматическая яркость'),
                  subtitle: const Text('Регулировать яркость в зависимости от освещения'),
                  value: false,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Ночной свет'),
                  subtitle: const Text('Уменьшить синий свет в вечернее время'),
                  value: _nightLightEnabled,
                  onChanged: (value) {
                    setState(() {
                      _nightLightEnabled = value;
                    });
                  },
                ),
                if (_nightLightEnabled)
                  Padding(
                    padding: const EdgeInsets.only(left: 56.0),
                    child: _buildSliderSetting(
                      title: 'Интенсивность',
                      value: 0.5,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) {},
                    ),
                  ),
              ],
            ),
            
            _buildSection('Разрешение и обновление', [
                _buildDropdownSetting(
                  title: 'Разрешение экрана',
                  value: _resolution,
                  options: _resolutions,
                  onChanged: (value) {
                    setState(() {
                      _resolution = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownSetting(
                  title: 'Частота обновления',
                  value: _refreshRate,
                  options: _refreshRates,
                  onChanged: (value) {
                    setState(() {
                      _refreshRate = value!;
                    });
                  },
                ),
              ],
            ),
            
            _buildSection('Масштабирование', [
                _buildSliderSetting(
                  title: 'Масштаб интерфейса',
                  value: _scale,
                  min: 0.5,
                  max: 3.0,
                  divisions: 25,
                  onChanged: (value) {
                    setState(() {
                      _scale = value;
                    });
                  },
                  label: '${_scale.toStringAsFixed(2)}x',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Автоматический поворот'),
                  subtitle: const Text('Повернуть экран при изменении ориентации устройства'),
                  value: _autoRotate,
                  onChanged: (value) {
                    setState(() {
                      _autoRotate = value;
                    });
                  },
                ),
              ],
            ),
            
            _buildSection('Продвинутые настройки', [
                SwitchListTile(
                  title: const Text('HDR'),
                  subtitle: const Text('Включить поддержку HDR для совместимого контента'),
                  value: _hdrEnabled,
                  onChanged: (value) {
                    setState(() {
                      _hdrEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdownSetting(
                  title: 'Цветовой профиль',
                  value: _colorProfile,
                  options: _colorProfiles,
                  onChanged: (value) {
                    setState(() {
                      _colorProfile = value!;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Справка по настройкам дисплея'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• Яркость: регулирует общую яркость экрана'),
              Text('• Ночной свет: уменьшает синий свет для комфорта глаз в темное время суток'),
              Text('• Разрешение: определяет количество пикселей на экране'),
              Text('• Частота обновления: сколько раз в секунду обновляется изображение'),
              Text('• Масштаб: увеличивает или уменьшает размер элементов интерфейса'),
              Text('• HDR: обеспечивает более широкий динамический диапазон цветов'), 
              Text('• Цветовой профиль: определяет цветовую гамму для точной цветопередачи'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
