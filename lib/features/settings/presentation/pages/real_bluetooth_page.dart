import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:process_run/process_run.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/services/bluetooth_service.dart';

class RealBluetoothPage extends StatefulWidget {
  const RealBluetoothPage({super.key});

  @override
  State<RealBluetoothPage> createState() => _RealBluetoothPageState();
}

class _RealBluetoothPageState extends State<RealBluetoothPage> {
  bool _bluetoothEnabled = false;
  List<Map<String, dynamic>> _devices = [];
  bool _isScanning = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBluetoothStatus();
  }

  Future<void> _loadBluetoothStatus() async {
    setState(() {
      _isLoading = true;
    });

    _bluetoothEnabled = await BluetoothService.getBluetoothStatus();
    if (_bluetoothEnabled) {
      await _loadDevices();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadDevices() async {
    final devices = await BluetoothService.getBluetoothDevices();
    setState(() {
      _devices = devices;
    });
  }

  Future<void> _toggleBluetooth(bool enabled) async {
    setState(() {
      _isLoading = true;
    });

    await BluetoothService.setBluetoothEnabled(enabled);
    
    if (enabled) {
      await _startScanning();
    } else {
      setState(() {
        _devices = [];
        _isScanning = false;
      });
    }

    setState(() {
      _bluetoothEnabled = enabled;
      _isLoading = false;
    });
  }

  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
    });

    await Future.delayed(const Duration(seconds: 3));
    await _loadDevices();

    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _connectToDevice(Map<String, dynamic> device) async {
    try {
      await BluetoothService.connectToDevice(device['address']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device['name']}')),
      );
      await _loadDevices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ${device['name']}')),
      );
    }
  }

  Future<void> _disconnectDevice(Map<String, dynamic> device) async {
    try {
      await BluetoothService.disconnectDevice(device['address']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnected from ${device['name']}')),
      );
      await _loadDevices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to disconnect from ${device['name']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth'),
        actions: [
          if (_bluetoothEnabled && !_isScanning)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _startScanning,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  child: SwitchListTile(
                    title: const Text('Bluetooth'),
                    subtitle: Text(_bluetoothEnabled ? 'On' : 'Off'),
                    value: _bluetoothEnabled,
                    onChanged: _toggleBluetooth,
                  ),
                ),

                if (_bluetoothEnabled) ...[
                  if (_isScanning)
                    const Card(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Scanning for devices...'),
                      ),
                    ),

                  Expanded(
                    child: _devices.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No Bluetooth devices found'),
                                Text('Make sure your devices are in pairing mode'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _devices.length,
                            itemBuilder: (context, index) {
                              final device = _devices[index];
                              return _BluetoothDeviceItem(
                                device: device,
                                onConnect: () => _connectToDevice(device),
                                onDisconnect: () => _disconnectDevice(device),
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
                          Text('Bluetooth is turned off'),
                          Text('Turn on Bluetooth to connect devices'),
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
  final Map<String, dynamic> device;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const _BluetoothDeviceItem({
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = device['connected'] == true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getDeviceIcon(device['type']),
            color: Colors.blue,
          ),
        ),
        title: Text(device['name'] ?? 'Unknown Device'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device['address'] ?? ''),
            Text('Type: ${device['type']}'),
          ],
        ),
        trailing: isConnected
            ? FilledButton.tonal(
                onPressed: onDisconnect,
                child: const Text('Disconnect'),
              )
            : FilledButton(
                onPressed: onConnect,
                child: const Text('Connect'),
              ),
      ),
    );
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'audio':
        return Icons.headphones;
      case 'mouse':
        return Icons.mouse;
      case 'keyboard':
        return Icons.keyboard;
      case 'phone':
        return Icons.phone;
      default:
        return Icons.devices_other;
    }
  }
}
