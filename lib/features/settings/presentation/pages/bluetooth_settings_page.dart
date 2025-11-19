import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../data/models/system_models.dart';
import 'dart:io';

class BluetoothSettingsPage extends StatefulWidget {
  const BluetoothSettingsPage({super.key});

  @override
  State<BluetoothSettingsPage> createState() => _BluetoothSettingsPageState();
}

class _BluetoothSettingsPageState extends State<BluetoothSettingsPage> {
  bool _bluetoothEnabled = false;
  bool _isScanning = false;

  Future<void> _toggleBluetooth(bool enabled) async {
    setState(() {
      _bluetoothEnabled = enabled;
    });

    try {
      if (enabled) {
        await Process.run('bluetoothctl', ['power', 'on']);
        _startScanning();
      } else {
        await Process.run('bluetoothctl', ['power', 'off']);
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      print('Ошибка управления Bluetooth: $e');
    }
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
    });

    try {
      await Process.run('bluetoothctl', ['scan', 'on']);
      await Future.delayed(const Duration(seconds: 10));
      await Process.run('bluetoothctl', ['scan', 'off']);
    } catch (e) {
      print('Ошибка сканирования: $e');
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      final result = await Process.run('bluetoothctl', ['connect', device.address]);
      if (result.exitCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Подключено к ${device.name}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка подключения к ${device.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _disconnectDevice(BluetoothDevice device) async {
    try {
      final result = await Process.run('bluetoothctl', ['disconnect', device.address]);
      if (result.exitCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Отключено от ${device.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отключения: $e')),
      );
    }
  }

  Future<void> _pairDevice(BluetoothDevice device) async {
    try {
      final result = await Process.run('bluetoothctl', ['pair', device.address]);
      if (result.exitCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Сопряжено с ${device.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сопряжения: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth'),
        actions: [
          if (_bluetoothEnabled) ...[
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScanning,
              tooltip: 'Обновить устройства',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Bluetooth'),
            subtitle: Text(_bluetoothEnabled ? 'Включено' : 'Выключено'),
            value: _bluetoothEnabled,
            onChanged: _toggleBluetooth,
          ),
          if (_bluetoothEnabled) ...[
            if (_isScanning)
              const LinearProgressIndicator(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.search, size: 16),
                  SizedBox(width: 8),
                  Text('Поиск устройств...'),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: settingsProvider.bluetoothDevices.length,
                itemBuilder: (context, index) {
                  final device = settingsProvider.bluetoothDevices[index];
                  return _BluetoothDeviceItem(
                    device: device,
                    onConnect: () => _connectToDevice(device),
                    onDisconnect: () => _disconnectDevice(device),
                    onPair: () => _pairDevice(device),
                  );
                },
              ),
            ),
          ] else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Bluetooth выключен'),
                    SizedBox(height: 8),
                    Text(
                      'Включите Bluetooth для поиска устройств',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
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

class _BluetoothDeviceItem extends StatelessWidget {
  final BluetoothDevice device;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onPair;

  const _BluetoothDeviceItem({
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
    required this.onPair,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.devices),
        title: Text(device.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.address),
            Text('Тип: ${device.type}'),
            if (device.connected)
              const Text('Статус: Подключено', style: TextStyle(color: Colors.green))
            else
              const Text('Статус: Не подключено', style: TextStyle(color: Colors.grey)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!device.connected) ...[
              IconButton(
                icon: const Icon(Icons.link),
                onPressed: onConnect,
                tooltip: 'Подключиться',
              ),
              IconButton(
                icon: const Icon(Icons.bluetooth),
                onPressed: onPair,
                tooltip: 'Сопряжение',
              ),
            ] else
              IconButton(
                icon: const Icon(Icons.link_off),
                onPressed: onDisconnect,
                tooltip: 'Отключиться',
              ),
          ],
        ),
      ),
    );
  }
}
