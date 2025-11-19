import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/google_sync_service.dart';

class GoogleSyncPage extends StatefulWidget {
  const GoogleSyncPage({super.key});

  @override
  State<GoogleSyncPage> createState() => _GoogleSyncPageState();
}

class _GoogleSyncPageState extends State<GoogleSyncPage> {
  final GoogleSyncService _syncService = GoogleSyncService();
  final Map<String, bool> _syncItems = {
    'Контакты': true,
    'Календарь': true,
    'Google Диск': true,
    'Gmail': false,
    'Google Фото': true,
    'Пароли': false,
  };

  Map<String, dynamic> _syncStatus = {};
  bool _isLoading = true;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    _syncStatus = await _syncService.getSyncStatus();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _showAuthDialog(BuildContext context) async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройка синхронизации Google'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Для работы синхронизации необходимо:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.terminal),
              title: const Text('1. Установить rclone'),
              subtitle: const Text('sudo apt install rclone'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('2. Настроить rclone'),
              subtitle: const Text('Запустите настройку для подключения Google Drive'),
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('3. Включить синхронизацию'),
              subtitle: const Text('Выберите папки для синхронизации'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await _syncService.setupRclone();
              if (success) {
                await _syncService.setAccount('google-drive');
                await _syncService.setSyncEnabled(true);
                settingsProvider.setGoogleSyncEnabled(true);
                settingsProvider.setGoogleAccount('google-drive');
                
                Navigator.pop(context);
                await _loadSyncStatus();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rclone успешно настроен')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ошибка настройки rclone')),
                );
              }
            },
            child: const Text('Настроить rclone'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleSyncItem(String item, bool value) async {
    setState(() {
      _syncItems[item] = value;
    });
    
    if (value) {
      await _syncService.forceSync();
    }
  }

  Future<void> _logout() async {
    await _syncService.setSyncEnabled(false);
    
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.setGoogleSyncEnabled(false);
    settingsProvider.setGoogleAccount('');
    
    await _loadSyncStatus();
    
    setState(() {
      _statusMessage = 'Выход выполнен';
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Синхронизация с Google'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Синхронизация с Google'),
        actions: [
          if (_syncStatus['enabled'] as bool)
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () {
                _syncService.forceSync();
                _loadSyncStatus();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Синхронизация запущена')),
                );
              },
            ),
        ],
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _syncStatus['enabled'] as bool
                        ? _syncStatus['account'] as String
                        : 'Аккаунт не подключен',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _syncStatus['enabled'] as bool
                        ? 'Синхронизация активна'
                        : 'Войдите для синхронизации',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _syncStatus['enabled'] as bool
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  if (_syncStatus['enabled'] as bool) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Последняя синхронизация: ${_syncStatus['lastSync']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_statusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          color: _statusMessage.contains('Ошибка') ? Colors.red : Colors.green,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!_syncStatus['enabled'] as bool)
                        FilledButton(
                          onPressed: () => _showAuthDialog(context),
                          child: const Text('Войти в аккаунт'),
                        )
                      else
                        FilledButton(
                          onPressed: _logout,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Выйти'),
                        ),
                      FilledButton.tonal(
                        onPressed: () {
                          _loadSyncStatus();
                        },
                        child: const Text('Обновить'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_syncStatus['enabled'] as bool) ...[
            _SyncSection(
              title: 'Типы синхронизации',
              children: [
                SwitchListTile(
                  title: const Text('Общая синхронизация'),
                  subtitle: const Text('Включить автоматическую синхронизацию'),
                  value: _syncStatus['enabled'] as bool,
                  onChanged: (value) async {
                    await _syncService.setSyncEnabled(value);
                    settingsProvider.setGoogleSyncEnabled(value);
                    await _loadSyncStatus();
                  },
                ),
                ..._syncItems.entries.map((entry) => SwitchListTile(
                  title: Text(entry.key),
                  value: entry.value,
                  onChanged: (value) => _toggleSyncItem(entry.key, value!),
                )),
              ],
            ),
            _SyncSection(
              title: 'Статус сервисов',
              children: [
                _ServiceStatusItem(
                  name: 'Контакты',
                  status: _syncStatus['contacts'] as bool,
                ),
                _ServiceStatusItem(
                  name: 'Календарь',
                  status: _syncStatus['calendar'] as bool,
                ),
                _ServiceStatusItem(
                  name: 'Файлы',
                  status: _syncStatus['files'] as bool,
                ),
              ],
            ),
          ] else
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Преимущества синхронизации',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      leading: Icon(Icons.cloud_upload, color: Colors.green),
                      title: Text('Резервное копирование'),
                      subtitle: Text('Автоматическое сохранение данных в облаке'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.sync, color: Colors.blue),
                      title: Text('Синхронизация между устройствами'),
                      subtitle: Text('Доступ к данным на всех ваших устройствах'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.security, color: Colors.orange),
                      title: Text('Безопасное хранение'),
                      subtitle: Text('Ваши данные защищены шифрованием'),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => _showAuthDialog(context),
                      child: const Text('Настроить синхронизацию'),
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

class _SyncSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SyncSection({
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

class _ServiceStatusItem extends StatelessWidget {
  final String name;
  final bool status;

  const _ServiceStatusItem({
    required this.name,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        status ? Icons.check_circle : Icons.error,
        color: status ? Colors.green : Colors.grey,
      ),
      title: Text(name),
      subtitle: Text(status ? 'Работает' : 'Недоступно'),
      trailing: Chip(
        label: Text(status ? 'OK' : 'Ошибка'),
        backgroundColor: status ? Colors.green : Colors.red,
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
