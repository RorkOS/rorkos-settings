import 'dart:io';
import 'package:flutter/material.dart';

class PrintersPage extends StatefulWidget {
  const PrintersPage({super.key});

  @override
  State<PrintersPage> createState() => _PrintersPageState();
}

class _PrintersPageState extends State<PrintersPage> {
  List<Map<String, String>> _printers = [];
  bool _isLoading = true;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await Process.run('lpstat', ['-p']);
      final lines = result.stdout.toString().split('\n');
      
      _printers.clear();
      
      for (final line in lines) {
        if (line.startsWith('printer')) {
          final parts = line.split(' ');
          if (parts.length >= 2) {
            final printerName = parts[1];
            final status = line.contains('enabled') ? 'Доступен' : 'Недоступен';
            
            _printers.add({
              'name': printerName,
              'status': status,
              'description': await _getPrinterDescription(printerName),
            });
          }
        }
      }
      
      if (_printers.isEmpty) {
        _statusMessage = 'Принтеры не найдены';
      }
    } catch (e) {
      _statusMessage = 'Ошибка загрузки принтеров: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<String> _getPrinterDescription(String printerName) async {
    try {
      final result = await Process.run('lpstat', ['-l', '-p', printerName]);
      final output = result.stdout.toString();
      
      if (output.contains('Description:')) {
        final descLine = output.split('\n').firstWhere(
          (line) => line.contains('Description:'),
          orElse: () => ''
        );
        return descLine.replaceFirst('Description:', '').trim();
      }
    } catch (e) {
      print('Ошибка получения описания принтера: $e');
    }
    
    return 'Системный принтер';
  }

  Future<void> _addPrinter() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить принтер'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Доступные способы:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.usb),
              title: const Text('USB принтер'),
              subtitle: const Text('Автоматическое обнаружение'),
              onTap: () => _addUSBPrinter(),
            ),
            ListTile(
              leading: const Icon(Icons.network_wifi),
              title: const Text('Сетевой принтер'),
              subtitle: const Text('Добавить по IP адресу'),
              onTap: () => _addNetworkPrinter(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Future<void> _addUSBPrinter() async {
    try {
      final result = await Process.run('lpinfo', ['-v']);
      final lines = result.stdout.toString().split('\n');
      
      for (final line in lines) {
        if (line.contains('usb://')) {
          final uri = line.split(' ').last;
          final printerName = 'USB-Printer-${DateTime.now().millisecondsSinceEpoch}';
          
          await Process.run('lpadmin', ['-p', printerName, '-v', uri, '-E']);
          await _loadPrinters();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('USB принтер добавлен')),
            );
            Navigator.pop(context);
          }
          break;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка добавления USB принтера: $e')),
        );
      }
    }
  }

  Future<void> _addNetworkPrinter() async {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить сетевой принтер'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'IP адрес принтера',
            hintText: '192.168.1.100',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () async {
              final ip = controller.text.trim();
              if (ip.isEmpty) return;
              
              try {
                final printerName = 'Network-Printer-$ip';
                final uri = 'ipp://$ip/ipp/print';
                
                await Process.run('lpadmin', ['-p', printerName, '-v', uri, '-E']);
                await _loadPrinters();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Сетевой принтер добавлен')),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка добавления принтера: $e')),
                  );
                }
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _printTestPage(String printerName) async {
    try {
      await Process.run('lp', ['-d', printerName, '/etc/nsswitch.conf']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Тестовая страница отправлена на $printerName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка печати: $e')),
        );
      }
    }
  }

  Future<void> _deletePrinter(String printerName) async {
    try {
      await Process.run('lpadmin', ['-x', printerName]);
      await _loadPrinters();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Принтер $printerName удален')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления принтера: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Принтеры'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrinters,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPrinter,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _printers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.print, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Принтеры не найдены',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      if (_statusMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _statusMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.orange),
                          ),
                        ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _addPrinter,
                        child: const Text('Добавить принтер'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: [
                    if (_statusMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ..._printers.map((printer) => Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: const Icon(Icons.print),
                            title: Text(printer['name']!),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(printer['description']!),
                                const SizedBox(height: 4),
                                Text(
                                  printer['status']!,
                                  style: TextStyle(
                                    color: printer['status'] == 'Доступен'
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.print),
                                  onPressed: () => _printTestPage(printer['name']!),
                                  tooltip: 'Тестовая печать',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deletePrinter(printer['name']!),
                                  tooltip: 'Удалить принтер',
                                ),
                              ],
                            ),
                          ),
                        )),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FilledButton(
                        onPressed: _addPrinter,
                        child: const Text('Добавить принтер'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
