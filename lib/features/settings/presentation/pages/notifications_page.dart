import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _notificationsEnabled = true;
  bool _showPreview = true;
  bool _vibrationEnabled = true;
  bool _ledIndicator = true;
  String _notificationSound = 'default';
  String _vibrationPattern = 'default';

  final List<String> _sounds = [
    'default',
    'chime',
    'bell',
    'beep',
    'notification'
  ];

  final List<String> _vibrationPatterns = [
    'default',
    'short',
    'long',
    'double',
    'pulse'
  ];

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
      ),
      body: ListView(
        children: [
          _NotificationSection(
            title: 'Основные настройки',
            children: [
              SwitchListTile(
                title: const Text('Уведомления'),
                subtitle: const Text('Разрешить уведомления приложения'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  settingsProvider.setNotificationsEnabled(value);
                },
              ),
              SwitchListTile(
                title: const Text('Показывать превью'),
                subtitle: const Text('Показывать содержимое уведомлений'),
                value: _showPreview,
                onChanged: (value) {
                  setState(() {
                    _showPreview = value;
                  });
                },
              ),
            ],
          ),
          _NotificationSection(
            title: 'Звук и вибрация',
            children: [
              _DropdownSetting(
                title: 'Звук уведомления',
                value: _notificationSound,
                options: _sounds,
                onChanged: (value) {
                  setState(() {
                    _notificationSound = value!;
                  });
                },
              ),
              _DropdownSetting(
                title: 'Паттерн вибрации',
                value: _vibrationPattern,
                options: _vibrationPatterns,
                onChanged: (value) {
                  setState(() {
                    _vibrationPattern = value!;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Вибрация'),
                subtitle: const Text('Вибрировать при уведомлениях'),
                value: _vibrationEnabled,
                onChanged: (value) {
                  setState(() {
                    _vibrationEnabled = value;
                  });
                },
              ),
            ],
          ),
          _NotificationSection(
            title: 'Дополнительные настройки',
            children: [
              SwitchListTile(
                title: const Text('Световой индикатор'),
                subtitle: const Text('Мигать светодиодом при уведомлениях'),
                value: _ledIndicator,
                onChanged: (value) {
                  setState(() {
                    _ledIndicator = value;
                  });
                },
              ),
              ListTile(
                title: const Text('Приложения и уведомления'),
                subtitle: const Text('Настройки уведомлений для каждого приложения'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                },
              ),
              ListTile(
                title: const Text('Режим "Не беспокоить"'),
                subtitle: const Text('Настройки тихого времени'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                },
              ),
            ],
          ),
          _NotificationSection(
            title: 'Тестирование',
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton.icon(
                  icon: const Icon(Icons.notifications),
                  label: const Text('Тестовое уведомление'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Тестовое уведомление'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _NotificationSection({
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
