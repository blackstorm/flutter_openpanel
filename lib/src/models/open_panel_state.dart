class OpenpanelState {
  final String? deviceId;

  /// Older SDK versions stored a hardware-derived id here. Those values are
  /// replaced on the next startup instead of being sent again.
  final bool deviceIdIsHardware;
  final String? profileId;
  final bool isCollectionEnabled;
  final Map<String, dynamic> properties;
  final bool isTracingSampled;

  const OpenpanelState({
    this.deviceId,
    this.deviceIdIsHardware = false,
    this.profileId,
    this.isCollectionEnabled = true,
    this.properties = const {},
    this.isTracingSampled = true,
  });

  factory OpenpanelState.fromJson(Map<String, dynamic> json) {
    return OpenpanelState(
      deviceId: json['deviceId'] as String?,
      // Legacy persisted state did not carry this marker and therefore may
      // contain Android ID / identifierForVendor collected by an old build.
      deviceIdIsHardware: json['deviceIdIsHardware'] as bool? ?? true,
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
    'deviceIdIsHardware': deviceIdIsHardware,
    'profileId': profileId,
    'properties': properties,
    'isCollectionEnabled': isCollectionEnabled,
    'isTracingSampled': isTracingSampled,
  };

  /// Use [clearProfileId] to set [profileId] back to null.
  OpenpanelState copyWith({
    String? deviceId,
    bool? deviceIdIsHardware,
    String? profileId,
    Map<String, dynamic>? properties,
    bool? isCollectionEnabled,
    bool? isTracingSampled,
    bool clearProfileId = false,
  }) {
    return OpenpanelState(
      deviceId: deviceId ?? this.deviceId,
      deviceIdIsHardware: deviceIdIsHardware ?? this.deviceIdIsHardware,
      profileId: clearProfileId ? null : (profileId ?? this.profileId),
      properties: properties ?? this.properties,
      isCollectionEnabled: isCollectionEnabled ?? this.isCollectionEnabled,
      isTracingSampled: isTracingSampled ?? this.isTracingSampled,
    );
  }
}
