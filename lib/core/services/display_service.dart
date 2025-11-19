import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/display_settings_model.dart';
import '../utils/logger.dart';

class DisplayService {
  static const _logTag = 'DisplayService';
  
  static Future<Map<String, bool>> _checkAvailableTools() async {
    final tools = {
      'brightnessctl': false,
      'xrandr': false,
      'redshift': false,
      'cvt': false,
      'gsettings': false,
    };

    try {
      for (final tool in tools.keys.toList()) {
        final result = await Process.run('which', [tool], runInShell: true);
        tools[tool] = (result.exitCode == 0 && result.stdout.toString().isNotEmpty);
      }
    } catch (e) {
      Logger.error(_logTag, 'Ошибка проверки утилит: $e');
    }
    
    return tools;
  }
  
  static Future<List<DisplayInfo>> getDisplays() async {
    final displays = <DisplayInfo>[];
    try {
      final result = await Process.run('xrandr', [], runInShell: true);
      final lines = result.stdout.toString().split('\n');
      
      for (final line in lines) {
        if (line.contains(' connected')) {
          final parts = line.split(' ');
          final name = parts[0];
          displays.add(DisplayInfo(
            name: name,
            description: line,
          ));
        }
      }
      
      if (displays.isEmpty) {
        displays.add(const DisplayInfo(
          name: 'default',
          description: 'Основной дисплей',
        ));
      }
      
      Logger.info(_logTag, 'Найдено дисплеев: ${displays.length}');
    } catch (e) {
      Logger.error(_logTag, 'Ошибка получения списка дисплеев: $e');
      displays.add(const DisplayInfo(
        name: 'default',
        description: 'Основной дисплей (ошибка получения информации)',
      ));
    }
    
    return displays;
  }
  
  static Future<List<DisplayMode>> getDisplayModes(String display) async {
    final modes = <DisplayMode>[];
    final tools = await _checkAvailableTools();
    
    try {
      if (tools['xrandr'] == true) {
        final result = await Process.run('xrandr', [], runInShell: true);
        final lines = result.stdout.toString().split('\n');
        bool foundDisplay = false;
        
        for (final line in lines) {
          if (line.contains('$display connected')) {
            foundDisplay = true;
            continue;
          }
          
          if (foundDisplay) {
            final trimmed = line.trim();
            final modeMatch = RegExp(r'(\d+x\d+)\s+(\d+\.\d+)(\s+\*)?').firstMatch(trimmed);
            if (modeMatch != null) {
              final resolution = modeMatch.group(1)!;
              final refreshRate = double.tryParse(modeMatch.group(2)!) ?? 60.0;
              
              if (!modes.any((mode) => mode.resolution == resolution && mode.refreshRate == refreshRate)) {
                modes.add(DisplayMode(
                  resolution: resolution,
                  refreshRate: refreshRate,
                ));
              }
            }
            
            if (trimmed.isEmpty || trimmed.startsWith(' ')) continue;
            if (!trimmed.contains('x')) break;
          }
        }
      }
      
      if (modes.isEmpty) {
        modes.addAll([
          const DisplayMode(resolution: '1920x1080', refreshRate: 60.0),
          const DisplayMode(resolution: '1920x1080', refreshRate: 75.0),
          const DisplayMode(resolution: '1920x1080', refreshRate: 120.0),
          const DisplayMode(resolution: '2560x1440', refreshRate: 60.0),
          const DisplayMode(resolution: '3840x2160', refreshRate: 60.0),
        ]);
      }
      
      Logger.info(_logTag, 'Найдено режимов для $display: ${modes.length}');
    } catch (e) {
      Logger.error(_logTag, 'Ошибка получения режимов для $display: $e');
      modes.addAll([
        const DisplayMode(resolution: '1920x1080', refreshRate: 60.0),
        const DisplayMode(resolution: '1920x1080', refreshRate: 75.0),
        const DisplayMode(resolution: '1920x1080', refreshRate: 120.0),
      ]);
    }
    
    return modes;
  }
  
  // Получение текущей яркости
  static Future<double> getCurrentBrightness() async {
    final tools = await _checkAvailableTools();
    double brightness = 0.7;     
    try {
      if (tools['brightnessctl'] == true) {
        final currentResult = await Process.run('brightnessctl', ['g'], runInShell: true);
        final maxResult = await Process.run('brightnessctl', ['m'], runInShell: true);
        
        if (currentResult.exitCode == 0 && maxResult.exitCode == 0) {
          final current = int.tryParse(currentResult.stdout.toString().trim()) ?? 0;
          final max = int.tryParse(maxResult.stdout.toString().trim()) ?? 1;
          brightness = current / max;
        }
      } else {
        final backlightDir = Directory('/sys/class/backlight');
        if (await backlightDir.exists()) {
          await for (var entity in backlightDir.list()) {
            if (entity is Directory) {
              final maxFile = File('${entity.path}/max_brightness');
              final brightnessFile = File('${entity.path}/brightness');
              
              if (await maxFile.exists() && await brightnessFile.exists()) {
                final maxContent = await maxFile.readAsString();
                final brightnessContent = await brightnessFile.readAsString();
                
                final maxBrightness = int.tryParse(maxContent.trim()) ?? 255;
                final currentBrightness = int.tryParse(brightnessContent.trim()) ?? 128;
                
                brightness = currentBrightness / maxBrightness;
                break;
              }
            }
          }
        }
      }
      
      Logger.info(_logTag, 'Текущая яркость: $brightness');
    } catch (e) {
      Logger.error(_logTag, 'Ошибка получения яркости: $e');
    }
    
    return brightness.clamp(0.0, 1.0);
  }
  
  static Future<void> setBrightness(double brightness) async {
    final tools = await _checkAvailableTools();
    brightness = brightness.clamp(0.0, 1.0);
    
    try {
      if (tools['brightnessctl'] == true) {
        final percent = (brightness * 100).round();
        await Process.run('brightnessctl', ['set', '$percent%'], runInShell: true);
        Logger.info(_logTag, 'Яркость установлена через brightnessctl: $percent%');
      } else {
        final backlightDir = Directory('/sys/class/backlight');
        if (await backlightDir.exists()) {
          await for (var entity in backlightDir.list()) {
            if (entity is Directory) {
              final maxFile = File('${entity.path}/max_brightness');
              final brightnessFile = File('${entity.path}/brightness');
              
              if (await maxFile.exists() && await brightnessFile.exists()) {
                final maxContent = await maxFile.readAsString();
                final maxBrightness = int.tryParse(maxContent.trim()) ?? 255;
                final newBrightness = (brightness * maxBrightness).round();
                
                await brightnessFile.writeAsString(newBrightness.toString());
                Logger.info(_logTag, 'Яркость установлена через sysfs: $newBrightness/$maxBrightness');
                break;
              }
            }
          }
        }
      }
    } catch (e) {
      Logger.error(_logTag, 'Ошибка установки яркости: $e');
      try {
        if (tools['xrandr'] == true) {
          final displays = await getDisplays();
          if (displays.isNotEmpty) {
            final display = displays.first.name;
            await Process.run('xrandr', ['--output', display, '--brightness', brightness.toString()], runInShell: true);
            Logger.info(_logTag, 'Яркость установлена через xrandr: $brightness');
          }
        }
      } catch (e2) {
        Logger.error(_logTag, 'Альтернативный метод тоже не сработал: $e2');
      }
    }
  }
  
  // Переключение ночного света
  static Future<void> setNightLight(bool enabled) async {
    final tools = await _checkAvailableTools();
    
    try {
      if (enabled) {
        if (tools['redshift'] == true) {
          await Process.run('redshift', ['-O', '3500'], runInShell: true);
          Logger.info(_logTag, 'Ночной свет включен через redshift');
        } 
        else if (tools['gsettings'] == true) {
          await Process.run('gsettings', [
            'set', 'org.gnome.settings-daemon.plugins.color', 'night-light-enabled', 'true'
          ], runInShell: true);
          Logger.info(_logTag, 'Ночной свет включен через gsettings');
        }
      } else {
        if (tools['redshift'] == true) {
          await Process.run('redshift', ['-x'], runInShell: true);
          Logger.info(_logTag, 'Ночной свет выключен через redshift');
        } 
        else if (tools['gsettings'] == true) {
          await Process.run('gsettings', [
            'set', 'org.gnome.settings-daemon.plugins.color', 'night-light-enabled', 'false'
          ], runInShell: true);
          Logger.info(_logTag, 'Ночной свет выключен через gsettings');
        }
      }
    } catch (e) {
      Logger.error(_logTag, 'Ошибка переключения ночного света: $e');
    }
  }
  
  static Future<bool> isNightLightEnabled() async {
    final tools = await _checkAvailableTools();
    bool enabled = false;
    
    try {
      if (tools['gsettings'] == true) {
        final result = await Process.run('gsettings', [
          'get', 'org.gnome.settings-daemon.plugins.color', 'night-light-enabled'
        ], runInShell: true);
        
        if (result.exitCode == 0) {
          enabled = result.stdout.toString().trim() == 'true';
        }
      } else if (tools['redshift'] == true) {
        final result = await Process.run('pgrep', ['redshift'], runInShell: true);
        enabled = result.exitCode == 0;
      }
      
      Logger.info(_logTag, 'Статус ночного света: $enabled');
    } catch (e) {
      Logger.error(_logTag, 'Ошибка проверки статуса ночного света: $e');
    }
    
    return enabled;
  }
  
  // Генерация modeline для xrandr
  static Future<String> generateModeline(int width, int height, double refreshRate) async {
    String modeline = '';
    final tools = await _checkAvailableTools();
    
    try {
      if (tools['cvt'] == true) {
        final result = await Process.run('cvt', [
          width.toString(), 
          height.toString(), 
          refreshRate.toStringAsFixed(1)
        ], runInShell: true);
        
        if (result.exitCode == 0) {
          final output = result.stdout.toString();
          final match = RegExp(r'Modeline\s+"([^"]+)"\s+([\d.]+)\s+(\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+-hsync\s+\+vsync)').firstMatch(output);
          
          if (match != null) {
            modeline = match.group(0)!;
            Logger.info(_logTag, 'Сгенерирована modeline: $modeline');
          }
        }
      }
    } catch (e) {
      Logger.error(_logTag, 'Ошибка генерации modeline: $e');
    }
    
    return modeline;
  }
  
  static Future<void> changeResolution(String display, String resolution, double refreshRate) async {
    final tools = await _checkAvailableTools();
    
    try {
      if (tools['xrandr'] == true) {
        final parts = resolution.split('x');
        if (parts.length == 2) {
          final width = int.tryParse(parts[0]) ?? 1920;
          final height = int.tryParse(parts[1]) ?? 1080;
          
          final modeline = await generateModeline(width, height, refreshRate);
          
          if (modeline.isNotEmpty) {
            final modeNameMatch = RegExp(r'"([^"]+)"').firstMatch(modeline);
            if (modeNameMatch != null) {
              final modeName = modeNameMatch.group(1)!;
              
              await Process.run('xrandr', ['--newmode'] + modeline.split(' ').where((e) => e.isNotEmpty).toList(), runInShell: true);
              await Process.run('xrandr', ['--addmode', display, modeName], runInShell: true);
              await Process.run('xrandr', ['--output', display, '--mode', modeName], runInShell: true);
              
              Logger.info(_logTag, 'Разрешение изменено: $resolution @ $refreshRate Гц');
            }
          } else {
            await Process.run('xrandr', ['--output', display, '--mode', resolution], runInShell: true);
            Logger.info(_logTag, 'Стандартное разрешение изменено: $resolution');
          }
        }
      }
    } catch (e) {
      Logger.error(_logTag, 'Ошибка изменения разрешения: $e');
    }
  }
  
  static Future<void> setScaling(String display, double scale) async {
    final tools = await _checkAvailableTools();
    scale = scale.clamp(0.5, 3.0);
    
    try {
      if (tools['xrandr'] == true) {
        await Process.run('xrandr', [
          '--output', display, 
          '--scale', '${scale}x$scale'
        ], runInShell: true);
        Logger.info(_logTag, 'Масштабирование установлено через xrandr: $scale');
      }
      
      if (tools['gsettings'] == true) {
        await Process.run('gsettings', [
          'set', 'org.gnome.desktop.interface', 'text-scaling-factor', scale.toString()
        ], runInShell: true);
        Logger.info(_logTag, 'Масштабирование текста установлено через gsettings: $scale');
      }
    } catch (e) {
      Logger.error(_logTag, 'Ошибка установки масштабирования: $e');
    }
  }
  
  static Future<double> getCurrentScaling() async {
    final tools = await _checkAvailableTools();
    double scale = 1.0;
    
    try {
      if (tools['gsettings'] == true) {
        final result = await Process.run('gsettings', [
          'get', 'org.gnome.desktop.interface', 'text-scaling-factor'
        ], runInShell: true);
        
        if (result.exitCode == 0) {
          final scaleText = result.stdout.toString().trim();
          scale = double.tryParse(scaleText) ?? 1.0;
          Logger.info(_logTag, 'Текущее масштабирование: $scale');
        }
      }
    } catch (e) {
      Logger.error(_logTag, 'Ошибка получения масштабирования: $e');
    }
    
    return scale;
  }
  
  static Future<void> setAutoRotate(bool enabled) async {
    final tools = await _checkAvailableTools();
    
    try {
      if (tools['gsettings'] == true) {
        await Process.run('gsettings', [
          'set', 'org.gnome.settings-daemon.peripherals.touchscreen', 
          'orientation-lock', enabled ? 'false' : 'true'
        ], runInShell: true);
        
        Logger.info(_logTag, 'Автоповорот ${enabled ? 'включен' : 'выключен'}');
      }
    } catch (e) {
      Logger.error(_logTag, 'Ошибка переключения автоповорота: $e');
    }
  }
}
