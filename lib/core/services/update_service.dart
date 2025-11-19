import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String _lastCheckKey = 'last_update_check';
  static const String _currentVersionKey = 'current_version';
  static const String _updateUrl = 'https://raw.githubusercontent.com/RorkOS/rorkos-updates/main/';

  Future<Map<String, dynamic>> checkForUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_lastCheckKey);
      final currentVersion = prefs.getString(_currentVersionKey) ?? '1.0.0';

      final response = await http.get(Uri.parse('${_updateUrl}latest.json'));
      
      if (response.statusCode == 200) {
        final updateInfo = json.decode(response.body);
        final latestVersion = updateInfo['version'];
        final downloadUrl = updateInfo['download_url'];
        final changelog = updateInfo['changelog'];
        final size = updateInfo['size'];
        final checksum = updateInfo['checksum'];

        await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());

        return {
          'current_version': currentVersion,
          'latest_version': latestVersion,
          'update_available': _compareVersions(currentVersion, latestVersion) < 0,
          'download_url': downloadUrl,
          'changelog': changelog,
          'size': size,
          'checksum': checksum,
          'last_checked': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      print('Ошибка проверки обновлений: $e');
    }

    return {
      'current_version': '1.0.0',
      'latest_version': '1.0.0',
      'update_available': false,
      'last_checked': DateTime.now().toIso8601String(),
    };
  }

  int _compareVersions(String version1, String version2) {
    final v1 = version1.split('.').map(int.parse).toList();
    final v2 = version2.split('.').map(int.parse).toList();

    for (int i = 0; i < v1.length; i++) {
      if (v1[i] > v2[i]) return 1;
      if (v1[i] < v2[i]) return -1;
    }
    return 0;
  }

  Future<Map<String, dynamic>> downloadUpdate(String downloadUrl, Function(String) onProgress) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Ошибка загрузки: ${response.statusCode}');
      }

      // Создаем временную директорию
      final tempDir = Directory.systemTemp.createTempSync('rorkos_update');
      final fileName = path.basename(downloadUrl);
      final filePath = path.join(tempDir.path, fileName);
      final file = File(filePath);

      // Загружаем файл с прогрессом
      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = file.openWrite();
      await for (var chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        
        if (totalBytes > 0) {
          final progress = (receivedBytes / totalBytes * 100).toInt();
          onProgress('Загрузка: $progress% ($receivedBytes/$totalBytes байт)');
        }
      }
      await sink.close();

      final checksum = await _calculateChecksum(filePath);
      
      return {
        'success': true,
        'file_path': filePath,
        'file_size': receivedBytes,
        'checksum': checksum,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<String> _calculateChecksum(String filePath) async {
    final process = await Process.run('sha256sum', [filePath]);
    return process.stdout.toString().split(' ')[0];
  }

  Future<Map<String, dynamic>> installUpdate(String filePath, String password) async {
    try {
      final String command;
      final List<String> args;

      if (filePath.endsWith('.zip')) {
        command = 'unzip';
        args = ['-o', filePath, '-d', '/'];
      } else if (filePath.endsWith('.tar.gz')) {
        command = 'tar';
        args = ['-xzf', filePath, '-C', '/'];
      } else if (filePath.endsWith('.tar.xz')) {
        command = 'tar';
        args = ['-xJf', filePath, '-C', '/'];
      } else {
        throw Exception('Неподдерживаемый формат архива');
      }

      final process = await Process.start(
        'pkexec',
        [command, ...args],
        runInShell: true,
      );

      if (password.isNotEmpty) {
        process.stdin.writeln(password);
      }
      process.stdin.close();

      final exitCode = await process.exitCode;

      if (exitCode == 0) {
        final prefs = await SharedPreferences.getInstance();
        final updateInfo = await checkForUpdates();
        await prefs.setString(_currentVersionKey, updateInfo['latest_version']);

        return {
          'success': true,
          'message': 'Обновление успешно установлено',
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка установки. Код: $exitCode',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка установки: $e',
      };
    }
  }

  Future<void> rebootSystem() async {
    try {
      await Process.run('pkexec', ['systemctl', 'reboot']);
    } catch (e) {
      try {
        await Process.run('pkexec', ['reboot']);
      } catch (e) {
        await Process.run('pkexec', ['shutdown', '-r', 'now']);
      }
    }
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final uname = await Process.run('uname', ['-r']);
      final lsbRelease = await Process.run('lsb_release', ['-d']);
      final arch = await Process.run('uname', ['-m']);

      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getString(_currentVersionKey) ?? '1.0.0';

      return {
        'current_version': currentVersion,
        'kernel_version': uname.stdout.toString().trim(),
        'distribution': lsbRelease.stdout.toString().replaceFirst('Description:', '').trim(),
        'architecture': arch.stdout.toString().trim(),
        'last_check': prefs.getString(_lastCheckKey) ?? 'Никогда',
      };
    } catch (e) {
      return {
        'current_version': '1.0.0',
        'kernel_version': 'Неизвестно',
        'distribution': 'Rorkos',
        'architecture': 'Неизвестно',
        'last_check': 'Никогда',
      };
    }
  }
}
