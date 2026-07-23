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

  factory PostEventPayload.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final timestamp = json['timestamp'];
    if (name is! String ||
        name.trim().isEmpty ||
        timestamp is! String ||
        timestamp.trim().isEmpty) {
      throw const FormatException('Invalid queued OpenPanel event');
    }
    return PostEventPayload(
      name: name,
      timestamp: timestamp,
      deviceId: json['deviceId'] as String?,
      profileId: json['profileId'] as String?,
      properties: Map<String, dynamic>.from(
        (json['properties'] as Map?) ?? const <String, dynamic>{},
      ),
    );
  }
}
