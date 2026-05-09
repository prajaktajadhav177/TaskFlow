import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class ProjectService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<ProjectModel> createProject({
    required String name,
    required String description,
    required UserModel owner,
    required String color,
    required String icon,
    DateTime? deadline,
  }) async {
    final ref = _db.collection(AppConstants.projectsCollection).doc();

    final member = ProjectMember(
      uid: owner.uid,
      name: owner.name,
      email: owner.email,
      role: 'admin',
      photoUrl: owner.photoUrl,
    );

    final project = ProjectModel(
      id: ref.id,
      name: name,
      description: description,
      ownerId: owner.uid,
      ownerName: owner.name,
      memberIds: [owner.uid],
      members: [member],
      color: color,
      icon: icon,
      createdAt: DateTime.now(),
      deadline: deadline,
    );

    await ref.set(project.toFirestore());

    await _db.collection(AppConstants.usersCollection).doc(owner.uid).update({
      'projectIds': FieldValue.arrayUnion([ref.id]),
    });

    return project;
  }

  Future<void> updateProject(ProjectModel project) async {
    await _db
        .collection(AppConstants.projectsCollection)
        .doc(project.id)
        .update(project.toFirestore());
  }

  Future<void> deleteProject(String projectId) async {
    final tasks = await _db
        .collection(AppConstants.tasksCollection)
        .where('projectId', isEqualTo: projectId)
        .get();

    final batch = _db.batch();
    for (final task in tasks.docs) {
      batch.delete(task.reference);
    }
    batch.delete(
        _db.collection(AppConstants.projectsCollection).doc(projectId));
    await batch.commit();
  }

  Future<void> addMember({
    required String projectId,
    required UserModel user,
    String role = 'member',
  }) async {
    final member = ProjectMember(
      uid: user.uid,
      name: user.name,
      email: user.email,
      role: role,
      photoUrl: user.photoUrl,
    );

    await _db.collection(AppConstants.projectsCollection).doc(projectId).update({
      'memberIds': FieldValue.arrayUnion([user.uid]),
      'members': FieldValue.arrayUnion([member.toMap()]),
    });

    await _db.collection(AppConstants.usersCollection).doc(user.uid).update({
      'projectIds': FieldValue.arrayUnion([projectId]),
    });
  }

  Future<void> removeMember({
    required String projectId,
    required UserModel user,
  }) async {
    final doc = await _db
        .collection(AppConstants.projectsCollection)
        .doc(projectId)
        .get();
    final project = ProjectModel.fromFirestore(doc);

    final updatedMembers =
        project.members.where((m) => m.uid != user.uid).toList();
    final updatedMemberIds =
        project.memberIds.where((id) => id != user.uid).toList();

    await _db.collection(AppConstants.projectsCollection).doc(projectId).update({
      'memberIds': updatedMemberIds,
      'members': updatedMembers.map((m) => m.toMap()).toList(),
    });

    await _db.collection(AppConstants.usersCollection).doc(user.uid).update({
      'projectIds': FieldValue.arrayRemove([projectId]),
    });
  }

  // FIX: Removed .orderBy('createdAt', descending: true)
  // arrayContains + orderBy requires a Firestore composite index.
  // Without it, Firestore silently returns empty results.
  // Sorting in memory instead — no index needed.
  Stream<List<ProjectModel>> userProjectsStream(String userId) {
    return _db
        .collection(AppConstants.projectsCollection)
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ProjectModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<ProjectModel?> projectStream(String projectId) {
    return _db
        .collection(AppConstants.projectsCollection)
        .doc(projectId)
        .snapshots()
        .map((doc) => doc.exists ? ProjectModel.fromFirestore(doc) : null);
  }

  Future<ProjectModel?> getProject(String projectId) async {
    final doc = await _db
        .collection(AppConstants.projectsCollection)
        .doc(projectId)
        .get();
    if (!doc.exists) return null;
    return ProjectModel.fromFirestore(doc);
  }

  Future<void> updateTaskCounts(String projectId) async {
    final tasks = await _db
        .collection(AppConstants.tasksCollection)
        .where('projectId', isEqualTo: projectId)
        .get();

    final total = tasks.docs.length;
    final completed =
        tasks.docs.where((d) => d.data()['status'] == 'done').length;

    await _db.collection(AppConstants.projectsCollection).doc(projectId).update({
      'totalTasks': total,
      'completedTasks': completed,
    });
  }
}