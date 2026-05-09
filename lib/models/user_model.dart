import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String role; // admin or member
  final List<String> projectIds;
  final DateTime createdAt;
  final bool isOnline;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.role,
    required this.projectIds,
    required this.createdAt,
    this.isOnline = false,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get isAdmin => role == 'admin';

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      role: data['role'] ?? 'member',
      projectIds: List<String>.from(data['projectIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: data['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'projectIds': projectIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'isOnline': isOnline,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? role,
    List<String>? projectIds,
    bool? isOnline,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      projectIds: projectIds ?? this.projectIds,
      createdAt: createdAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}