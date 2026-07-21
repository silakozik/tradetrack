class AppUser{
  final int id;
  final String email;
  final String? fullname;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    this.fullname,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      fullname: json['fullname'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
