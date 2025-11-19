import 'dart:io';
import 'package:process_run/process_run.dart';
import '../../data/models/system_models.dart';

class SystemService {
  static Future<Map<String, String>> getSystemInfo() async {
    try {
      final unameResult = await run('uname', ['-a']);
      final memoryResult = await run('free', ['-h']);
      final diskResult = await run('df', ['-h', '/']);
      final osResult = await run('lsb_release', ['-d']);
      
      return {
        'kernel': unameResult.stdout.toString().trim(),
        'memory': _parseMemory(memoryResult.stdout.toString()),
        'disk': _parseDisk(diskResult.stdout.toString()),
        'os': osResult.stdout.toString().replaceFirst('Description:', '').trim(),
        'hostname': await _getHostname(),
      };
    } catch (e) {
      return {
        'kernel': 'Linux (Unknown)',
        'memory': 'Unknown',
        'disk': 'Unknown',
        'os': 'RorkOS',
        'hostname': 'localhost',
      };
    }
  }

  static String _parseMemory(String memoryOutput) {
    final lines = memoryOutput.split('\n');
    if (lines.length > 1) {
      final parts = lines[1].split(RegExp(r'\s+'));
      if (parts.length > 2) {
        return '${parts[1]} / ${parts[2]} used';
      }
    }
    return 'Unknown';
  }

  static String _parseDisk(String diskOutput) {
    final lines = diskOutput.split('\n');
    if (lines.length > 1) {
      final parts = lines[1].split(RegExp(r'\s+'));
      if (parts.length > 4) {
        return '${parts[1]} / ${parts[2]} used (${parts[4]} free)';
      }
    }
    return 'Unknown';
  }

  static Future<String> _getHostname() async {
    try {
      final result = await run('hostname', []);
      return result.stdout.toString().trim();
    } catch (e) {
      return 'localhost';
    }
  }

  static Future<List<SystemApplication>> getInstalledApplications() async {
    final applications = <SystemApplication>[];
    
    try {
      final binDir = Directory('/usr/bin');
      if (await binDir.exists()) {
        await for (var entity in binDir.list()) {
          if (entity is File) {
            try {
              final stat = await entity.stat();
              applications.add(SystemApplication(
                name: entity.uri.pathSegments.last,
                path: entity.path,
                type: 'binary',
                size: stat.size,
              ));
            } catch (e) {
              continue;
            }
          }
        }
      }

      final sbinDir = Directory('/usr/sbin');
      if (await sbinDir.exists()) {
        await for (var entity in sbinDir.list()) {
          if (entity is File) {
            try {
              final stat = await entity.stat();
              applications.add(SystemApplication(
                name: entity.uri.pathSegments.last,
                path: entity.path,
                type: 'system',
                size: stat.size,
              ));
            } catch (e) {
              continue;
            }
          }
        }
      }

      applications.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      applications.addAll([
        SystemApplication(name: 'bash', path: '/usr/bin/bash', type: 'binary', size: 0),
        SystemApplication(name: 'ls', path: '/usr/bin/ls', type: 'binary', size: 0),
        SystemApplication(name: 'cat', path: '/usr/bin/cat', type: 'binary', size: 0),
        SystemApplication(name: 'systemctl', path: '/usr/bin/systemctl', type: 'system', size: 0),
      ]);
    }

    return applications;
  }

  static Future<void> openTerminal() async {
    try {
      await run('gnome-terminal', []);
    } catch (e) {
      try {
        await run('konsole', []);
      } catch (e) {
        try {
          await run('xterm', []);
        } catch (e) {
          await run('xdg-open', ['/usr/bin']);
        }
      }
    }
  }

  static Future<List<WiFiNetwork>> getWiFiNetworks() async {
    try {
      final result = await run('nmcli', ['-t', '-f', 'SSID,SIGNAL,SECURITY', 'dev', 'wifi']);
      final networks = <WiFiNetwork>[];
      final lines = result.stdout.toString().trim().split('\n');
      
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length >= 3) {
          networks.add(WiFiNetwork(
            ssid: parts[0],
            signal: int.tryParse(parts[1]) ?? 0,
            security: parts[2],
            connected: false, 
          ));
        }
      }
      
      return networks;
    } catch (e) {
      return [
        WiFiNetwork(ssid: 'Home-WiFi', signal: 85, security: 'WPA2', connected: true),
        WiFiNetwork(ssid: 'Office-Net', signal: 60, security: 'WPA2', connected: false),
        WiFiNetwork(ssid: 'Free-WiFi', signal: 45, security: 'Open', connected: false),
        WiFiNetwork(ssid: 'Neighbor', signal: 30, security: 'WPA', connected: false),
      ];
    }
  }

  static Future<List<BluetoothDevice>> getBluetoothDevices() async {
    try {
      final result = await run('bluetoothctl', ['devices']);
      final devices = <BluetoothDevice>[];
      final lines = result.stdout.toString().trim().split('\n');
      
      for (final line in lines) {
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final address = parts[1];
          final name = parts.sublist(2).join(' ');
          
          devices.add(BluetoothDevice(
            name: name,
            address: address,
            connected: false,
            type: 'Unknown',
          ));
        }
      }
      
      return devices;
    } catch (e) {
      return [
        BluetoothDevice(name: 'Wireless Headphones', address: '00:1A:7D:DA:71:13', connected: false, type: 'Audio'),
        BluetoothDevice(name: 'Magic Mouse', address: '5C:F3:70:90:6A:12', connected: true, type: 'Mouse'),
        BluetoothDevice(name: 'Keyboard K380', address: '44:6E:F5:32:A1:7B', connected: false, type: 'Keyboard'),
      ];
    }
  }
}
