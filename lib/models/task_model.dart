import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String projectId;
  final String projectName;
  final String creatorId;
  final String creatorName;
  final String? assigneeId;
  final String? assigneeName;
  final String? assigneePhotoUrl;
  final String status; // todo, in_progress, review, done
  final String priority; // low, medium, high, critical
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final List<TaskComment> comments;
  final List<SubTask> subTasks;
  final List<String> attachments;
  final int estimatedHours;
  final int loggedHours;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.projectId,
    required this.projectName,
    required this.creatorId,
    required this.creatorName,
    this.assigneeId,
    this.assigneeName,
    this.assigneePhotoUrl,
    required this.status,
    required this.priority,
    required this.tags,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
    required this.comments,
    required this.subTasks,
    required this.attachments,
    this.estimatedHours = 0,
    this.loggedHours = 0,
  });

  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != 'done';

  bool get isDone => status == 'done';

  int get completedSubTasks => subTasks.where((s) => s.isDone).length;

  double get subTaskProgress =>
      subTasks.isEmpty ? 0.0 : completedSubTasks / subTasks.length;

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      projectId: data['projectId'] ?? '',
      projectName: data['projectName'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? '',
      assigneeId: data['assigneeId'],
      assigneeName: data['assigneeName'],
      assigneePhotoUrl: data['assigneePhotoUrl'],
      status: data['status'] ?? 'todo',
      priority: data['priority'] ?? 'medium',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((c) => TaskComment.fromMap(c as Map<String, dynamic>))
          .toList(),
      subTasks: (data['subTasks'] as List<dynamic>? ?? [])
          .map((s) => SubTask.fromMap(s as Map<String, dynamic>))
          .toList(),
      attachments: List<String>.from(data['attachments'] ?? []),
      estimatedHours: data['estimatedHours'] ?? 0,
      loggedHours: data['loggedHours'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'projectId': projectId,
      'projectName': projectName,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'assigneePhotoUrl': assigneePhotoUrl,
      'status': status,
      'priority': priority,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'comments': comments.map((c) => c.toMap()).toList(),
      'subTasks': subTasks.map((s) => s.toMap()).toList(),
      'attachments': attachments,
      'estimatedHours': estimatedHours,
      'loggedHours': loggedHours,
    };
  }

  TaskModel copyWith({
    String? title,
    String? description,
    String? assigneeId,
    String? assigneeName,
    String? assigneePhotoUrl,
    String? status,
    String? priority,
    List<String>? tags,
    DateTime? dueDate,
    DateTime? completedAt,
    List<TaskComment>? comments,
    List<SubTask>? subTasks,
    List<String>? attachments,
    int? estimatedHours,
    int? loggedHours,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectId: projectId,
      projectName: projectName,
      creatorId: creatorId,
      creatorName: creatorName,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      assigneePhotoUrl: assigneePhotoUrl ?? this.assigneePhotoUrl,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      comments: comments ?? this.comments,
      subTasks: subTasks ?? this.subTasks,
      attachments: attachments ?? this.attachments,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      loggedHours: loggedHours ?? this.loggedHours,
    );
  }
}

class TaskComment {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;

  String get initials {
    final parts = authorName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';
  }

  TaskComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  factory TaskComment.fromMap(Map<String, dynamic> map) {
    return TaskComment(
      id: map['id'] ?? '',
      authorId: map['authorId'] ?? '',
      authorName: map['authorName'] ?? '',
      authorPhotoUrl: map['authorPhotoUrl'],
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class SubTask {
  final String id;
  final String title;
  final bool isDone;

  SubTask({
    required this.id,
    required this.title,
    required this.isDone,
  });

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isDone: map['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
    };
  }

  SubTask copyWith({bool? isDone}) {
    return SubTask(id: id, title: title, isDone: isDone ?? this.isDone);
  }
}