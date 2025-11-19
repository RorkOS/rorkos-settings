import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/system_service.dart';
import '../services/audio_service.dart';
import '../../data/models/system_models.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;
  
  String get theme {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      default:
        return 'system';
    }
  }

  double _brightness = 0.8;
  double get brightness => _brightness;

  double _masterVolume = 0.7;
  double get masterVolume => _masterVolume;

  bool _wifiEnabled = true;
  bool get wifiEnabled => _wifiEnabled;

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  bool _googleSyncEnabled = false;
  bool get googleSyncEnabled => _googleSyncEnabled;
  String _googleAccount = '';
  String get googleAccount => _googleAccount;

  Map<String, String> _systemInfo = {};
  Map<String, String> get systemInfo => _systemInfo;

  List<SystemApplication> _applications = [];
  List<SystemApplication> get applications => _applications;

  List<WiFiNetwork> _wifiNetworks = [];
  List<WiFiNetwork> get wifiNetworks => _wifiNetworks;

  List<BluetoothDevice> _bluetoothDevices = [];
  List<BluetoothDevice> get bluetoothDevices => _bluetoothDevices;

  final AudioService _audioService = AudioService();

  SettingsProvider() {
    _loadSettings();
    _loadSystemData();
  }

  void _loadSettings() {
    _masterVolume = StorageService.getMasterVolume();
    _wifiEnabled = StorageService.getWifiEnabled();
    _notificationsEnabled = StorageService.getNotificationsEnabled();
    _brightness = StorageService.getBrightness();
    
    final theme = StorageService.getTheme();
    switch (theme) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
  }

  Future<void> _loadSystemData() async {
    await _loadSystemInfo();
    await _loadApplications();
    await _loadWiFiNetworks();
    await _loadBluetoothDevices();
  }

  Future<void> _loadSystemInfo() async {
    _systemInfo = await SystemService.getSystemInfo();
    notifyListeners();
  }

  Future<void> _loadApplications() async {
    _applications = await SystemService.getInstalledApplications();
    notifyListeners();
  }

  Future<void> _loadWiFiNetworks() async {
    _wifiNetworks = await SystemService.getWiFiNetworks();
    notifyListeners();
  }

  Future<void> _loadBluetoothDevices() async {
    _bluetoothDevices = await SystemService.getBluetoothDevices();
    notifyListeners();
  }

  Future<void> refreshSystemData() async {
    await _loadSystemData();
    notifyListeners();
  }

  Future<void> loadSystemData() async {
    await _loadSystemData();
  }

  void setTheme(ThemeMode theme) {
    _themeMode = theme;
    String themeString;
    switch (theme) {
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.light:
        themeString = 'light';
        break;
      default:
        themeString = 'system';
    }
    StorageService.setTheme(themeString);
    notifyListeners();
  }

  void setBrightness(double value) {
    _brightness = value.clamp(0.0, 1.0);
    StorageService.setBrightness(_brightness);
    notifyListeners();
  }

  void setMasterVolume(double volume) {
    _masterVolume = volume;
    StorageService.setMasterVolume(volume);
    _audioService.setVolume(volume);
    notifyListeners();
  }

  void setWifiEnabled(bool enabled) {
    _wifiEnabled = enabled;
    StorageService.setWifiEnabled(enabled);
    notifyListeners();
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    StorageService.setNotificationsEnabled(enabled);
    notifyListeners();
  }

  void setGoogleSyncEnabled(bool enabled) {
    _googleSyncEnabled = enabled;
    StorageService.setBool('google_sync', enabled);
    notifyListeners();
  }

  void setGoogleAccount(String account) {
    _googleAccount = account;
    StorageService.setString('google_account', account);
    notifyListeners();
  }

  Future<void> openTerminal() async {
    await SystemService.openTerminal();
  }

  AudioService get audioService => _audioService;
}
