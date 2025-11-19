import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';

class MainSettingsPage extends StatelessWidget {
  const MainSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки системы'),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'Система',
            children: [
              _SettingsTile(
                icon: Icons.update,
                title: 'Обновление системы',
                subtitle: 'Проверить и установить обновления',
                onTap: () => Navigator.pushNamed(context, '/updates'),
              ),
              _SettingsTile(
                icon: Icons.info,
                title: 'О системе',
                subtitle: 'Информация о системе и устройстве',
                onTap: () => Navigator.pushNamed(context, '/system'),
              ),
              _SettingsTile(
                icon: Icons.sync,
                title: 'Синхронизация с Google',
                subtitle: 'Настройки аккаунта и синхронизации',
                onTap: () => Navigator.pushNamed(context, '/google-sync'),
              ),
            ],
          ),

          _SettingsSection(
            title: 'Устройства',
            children: [
              _SettingsTile(
                icon: Icons.display_settings,
                title: 'Дисплей',
                subtitle: 'Яркость, разрешение, ночной режим',
                onTap: () => Navigator.pushNamed(context, '/display'),
              ),
              _SettingsTile(
                icon: Icons.volume_up,
                title: 'Звук',
                subtitle: 'Громкость, устройства вывода',
                onTap: () => Navigator.pushNamed(context, '/sound'),
              ),
              _SettingsTile(
                icon: Icons.network_wifi,
                title: 'Сеть и интернет',
                subtitle: 'Wi-Fi, мобильные данные',
                onTap: () => Navigator.pushNamed(context, '/network'),
              ),
              _SettingsTile(
                icon: Icons.bluetooth,
                title: 'Bluetooth',
                subtitle: 'Подключенные устройства',
                onTap: () => Navigator.pushNamed(context, '/bluetooth'),
              ),
              _SettingsTile(
                icon: Icons.print,
                title: 'Принтеры',
                subtitle: 'Настройки печати и принтеров',
                onTap: () => Navigator.pushNamed(context, '/printers'),
              ),
            ],
          ),

          _SettingsSection(
            title: 'Персонализация',
            children: [
              _SettingsTile(
                icon: Icons.palette,
                title: 'Внешний вид',
                subtitle: 'Темы, обои, шрифты',
                onTap: () => Navigator.pushNamed(context, '/appearance'),
              ),
              _SettingsTile(
                icon: Icons.language,
                title: 'Язык и регион',
                subtitle: 'Язык системы, раскладка клавиатуры',
                onTap: () => Navigator.pushNamed(context, '/language'),
              ),
              _SettingsTile(
                icon: Icons.notifications,
                title: 'Уведомления',
                subtitle: 'Настройки уведомлений приложений',
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
            ],
          ),

          _SettingsSection(
            title: 'Приложения',
            children: [
              _SettingsTile(
                icon: Icons.apps,
                title: 'Установленные приложения',
                subtitle: 'Управление приложениями',
                onTap: () => Navigator.pushNamed(context, '/apps'),
              ),
              _SettingsTile(
                icon: Icons.security,
                title: 'Разрешения',
                subtitle: 'Управление разрешениями приложений',
                onTap: () {
                },
              ),
            ],
          ),

          _SettingsSection(
            title: 'Дополнительно',
            children: [
              _SettingsTile(
                icon: Icons.storage,
                title: 'Хранилище',
                subtitle: 'Использование памяти и очистка',
                onTap: () {
                },
              ),
              _SettingsTile(
                icon: Icons.battery_std,
                title: 'Батарея',
                subtitle: 'Оптимизация расхода заряда',
                onTap: () {
                },
              ),
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'О приложении',
                subtitle: 'Версия и информация о разработчике',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('О RorkOS Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RorkOS Settings'),
            SizedBox(height: 8),
            Text('Версия: BETA 0.1'),
            SizedBox(height: 8),
            Text('Приложение для управления настройками системы RorkOS'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
