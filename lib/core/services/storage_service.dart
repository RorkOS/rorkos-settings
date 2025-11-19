import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;
  
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }
  
  static double getMasterVolume() {
    return prefs.getDouble('master_volume') ?? 0.7;
  }
  
  static void setMasterVolume(double volume) {
    prefs.setDouble('master_volume', volume);
  }
  
  static bool getWifiEnabled() {
    return prefs.getBool('wifi_enabled') ?? true;
  }
  
  static void setWifiEnabled(bool enabled) {
    prefs.setBool('wifi_enabled', enabled);
  }
  
  static bool getNotificationsEnabled() {
    return prefs.getBool('notifications_enabled') ?? true;
  }
  
  static void setNotificationsEnabled(bool enabled) {
    prefs.setBool('notifications_enabled', enabled);
  }
  
  static double getBrightness() {
    return prefs.getDouble('brightness') ?? 0.8;
  }
  
  static void setBrightness(double brightness) {
    prefs.setDouble('brightness', brightness);
  }
  
  static String getTheme() {
    return prefs.getString('theme') ?? 'system';
  }
  
  static void setTheme(String theme) {
    prefs.setString('theme', theme);
  }
  
  static bool getBool(String key) {
    return prefs.getBool(key) ?? false;
  }
  
  static void setBool(String key, bool value) {
    prefs.setBool(key, value);
  }
  
  static String getString(String key) {
    return prefs.getString(key) ?? '';
  }
  
  static void setString(String key, String value) {
    prefs.setString(key, value);
  }
}
