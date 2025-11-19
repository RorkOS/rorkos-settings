import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                const ListTile(
                  title: Text('Theme Mode'),
                  subtitle: Text('Choose light, dark or system theme'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System Default'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (ThemeMode? value) {
                      if (value != null) {
                        settings.setTheme(value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const ListTile(
                  title: Text('Accent Color'),
                  subtitle: Text('Choose your primary color'),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ColorOption(color: Colors.blue, currentTheme: settings.themeMode),
                      _ColorOption(color: Colors.green, currentTheme: settings.themeMode),
                      _ColorOption(color: Colors.orange, currentTheme: settings.themeMode),
                      _ColorOption(color: Colors.purple, currentTheme: settings.themeMode),
                      _ColorOption(color: Colors.pink, currentTheme: settings.themeMode),
                      _ColorOption(color: Colors.red, currentTheme: settings.themeMode),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                const ListTile(
                  title: Text('Font Settings'),
                  subtitle: Text('Customize text appearance'),
                ),
                ListTile(
                  title: const Text('Font Size'),
                  subtitle: Slider(
                    value: settings.fontSize,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    label: '${settings.fontSize.toInt()}',
                    onChanged: (value) {
                      settings.setFontSize(value);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Font Family'),
                  subtitle: DropdownButton<String>(
                    value: settings.fontFamily,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                      DropdownMenuItem(value: 'Arial', child: Text('Arial')),
                      DropdownMenuItem(value: 'Helvetica', child: Text('Helvetica')),
                      DropdownMenuItem(value: 'Ubuntu', child: Text('Ubuntu')),
                      DropdownMenuItem(value: 'DejaVu Sans', child: Text('DejaVu Sans')),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        settings.setFontFamily(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final ThemeMode currentTheme;

  const _ColorOption({
    required this.color,
    required this.currentTheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: currentTheme == ThemeMode.dark ? Colors.white : Colors.black,
            width: 2,
          ),
        ),
      ),
    );
  }
}
