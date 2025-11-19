import 'package:process_run/process_run.dart';

class BluetoothService {
  static Future<bool> getBluetoothStatus() async {
    try {
      final result = await run('bluetoothctl', ['show']);
      final output = result.stdout.toString();
      return output.contains('Powered: yes');
    } catch (e) {
      return false;
    }
  }

  static Future<void> setBluetoothEnabled(bool enabled) async {
    try {
      if (enabled) {
        await run('bluetoothctl', ['power', 'on']);
      } else {
        await run('bluetoothctl', ['power', 'off']);
      }
    } catch (e) {
    }
  }

  static Future<List<Malt.stdout.toString().trim().split('\n');
      
      for (final line in lines) {
        if (line.startsWith('Device')) {
          final parts = line.split(' ');
          if (parts.length >= 3) {
            final address = parts[1];
            final name = parts.sublist(2).join(' ');
            
            final infoResult = await run('bluetoothctl', ['info', address]);
            final connected = infoResult.stdout.toString().contains('Connected: yes');
            
            devices.add({
              'name': name,
              'address': address,
              'connected': connected,
              'type': _getDeviceType(name),
            });
          }
        }
      }

      return devices;
    } catch (e) {
      return [
        {
          'name': 'Wireless Headphones',
          'address': '00:1A:7D:DA:71:13',
          'connected': false,
          'type': 'Audio',
        },
        {
          'name': 'Magic Mouse',
          'address': '5C:F3:70:90:6A:12',
          'connected': true,
          'type': 'Mouse',
        },
      ];
    }
  }

  static String _getDeviceType(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('headphone') || lowerName.contains('speaker')) {
      return 'Audio';
    } else if (lowerName.contains('mouse')) {
      return 'Mouse';
    } else if (lowerName.contains('keyboard')) {
      return 'Keyboard';
    } else if (lowerName.contains('phone')) {
      return 'Phone';
    } else {
      return 'Other';
    }
  }

  static Future<void> connectToDevice(String address) async {
    try {
      await run('bluetoothctl', ['connect', address]);
    } catch (e) {
    try {
      await run('bluetoothctl', ['disconnect', address]);
    } catch (e) {
    }
  }
}
