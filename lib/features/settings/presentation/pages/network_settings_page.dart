import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../data/models/system_models.dart';

class NetworkSettingsPage extends StatefulWidget {
  const NetworkSettingsPage({super.key});

  @override
  State<NetworkSettingsPage> createState() => _NetworkSettingsPageState();
}

class _NetworkSettingsPageState extends State<NetworkSettingsPage> {
  final Map<String, String> _savedPasswords = {};
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showPasswordDialog(WiFiNetwork network) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Подключиться к ${network.ssid}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (network.security != 'Open')
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Пароль WiFi',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              )
            else
              const Text('Эта сеть не защищена паролем'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              if (network.security != 'Open') {
                _savedPasswords[network.ssid] = _passwordController.text;
              }
              Navigator.pop(context);
              _connectToNetwork(network);
            },
            child: const Text('Подключиться'),
          ),
        ],
      ),
    );
  }

  void _connectToNetwork(WiFiNetwork network) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Подключение к ${network.ssid}...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сеть'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              settingsProvider.refreshSystemData();
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('WiFi'),
            subtitle: const Text('Беспроводная сеть'),
            value: settingsProvider.wifiEnabled,
            onChanged: (value) {
              settingsProvider.setWifiEnabled(value);
            },
          ),
          if (settingsProvider.wifiEnabled) ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Доступные сети',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...settingsProvider.wifiNetworks.map((network) => _WiFiNetworkItem(
                  network: network,
                  onConnect: () => _showPasswordDialog(network),
                )),
          ],
          const Divider(),
          const ListTile(
            leading: Icon(Icons.settings_ethernet),
            title: Text('Ethernet'),
            subtitle: Text('Проводное подключение'),
            trailing: Chip(label: Text('Подключено')),
          ),
          const ListTile(
            leading: Icon(Icons.vpn_key),
            title: Text('VPN'),
            subtitle: Text('Настройка VPN подключения'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Дополнительные настройки',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.dns),
                    title: const Text('Настройки DNS'),
                    subtitle: const Text('Конфигурация DNS серверов'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Брандмауэр'),
                    subtitle: const Text('Настройки сетевой безопасности'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                    },
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

class _WiFiNetworkItem extends StatelessWidget {
  final WiFiNetwork network;
  final VoidCallback onConnect;

  const _WiFiNetworkItem({
    required this.network,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _getSignalIcon(network.signal),
      title: Text(network.ssid),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Безопасность: ${network.security}'),
          Text('Сигнал: ${network.signal}%'),
        ],
      ),
      trailing: network.connected
          ? FilledButton.tonal(
              onPressed: () {
              },
              child: const Text('Подключено'),
            )
          : FilledButton(
              onPressed: onConnect,
              child: const Text('Подключить'),
            ),
    );
  }

  Widget _getSignalIcon(int signal) {
    IconData icon;
    Color color;
    
    if (signal > 75) {
      icon = Icons.wifi;
      color = Colors.green;
    } else if (signal > 50) {
      icon = Icons.wifi;
      color = Colors.orange;
    } else if (signal > 25) {
      icon = Icons.wifi;
      color = Colors.orangeAccent;
    } else {
      icon = Icons.wifi;
      color = Colors.red;
    }

    return Icon(icon, color: color);
  }
}
