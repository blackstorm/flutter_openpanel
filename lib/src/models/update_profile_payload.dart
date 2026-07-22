class UpdateProfilePayload {
  final String profileId;
  final String? firstName;
  final String? lastName;
  final String? avatar;
  final String? email;
  final Map<String, dynamic> properties;

  const UpdateProfilePayload({
    required this.profileId,
    this.firstName,
    this.lastName,
    this.avatar,
    this.email,
    this.properties = const {},
  });

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'firstName': firstName,
        'lastName': lastName,
        'avatar': avatar,
        'email': email,
        'properties': properties,
      };
}
