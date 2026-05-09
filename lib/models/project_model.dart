import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerName;
  final List<String> memberIds;
  final List<ProjectMember> members;
  final String color; // hex color
  final String icon;
  final DateTime createdAt;
  final DateTime? deadline;
  final int totalTasks;
  final int completedTasks;
  final String status; // active, completed, archived

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.memberIds,
    required this.members,
    required this.color,
    required this.icon,
    required this.createdAt,
    this.deadline,
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.status = 'active',
  });

  double get progress =>
      totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  bool get isOverdue =>
      deadline != null && deadline!.isBefore(DateTime.now()) && status != 'completed';

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      members: (data['members'] as List<dynamic>? ?? [])
          .map((m) => ProjectMember.fromMap(m as Map<String, dynamic>))
          .toList(),
      color: data['color'] ?? '#6C63FF',
      icon: data['icon'] ?? '📁',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      totalTasks: data['totalTasks'] ?? 0,
      completedTasks: data['completedTasks'] ?? 0,
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'memberIds': memberIds,
      'members': members.map((m) => m.toMap()).toList(),
      'color': color,
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'status': status,
    };
  }

  ProjectModel copyWith({
    String? name,
    String? description,
    List<String>? memberIds,
    List<ProjectMember>? members,
    String? color,
    String? icon,
    DateTime? deadline,
    int? totalTasks,
    int? completedTasks,
    String? status,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId,
      ownerName: ownerName,
      memberIds: memberIds ?? this.memberIds,
      members: members ?? this.members,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt,
      deadline: deadline ?? this.deadline,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      status: status ?? this.status,
    );
  }
}

class ProjectMember {
  final String uid;
  final String name;
  final String email;
  final String role; // admin or member
  final String? photoUrl;

  ProjectMember({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
  });

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory ProjectMember.fromMap(Map<String, dynamic> map) {
    return ProjectMember(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'member',
      photoUrl: map['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
    };
  }
}