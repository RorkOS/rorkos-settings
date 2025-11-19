class DisplaySettings {
  final String selectedDisplay;
  final String resolution;
  final double refreshRate;
  final double scale;
  final double brightness;
  final bool nightLight;
  final bool autoRotate;

  const DisplaySettings({
    this.selectedDisplay = '',
    this.resolution = '1920x1080',
    this.refreshRate = 60.0,
    this.scale = 1.0,
    this.brightness = 0.7,
    this.nightLight = false,
    this.autoRotate = true,
  });

  DisplaySettings copyWith({
    String? selectedDisplay,
    String? resolution,
    double? refreshRate,
    double? scale,
    double? brightness,
    bool? nightLight,
    bool? autoRotate,
  }) {
    return DisplaySettings(
      selectedDisplay: selectedDisplay ?? this.selectedDisplay,
      resolution: resolution ?? this.resolution,
      refreshRate: refreshRate ?? this.refreshRate,
      scale: scale ?? this.scale,
      brightness: brightness ?? this.brightness,
      nightLight: nightLight ?? this.nightLight,
      autoRotate: autoRotate ?? this.autoRotate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selectedDisplay': selectedDisplay,
      'resolution': resolution,
      'refreshRate': refreshRate,
      'scale': scale,
      'brightness': brightness,
      'nightLight': nightLight,
      'autoRotate': autoRotate,
    };
  }

  factory DisplaySettings.fromMap(Map<String, dynamic> map) {
    return DisplaySettings(
      selectedDisplay: map['selectedDisplay'] ?? '',
      resolution: map['resolution'] ?? '1920x1080',
      refreshRate: (map['refreshRate'] ?? 60.0).toDouble(),
      scale: (map['scale'] ?? 1.0).toDouble(),
      brightness: (map['brightness'] ?? 0.7).toDouble(),
      nightLight: map['nightLight'] ?? false,
      autoRotate: map['autoRotate'] ?? true,
    );
  }
}

class DisplayInfo {
  final String name;
  final String description;
  final bool connected;

  const DisplayInfo({
    required this.name,
    required this.description,
    required this.connected,
  });
}

class DisplayMode {
  final String resolution;
  final double refreshRate;

  const DisplayMode({
    required this.resolution,
    required this.refreshRate,
  });
}
