class BluetoothDevice {
  final String name;
  final String address;
  bool connected;
  final String type;

  BluetoothDevice({
    required this.name,
    required this.address,
    required this.connected,
    required this.type,
  });
}

