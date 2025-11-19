import 'dart:async';

class NotificationService {
  final StreamController<bool> _settingsController = StreamController<bool>.broadcast();
  
  Stream<bool> get settingsStream => _settingsController.stream;

  void enableAllNotifications(bool enabled) {
    _settingsController.add(enabled);
  }

  void dispose() {
    _settingsController.close();
  }
}
