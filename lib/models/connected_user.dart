class ConnectedUser {
  final String id;
  final String name;
  final String profileImage;

  const ConnectedUser({
    required this.id,
    required this.name,
    required this.profileImage,
  });

  factory ConnectedUser.fromJson(Map<String, dynamic> json) {
    return ConnectedUser(
      id: json['uid'] as String,
      name: json['name'] as String? ?? 'User',
      profileImage: json['profileImage'] as String? ?? '',
    );
  }
}
