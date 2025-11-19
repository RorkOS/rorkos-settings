import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/settings_provider.dart';
import 'routes.dart';

class RorkOSApp extends StatelessWidget {
  const RorkOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return MaterialApp(
          title: 'RorkOS Settings',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: settingsProvider.themeMode == ThemeMode.dark 
                  ? Colors.blue.shade800 
                  : Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: settingsProvider.themeMode,
          initialRoute: '/',
          routes: appRoutes,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
