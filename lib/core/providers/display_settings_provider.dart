import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/display_settings_model.dart';
import '../services/display_service.dart';
import '../utils/logger.dart';

class DisplaySettingsProvider with ChangeNotifier {
  static const _logTag = 'DisplaySettingsProvider';
  static const _prefsKey = 'display_settings';
  
  DisplaySettings _settings = const DisplaySettings(
    selectedDisplay: '',
    brightness: 0.7,
    nightLightEnabled: false,
    resolution: '1920x1080',
    refreshRate: 60.0,
    scale: 1.0,
    autoRotate: true,
  );
  
  DisplaySettings get settings => _settings;
  
  List<DisplayInfo> _displays = [];
  List<DisplayInfo> get displays => _displays;
  
  List<DisplayMode> _modes = [];
  List<DisplayMode> get modes => _modes;
  
  bool _isLoading = true;
  bool get isLoading => _isLoading;
  
  bool _hasError = false;
  bool get hasError => _hasError;
  
  String _errorMessage = '';
  String get errorMessage => _errorMessage;
  
  DisplaySettingsProvider() {
    _init();
  }
  
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loadSettings();
      
      await _loadDisplays();
      
      await _loadSystemSettings();
      
      _hasError = false;
      _errorMessage = '';
    } catch (e) {
      Logger.error(_logTag, 'Ошибка инициализации: $e');
      _hasError = true;
      _errorMessage = 'Ошибка загрузки настроек дисплея';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_prefsKey);
    
    if (settingsJson != null) {
      try {
        final settingsMap = Map<String, dynamic>.from(json.decode(settingsJson));
        _settings = DisplaySettings.fromMap(settingsMap);
        Logger.info(_logTag, 'Настройки загружены из SharedPreferences');
      } catch (e) {
        Logger.error(_logTag, 'Ошибка загрузки настроек из SharedPreferences: $e');
      }
    }
  }
  
  Future<void> _loadDisplays() async {
    _displays = await DisplayService.getDisplays();
    Logger.info(_logTag, 'Загружено дисплеев: ${_displays.length}');
    
    if (_displays.isNotEmpty) {
      if (_settings.selectedDisplay.isEmpty || !_displays.any((d) => d.name == _settings.selectedDisplay)) {
        _settings = _settings.copyWith(selectedDisplay: _displays.first.name);
      }
      
      await _loadDisplayModes(_settings.selectedDisplay);
    }
  }
  
  Future<void> _loadDisplayModes(String display) async {
    _modes = await DisplayService.getDisplayModes(display);
    Logger.info(_logTag, 'Загружено режимов для $display: ${_modes.length}');
    
    final currentResolution = _modes.firstWhere(
      (mode) => mode.resolution == _settings.resolution && mode.refreshRate == _settings.refreshRate,
      orElse: () => _modes.first
    );
    
    if (currentResolution.resolution != _settings.resolution || currentResolution.refreshRate != _settings.refreshRate) {
      _settings = _settings.copyWith(
        resolution: currentResolution.resolution,
        refreshRate: currentResolution.refreshRate
      );
    }
  }
  
  Future<void> _loadSystemSettings() async {
    try {
      final currentBrightness = await DisplayService.getCurrentBrightness();
      _settings = _settings.copyWith(brightness: currentBrightness);
      
      final nightLightEnabled = await DisplayService.isNightLightEnabled();
      _settings = _settings.copyWith(nightLightEnabled: nightLightEnabled);
      
      final currentScale = await DisplayService.getCurrentScaling();
      _settings = _settings.copyWith(scale: currentScale);
    } catch (e) {
      Logger.error(_logTag, 'Ошибка загрузки системных настроек: $e');
    }
  }
  
  Future<void> reload() async {
    await _init();
  }
  
  Future<void> selectDisplay(String displayName) async {
    if (!_displays.any((d) => d.name == displayName)) return;
    
    _settings = _settings.copyWith(selectedDisplay: displayName);
    await _loadDisplayModes(displayName);
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setResolution(String resolution, double refreshRate) async {
    final mode = _modes.firstWhere(
      (m) => m.resolution == resolution && m.refreshRate == refreshRate,
      orElse: () => _modes.first
    );
    
    _settings = _settings.copyWith(
      resolution: mode.resolution,
      refreshRate: mode.refreshRate
    );
    
    if (_settings.selectedDisplay.isNotEmpty) {
      await DisplayService.changeResolution(
        _settings.selectedDisplay, 
        _settings.resolution, 
        _settings.refreshRate
      );
    }
    
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setBrightness(double brightness) async {
    brightness = brightness.clamp(0.0, 1.0);
    _settings = _settings.copyWith(brightness: brightness);
    
    await DisplayService.setBrightness(brightness);
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> toggleNightLight(bool enabled) async {
    _settings = _settings.copyWith(nightLightEnabled: enabled);
    await DisplayService.setNightLight(enabled);
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> setScaling(double scale) async {
    scale = scale.clamp(0.5, 3.0);
    _settings = _settings.copyWith(scale: scale);
    
    if (_settings.selectedDisplay.isNotEmpty) {
      await DisplayService.setScaling(_settings.selectedDisplay, scale);
    }
    
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> toggleAutoRotate(bool enabled) async {
    _settings = _settings.copyWith(autoRotate: enabled);
    await DisplayService.setAutoRotate(enabled);
    await _saveSettings();
    notifyListeners();
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(_settings.toMap()));
    Logger.info(_logTag, 'Настройки сохранены в SharedPreferences');
  }
}
