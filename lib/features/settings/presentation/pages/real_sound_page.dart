import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/settings_provider.dart';

class RealSoundPage extends StatefulWidget {
  const RealSoundPage({super.key});

  @override
  State<RealSoundPage> createState() => _RealSoundPageState();
}

class _RealSoundPageState extends State<RealSoundPage> {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    double volume = settings.volume;
    if (volume > 1.0) {
      volume = volume / 100.0;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sound')),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.volume_up),
                  title: const Text('Master Volume'),
                  subtitle: Text('${(volume * 100).round()}%'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      settings.setVolume(value);
                    },
                  ),
                ),
                SwitchListTile(
                  title: const Text('Mute'),
                  value: settings.muted,
                  onChanged: (value) => settings.setMuted(value),
                ),
              ],
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const Column(
              children: [
                ListTile(
                  title: Text('Output Devices'),
                  subtitle: Text('Speakers, Headphones'),
                ),
                ListTile(
                  leading: Icon(Icons.speaker),
                  title: Text('Built-in Audio'),
                  subtitle: Text('Analog Stereo'),
                  trailing: Chip(label: Text('Default')),
                ),
                ListTile(
                  leading: Icon(Icons.headphones),
                  title: Text('USB Headset'),
                  subtitle: Text('Digital Stereo'),
                ),
              ],
            ),
          ),

          Card(
            margin: const EdgeInsets.all(16),
            child: const Column(
              children: [
                ListTile(
                  title: Text('Input Devices'),
                  subtitle: Text('Microphones'),
                ),
                ListTile(
                  leading: Icon(Icons.mic),
                  title: Text('Built-in Microphone'),
                  subtitle: Text('Analog Mono'),
                  trailing: Chip(label: Text('Default')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
