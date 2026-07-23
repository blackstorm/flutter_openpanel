class PostEventPayload {
  final String name;
  final String timestamp;
  final String? deviceId;
  final String? profileId;
  final Map<String, dynamic> properties;

  const PostEventPayload({
    required this.name,
    required this.timestamp,
    this.deviceId,
    this.profileId,
    this.properties = const {},
  });

  /// Omits null ids — anonymous traffic should not send `profileId`.
  Map<String, dynamic> toJson() => {
        'name': name,
        'timestamp': timestamp,
        if (deviceId != null) 'deviceId': deviceId,
        if (profileId != null) 'profileId': profileId,
        'properties': properties,
      };
}
