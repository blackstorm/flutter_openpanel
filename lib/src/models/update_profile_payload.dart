/// OpenPanel identify payload.
///
/// Prefer [Openpanel.identify] with an internal UID only. Optional name/email
/// fields exist for API completeness — product apps should not send PII.
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
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (avatar != null) 'avatar': avatar,
        if (email != null) 'email': email,
        if (properties.isNotEmpty) 'properties': properties,
      };
}
