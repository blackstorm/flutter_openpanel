class OpenpanelState {
  final String? deviceId;
  final String? profileId;
  final bool isCollectionEnabled;
  final Map<String, dynamic> properties;
  final bool isTracingSampled;

  const OpenpanelState({
    this.deviceId,
    this.profileId,
    this.isCollectionEnabled = true,
    this.properties = const {},
    this.isTracingSampled = true,
  });

  factory OpenpanelState.fromJson(Map<String, dynamic> json) {
    return OpenpanelState(
      deviceId: json['deviceId'] as String?,
      profileId: json['profileId'] as String?,
      properties: Map<String, dynamic>.from(
        (json['properties'] as Map?) ?? const {},
      ),
      isCollectionEnabled: json['isCollectionEnabled'] as bool? ?? true,
      isTracingSampled: json['isTracingSampled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'profileId': profileId,
        'properties': properties,
        'isCollectionEnabled': isCollectionEnabled,
        'isTracingSampled': isTracingSampled,
      };

  OpenpanelState copyWith({
    String? deviceId,
    String? profileId,
    Map<String, dynamic>? properties,
    bool? isCollectionEnabled,
    bool? isTracingSampled,
  }) {
    return OpenpanelState(
      deviceId: deviceId ?? this.deviceId,
      profileId: profileId ?? this.profileId,
      properties: properties ?? this.properties,
      isCollectionEnabled: isCollectionEnabled ?? this.isCollectionEnabled,
      isTracingSampled: isTracingSampled ?? this.isTracingSampled,
    );
  }
}
