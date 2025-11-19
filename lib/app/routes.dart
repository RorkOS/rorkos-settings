import 'package:flutter/material.dart';
import '../features/settings/presentation/pages/main_settings_page.dart';
import '../features/settings/presentation/pages/display_settings_page.dart';
import '../features/settings/presentation/pages/network_settings_page.dart';
import '../features/settings/presentation/pages/update_settings_page.dart';
import '../features/settings/presentation/pages/system_info_page.dart';
import '../features/settings/presentation/pages/bluetooth_settings_page.dart';
import '../features/settings/presentation/pages/appearance_settings_page.dart';
import '../features/settings/presentation/pages/sound_settings_page.dart';
import '../features/settings/presentation/pages/language_region_page.dart';
import '../features/settings/presentation/pages/google_sync_page.dart';
import '../features/settings/presentation/pages/installed_apps_page.dart';
import '../features/settings/presentation/pages/notifications_page.dart';
import '../features/settings/presentation/pages/printers_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const MainSettingsPage(),
  '/updates': (context) => const UpdateSettingsPage(),
  '/system': (context) => const SystemInfoPage(),
  '/display': (context) => const DisplaySettingsPage(),
  '/network': (context) => const NetworkSettingsPage(),
  '/bluetooth': (context) => const BluetoothSettingsPage(),
  '/appearance': (context) => const AppearanceSettingsPage(),
  '/sound': (context) => const SoundSettingsPage(),
  '/language': (context) => const LanguageRegionPage(),
  '/google-sync': (context) => const GoogleSyncPage(),
  '/apps': (context) => const InstalledAppsPage(),
  '/notifications': (context) => const NotificationsPage(),
  '/printers': (context) => const PrintersPage(),
};
