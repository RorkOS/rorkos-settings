import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart'; 

class UpdateSettingsPage extends StatefulWidget {
  const UpdateSettingsPage({super.key});

  @override
  State<UpdateSettingsPage> createState() => _UpdateSettingsPageState();
}

class _UpdateSettingsPageState extends State<UpdateSettingsPage> {
  bool _isChecking = false;
  bool _isUpdatingSystem = false;
  bool _isUpdatingRorkOS = false;
  String _updateStatus = '';
  Map<String, dynamic> _updateInfo = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _updateInfo['current_version'] = prefs.getString('current_version') ?? '1.0.0';
    });
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _updateStatus = 'Проверка обновлений на GitHub...';
    });

    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(
        'https://api.github.com/repos/RorkOS/rorkos-updates/releases/latest'
      ));
      final response = await request.close();

      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final releaseData = jsonDecode(jsonString);

        String latestVersion = releaseData['tag_name'] ?? '1.0.0';
        String changelog = releaseData['body'] ?? 'Обновление системы';
        double sizeBytes = 0.0;
        
        if (releaseData['assets'] != null && releaseData['assets'].isNotEmpty) {
          for (var asset in releaseData['assets']) {
            sizeBytes += (asset['size'] ?? 0).toDouble();
          }
        }

        String sizeStr = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';

        setState(() {
          _updateInfo = {
            'current_version': _updateInfo['current_version'] ?? '1.0.0',
            'latest_version': latestVersion,
            'update_available': true,
            'changelog': changelog,
            'size': sizeStr,
            'download_url': releaseData['assets'] != null && releaseData['assets'].isNotEmpty 
                ? releaseData['assets'][0]['browser_download_url'] 
                : '',
          };
          _updateStatus = 'Доступно обновление до версии $latestVersion';
        });
      } else {
        throw Exception('Ошибка HTTP: ${response.statusCode}');
      }
      
      client.close();
    } catch (e) {
      setState(() {
        _updateStatus = 'Ошибка проверки обновлений: $e';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _updateSystemAndPackages() async {
    setState(() {
      _isUpdatingSystem = true;
      _updateStatus = 'Запуск обновления системы и пакетов...\nЗапрос прав администратора...';
    });

    try {
      final result = await Process.run('pkexec', ['pacman', '-Syu', '--noconfirm']);

      if (result.exitCode == 0) {
        setState(() {
          _updateStatus = 'Обновление системы и пакетов успешно завершено!\n${result.stdout}';
        });
      } else {
        setState(() {
          _updateStatus = 'Ошибка обновления: ${result.stderr}';
        });
      }
    } catch (e) {
      setState(() {
        _updateStatus = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isUpdatingSystem = false;
      });
    }
  }

  Future<void> _updateRorkOS() async {
    setState(() {
      _isUpdatingRorkOS = true;
      _updateStatus = 'Запуск обновления RorkOS...';
    });

    try {
      if (_updateInfo['download_url'] != null && _updateInfo['download_url'].isNotEmpty) {
        setState(() {
          _updateStatus = 'Скачивание обновления RorkOS...';
        });

        final homeDir = Platform.environment['HOME'] ?? '/tmp';
        final updatesDir = Directory('$homeDir/updates');
        
        if (await updatesDir.exists()) {
          await updatesDir.delete(recursive: true);
        }
        await updatesDir.create(recursive: true);

        final archiveFile = File('${updatesDir.path}/update.zip');
        
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(_updateInfo['download_url']));
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final bytes = await response.fold<List<int>>([], (list, data) => list..addAll(data));
          await archiveFile.writeAsBytes(bytes);
          
          setState(() {
            _updateStatus = 'Распаковка обновления...';
          });

          final archiveBytes = await archiveFile.readAsBytes();
          final archive = ZipDecoder().decodeBytes(archiveBytes);
          
          for (final file in archive) {
            final filename = '${updatesDir.path}/${file.name}';
            if (file.isFile) {
              final data = file.content as List<int>;
              await File(filename).create(recursive: true);
              await File(filename).writeAsBytes(data);
            } else {
              await Directory(filename).create(recursive: true);
            }
          }

          await archiveFile.delete();

          setState(() {
            _updateStatus = 'Запуск скрипта обновления...\nЗапрос прав администратора...';
          });

          final scriptFile = File('${updatesDir.path}/updates.sh');
          if (await scriptFile.exists()) {
            await Process.run('chmod', ['+x', scriptFile.path]);
            
            final result = await Process.run('pkexec', [scriptFile.path]);

            if (result.exitCode == 0) {
              setState(() {
                _updateStatus = 'RorkOS успешно обновлен до версии ${_updateInfo['latest_version']}!\n${result.stdout}';
              });

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('current_version', _updateInfo['latest_version']);

              _showRebootQuestion();
            } else {
              setState(() {
                _updateStatus = 'Ошибка выполнения скрипта обновления: ${result.stderr}';
              });
            }
          } else {
            setState(() {
              _updateStatus = 'Скрипт updates.sh не найден в обновлении';
            });
          }
        } else {
          throw Exception('Не удалось скачать обновление: ${response.statusCode}');
        }
        
        client.close();
      } else {
        setState(() {
          _updateStatus = 'URL для скачивания обновления не доступен';
        });
      }
    } catch (e) {
      setState(() {
        _updateStatus = 'Ошибка обновления RorkOS: $e';
      });
    } finally {
      setState(() {
        _isUpdatingRorkOS = false;
      });
    }
  }

  void _showRebootQuestion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Обновление завершено'),
        content: const Text('RorkOS успешно обновлен. Хотите перезагрузить устройство для применения изменений?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _updateStatus = 'Обновление завершено. Перезагрузите устройство позже.';
              });
            },
            child: const Text('Позже'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _rebootSystem();
            },
            child: const Text('Перезагрузить'),
          ),
        ],
      ),
    );
  }

  Future<void> _rebootSystem() async {
    setState(() {
      _updateStatus = 'Перезагрузка системы...\nЗапрос прав администратора...';
    });

    try {
      await Process.run('pkexec', ['reboot']);
    } catch (e) {
      setState(() {
        _updateStatus = 'Не удалось выполнить перезагрузку: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обновление системы'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text('Текущая версия'),
                subtitle: Text(_updateInfo['current_version'] ?? '1.0.0'),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Проверка обновлений',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_updateStatus),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _isChecking ? null : _checkForUpdates,
                            child: _isChecking
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Проверка...'),
                                    ],
                                  )
                                : const Text('Проверить обновления на GitHub'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Обновление системы',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    FilledButton(
                      onPressed: _isUpdatingSystem ? null : _updateSystemAndPackages,
                      child: _isUpdatingSystem
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Обновление системы...'),
                              ],
                            )
                          : const Text('Обновить систему и пакеты'),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    FilledButton(
                      onPressed: (_isUpdatingRorkOS || _updateInfo['update_available'] != true) 
                          ? null 
                          : _updateRorkOS,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: _isUpdatingRorkOS
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Обновление RorkOS...'),
                              ],
                            )
                          : const Text('Обновить RorkOS'),
                    ),
                  ],
                ),
              ),
            ),

            if (_updateInfo['update_available'] == true) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Доступно обновление RorkOS!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      Text('Новая версия: ${_updateInfo['latest_version']}'),
                      Text('Размер: ${_updateInfo['size']}'),
                      const SizedBox(height: 8),
                      const Text(
                        'Изменения:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_updateInfo['changelog'] ?? ''),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
