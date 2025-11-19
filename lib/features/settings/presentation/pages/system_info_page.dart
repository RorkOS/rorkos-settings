import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/settings_provider.dart';

class SystemInfoPage extends StatelessWidget {
  const SystemInfoPage({super.key});

  Future<void> _launchGitHub(BuildContext context) async {
    final url = Uri.parse('https://github.com/RorkOS');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('О системе'),
        actions: [
          IconButton(
            icon: const Icon(Icons.terminal),
            onPressed: () {
              settingsProvider.openTerminal();
            },
            tooltip: 'Открыть терминал',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              settingsProvider.refreshSystemData();
            },
            tooltip: 'Обновить информацию',
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.memory,
                    size: 50,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'RorkOS',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            settingsProvider.systemInfo['os'] ?? 'Дистрибутив Linux',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          // Ссылка на GitHub
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: FilledButton.icon(
              icon: const Icon(Icons.code, size: 18),
              label: const Text('GitHub проекта'),
              onPressed: () => _launchGitHub(context),
            ),
          ),
          const SizedBox(height: 32),
          _InfoCard(
            children: [
              _InfoItem(
                title: 'Имя хоста',
                value: settingsProvider.systemInfo['hostname'] ?? 'Неизвестно',
              ),
              _InfoItem(
                title: 'Операционная система',
                value: settingsProvider.systemInfo['os'] ?? 'Неизвестно',
              ),
              _InfoItem(
                title: 'Ядро',
                value: settingsProvider.systemInfo['kernel'] ?? 'Неизвестно',
              ),
              _InfoItem(
                title: 'Память',
                value: settingsProvider.systemInfo['memory'] ?? 'Неизвестно',
              ),
              _InfoItem(
                title: 'Дисковое пространство',
                value: settingsProvider.systemInfo['disk'] ?? 'Неизвестно',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Системные действия',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.terminal, size: 16),
                        label: const Text('Терминал'),
                        onPressed: () {
                          settingsProvider.openTerminal();
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.update, size: 16),
                        label: const Text('Проверить обновления'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/updates');
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.backup, size: 16),
                        label: const Text('Резервная копия'),
                        onPressed: () {
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String title;
  final String value;

  const _InfoItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
