import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleSyncService {
  static final GoogleSyncService _instance = GoogleSyncService._internal();
  factory GoogleSyncService() => _instance;
  GoogleSyncService._internal();

  static const String _syncKey = 'google_sync_enabled';
  static const String _accountKey = 'google_account';
  static const String _lastSyncKey = 'last_sync_time';

  Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncKey) ?? false;
  }

  Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncKey, enabled);
    
    if (enabled) {
      await _startSync();
    } else {
      await _stopSync();
    }
  }

  Future<String?> getAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accountKey);
  }

  Future<void> setAccount(String account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountKey, account);
  }

  Future<void> _startSync() async {
    try {
      final result = await Process.run('rclone', ['lsd', 'gdrive:']);
      if (result.exitCode == 0) {
        await Process.run('rclone', ['sync', '-v', '~/Documents', 'gdrive:Documents']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastSyncKey, DateTime.now().toString());
      }
    } catch (e) {
      print('Ошибка синхронизации: $e');
    }
  }

  Future<void> _stopSync() async {
    try {
      await Process.run('pkill', ['-f', 'rclone']);
    } catch (e) {
      print('Ошибка остановки синхронизации: $e');
    }
  }

  Future<void> forceSync() async {
    if (await isSyncEnabled()) {
      await _startSync();
    }
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSync = prefs.getString(_lastSyncKey);
    return lastSync != null ? DateTime.parse(lastSync) : null;
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    final lastSync = await getLastSyncTime();
    final account = await getAccount();
    final enabled = await isSyncEnabled();
    
    final rcloneAvailable = await _checkRclone();
    
    return {
      'enabled': enabled,
      'account': account,
      'lastSync': lastSync?.toString() ?? 'Никогда',
      'contacts': await _checkContactSync(),
      'calendar': await _checkCalendarSync(),
      'files': rcloneAvailable,
      'rclone_configured': rcloneAvailable,
    };
  }

  Future<bool> _checkRclone() async {
    try {
      final result = await Process.run('which', ['rclone']);
      if (result.exitCode != 0) return false;
      
      final configResult = await Process.run('rclone', ['config', 'show']);
      return configResult.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkContactSync() async {
    try {
      final result = await Process.run('which', ['vdirsyncer']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkCalendarSync() async {
    try {
      final result = await Process.run('which', ['vdirsyncer']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setupRclone() async {
    try {
      print('Запуск настройки rclone...');
      final result = await Process.run('rclone', ['config']);
      return result.exitCode == 0;
    } catch (e) {
      print('Ошибка настройки rclone: $e');
      return false;
    }
  }
}
