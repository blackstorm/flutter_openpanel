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

  Map<String, dynamic> toJson() => {
        'name': name,
        'timestamp': timestamp,
        'deviceId': deviceId,
        'profileId': profileId,
        'properties': properties,
      };
}
