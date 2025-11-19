import 'package:flutter/material.dart';

class LanguageRegionPage extends StatefulWidget {
  const LanguageRegionPage({super.key});

  @override
  State<LanguageRegionPage> createState() => _LanguageRegionPageState();
}

class _LanguageRegionPageState extends State<LanguageRegionPage> {
  String _selectedLanguage = 'English (United States)';
  String _selectedRegion = 'United States';
  String _timeFormat = '12-hour';
  String _dateFormat = 'MM/DD/YYYY';
  String _firstDayOfWeek = 'Sunday';
  bool _automaticTimezone = true;

  final List<String> _languages = [
    'English (United States)',
    'English (United Kingdom)',
    'Spanish',
    'French',
    'German',
    'Russian',
    'Chinese',
    'Japanese'
  ];

  final List<String> _regions = [
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Japan',
    'Russia'
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language & Region'),
      ),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'Language',
            children: [
              _DropdownSetting(
                title: 'Language',
                value: _selectedLanguage,
                options: _languages,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Region',
            children: [
              _DropdownSetting(
                title: 'Region',
                value: _selectedRegion,
                options: _regions,
                onChanged: (value) {
                  setState(() {
                    _selectedRegion = value!;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Automatic Timezone'),
                subtitle: const Text('Set timezone automatically based on location'),
                value: _automaticTimezone,
                onChanged: (value) {
                  setState(() {
                    _automaticTimezone = value;
                  });
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Formats',
            children: [
              _DropdownSetting(
                title: 'Time Format',
                value: _timeFormat,
                options: const ['12-hour', '24-hour'],
                onChanged: (value) {
                  setState(() {
                    _timeFormat = value!;
                  });
                },
              ),
              _DropdownSetting(
                title: 'Date Format',
                value: _dateFormat,
                options: const ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'],
                onChanged: (value) {
                  setState(() {
                    _dateFormat = value!;
                  });
                },
              ),
              _DropdownSetting(
                title: 'First Day of Week',
                value: _firstDayOfWeek,
                options: const ['Sunday', 'Monday'],
                onChanged: (value) {
                  setState(() {
                    _firstDayOfWeek = value!;
                  });
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Examples',
            children: [
              ListTile(
                title: const Text('Date'),
                subtitle: Text(_getFormattedDate()),
              ),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(_getFormattedTime()),
              ),
              ListTile(
                title: const Text('Number Format'),
                subtitle: const Text('1,234.56'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    switch (_dateFormat) {
      case 'MM/DD/YYYY':
        return '12/25/2024';
      case 'DD/MM/YYYY':
        return '25/12/2024';
      case 'YYYY-MM-DD':
        return '2024-12-25';
      default:
        return '12/25/2024';
    }
  }

  String _getFormattedTime() {
    switch (_timeFormat) {
      case '12-hour':
        return '2:30 PM';
      case '24-hour':
        return '14:30';
      default:
        return '2:30 PM';
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _DropdownSetting({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
    );
  }
}
