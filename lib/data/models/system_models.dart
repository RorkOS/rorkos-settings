class SystemApplication {
  final String name;
  final String path;
  final String type;
  final int size;

  SystemApplication({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
  });
}

class WiFiNetwork {
  final String ssid;
  final int signal;
  final String security;
  final bool connected;

  WiFiNetwork({
    required this.ssid,
    required this.signal,
    required this.security,
    required this.connected,
  });
}

class BluetoothDevice {
  final String name;
  final String address;
  final bool connected;
  final String type;

  BluetoothDevice({
    required this.name,
    required this.address,
    required this.connected,
    required this.type,
  });
}
