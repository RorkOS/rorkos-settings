import 'dart:io';
import 'package:process_run/process_run.dart';

class SystemApplication {
  final String name;
  final String path;
  final String type;
  final int size;

  SystemApplication({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
  });
}

class LinuxSystemService {
  static Future<Map<String, String>> getSystemInfo() async {
    try {
      final uname = await run('uname', ['-r']);
      final memory = await run('free', ['-h']);
      final disk = await run('df', ['-h', '/']);
      final os = await run('lsb_release', ['-d']);
      final hostname = await run('hostname', []);
      
      return {
        'kernel': uname.stdout.toString().trim(),
        'memory': _parseMemory(memory.stdout.toString()),
        'disk': _parseDisk(disk.stdout.toString()),
        'os': os.stdout.toString().replaceFirst('Description:', '').trim(),
        'hostname': hostname.stdout.toString().trim(),
      };
    } catch (e) {
      return {
        'kernel': 'Linux',
        'memory': 'Unknown',
        'disk': 'Unknown',
        'os': 'RorkOS',
        'hostname': 'localhost',
      };
    }
  }

  static String _parseMemory(String output) {
    try {
      final lines = output.split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        return '${parts[2]} / ${parts[1]} used';
      }
    } catch (e) {}
    return 'Unknown';
  }

  static String _parseDisk(String output) {
    try {
      final lines = output.split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        return '${parts[2]} / ${parts[1]} used (${parts[3]} free)';
      }
    } catch (e) {}
    return 'Unknown';
  }

  static Future<List<Map<String, dynamic>>> getWiFiNetworks() async {
    try {
      final result = await run('iwctl', ['station', 'list']);
      final networks = <Map<String, dynamic>>[];
      
      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.contains('SSID') && !line.contains('SSID')) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.isNotEmpty) {
            networks.add({
              'ssid': parts[0],
              'signal': 75,
              'security': 'WPA2',
              'connected': line.contains('connected'),
            });
          }
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
      ];
    }
  }

  static Future<List<Map<String, dynamic>>> getBluetoothDevices() async {
    try {
      final result = await run('bluetoothctl', ['devices']);
      final devices = <Map<String, dynamic>>[];
      
      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.startsWith('Device')) {
          final parts = line.split(' ');
          if (parts.length >= 3) {
            devices.add({
              'name': parts.sublist(2).join(' '),
              'address': parts[1],
              'connected': false,
              'type': 'Unknown',
            });
          }
        }
      }
      
      return devices;
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getAudioInfo() async {
    try {
      final sinks = await run('pactl', ['list', 'sinks']);
      final sources = await run('pactl', ['list', 'sources']);
      
      return {
        'volume': 75,
        'muted': false,
        'sinks': sinks.stdout.toString(),
        'sources': sources.stdout.toString(),
      };
    } catch (e) {
      return {'volume': 75, 'muted': false};
    }
  }

  static Future<void> setVolume(int volume) async {
    try {
      await run('pactl', ['set-sink-volume', '@DEFAULT_SINK@', '$volume%']);
    } catch (e) {}
  }

  static Future<List<SystemApplication>> getInstalledApplications() async {
    final apps = <SystemApplication>[];
    
    try {
      final binDir = Directory('/usr/bin');
      if (await binDir.exists()) {
        await for (var entity in binDir.list()) {
          if (entity is File) {
            try {
              final stat = await entity.stat();
              final result = await run('test', ['-x', entity.path]);
              if (result.exitCode == 0) {
                apps.add(SystemApplication(
                  name: entity.uri.pathSegments.last,
                  path: entity.path,
                  type: 'binary',
                  size: stat.size,
                ));
              }
            } catch (e) {}
          }
        }
      }
      
      apps.sort((a, b) => a.name.compareTo(b.name));
      return apps.take(100).toList();
    } catch (e) {
      return [
        SystemApplication(name: 'bash', path: '/usr/bin/bash', type: 'binary', size: 0),
        SystemApplication(name: 'ls', path: '/usr/bin/ls', type: 'binary', size: 0),
      ];
    }
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
        } catch (e) {}
      }
    }
  }
}
