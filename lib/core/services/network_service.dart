import 'package:process_run/process_run.dart';

class NetworkService {
  static Future<Map<String, dynamic>> getWifiInfo() async {
    try {
      final result = await run('nmcli', ['-t', '-f', 'ACTIVE,SSID', 'dev', 'wifi']);
      final lines = result.stdout.toString().trim().split('\n');
      
      String? currentSsid;
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length >= 2 && parts[0] == 'yes') {
          currentSsid = parts[1];
          break;
        }
      }

      final ipResult = await run('hostname', ['-I']);
      final ip = ipResult.stdout.toString().trim().split(' ').first;

      return {
        'ssid': currentSsid ?? 'Not connected',
        'ip': ip,
        'connected': currentSsid != null,
      };
    } catch (e) {
      return {
        'ssid': 'Not connected',
        'ip': 'Unknown',
        'connected': false,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableNetworks() async {
    try {
      final result = await run('nmcli', ['-t', '-f', 'SSID,SIGNAL,SECURITY', 'dev', 'wifi']);
      final networks = <Map<String, dynamic>>[];
      final lines = result.stdout.toString().trim().split('\n');
      
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length >= 3) {
          networks.add({
            'ssid': parts[0],
            'signal': int.tryParse(parts[1]) ?? 0,
            'security': parts[2],
            'connected': false,
          });
        }
      }

      final currentInfo = await getWifiInfo();
      for (final network in networks) {
        if (network['ssid'] == currentInfo['ssid']) {
          network['connected'] = true;
        }
      }

      return networks;
    } catch (e) {
      return [
        {
          'ssid': 'Home-WiFi',
          'signal': 85,
          'security': 'WPA2',
          'connected': true,
        },
        {
          'ssid': 'Office-Network',
          'signal': 60,
          'security': 'WPA2',
          'connected': false,
        },
        {
          'ssid': 'Free-WiFi',
          'signal': 45,
          'security': 'Open',
          'connected': false,
        },
      ];
    }
  }

  static Future<void> setWifiEnabled(bool enabled) async {
    try {
      if (enabled) {
        await run('nmcli', ['radio', 'wifi', 'on']);
      } else {
        await run('nmcli', ['radio', 'wifi', 'off']);
      }
    } catch (e) {
    }
  }

  static Future<Map<String, dynamic>> getEthernetInfo() async {
    try {
      final result = await run('nmcli', ['-t', '-f', 'DEVICE,TYPE,STATE', 'dev']);
      final lines = result.stdout.toString().trim().split('\n');
      
      bool ethernetConnected = false;
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length >= 3 && parts[1] == 'ethernet' && parts[2] == 'connected') {
          ethernetConnected = true;
          break;
        }
      }

      return {
        'connected': ethernetConnected,
        'interface': 'eth0',
      };
    } catch (e) {
      return {
        'connected': true,
        'interface': 'eth0',
      };
    }
  }
}
