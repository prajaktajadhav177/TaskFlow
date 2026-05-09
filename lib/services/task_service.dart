import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';
import 'project_service.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ProjectService _projectService = ProjectService();

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required String projectId,
    required String projectName,
    required String creatorId,
    required String creatorName,
    String? assigneeId,
    String? assigneeName,
    String? assigneePhotoUrl,
    required String status,
    required String priority,
    List<String> tags = const [],
    DateTime? dueDate,
    int estimatedHours = 0,
    List<SubTask> subTasks = const [],
  }) async {
    final ref = _db.collection(AppConstants.tasksCollection).doc();

    final task = TaskModel(
      id: ref.id,
      title: title,
      description: description,
      projectId: projectId,
      projectName: projectName,
      creatorId: creatorId,
      creatorName: creatorName,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      assigneePhotoUrl: assigneePhotoUrl,
      status: status,
      priority: priority,
      tags: tags,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      comments: [],
      subTasks: subTasks,
      attachments: [],
      estimatedHours: estimatedHours,
    );

    await ref.set(task.toFirestore());
    await _projectService.updateTaskCounts(projectId);

    return task;
  }

  Future<void> updateTask(TaskModel task) async {
    await _db
        .collection(AppConstants.tasksCollection)
        .doc(task.id)
        .update(task.toFirestore());
    await _projectService.updateTaskCounts(task.projectId);
  }

  Future<void> updateTaskStatus(String taskId, String projectId, String status) async {
    final update = <String, dynamic>{'status': status};
    if (status == 'done') {
      update['completedAt'] = Timestamp.fromDate(DateTime.now());
    } else {
      update['completedAt'] = null;
    }
    await _db.collection(AppConstants.tasksCollection).doc(taskId).update(update);
    await _projectService.updateTaskCounts(projectId);
  }

  Future<void> deleteTask(String taskId, String projectId) async {
    await _db.collection(AppConstants.tasksCollection).doc(taskId).delete();
    await _projectService.updateTaskCounts(projectId);
  }

  Future<void> addComment({
    required String taskId,
    required TaskComment comment,
  }) async {
    await _db.collection(AppConstants.tasksCollection).doc(taskId).update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
    });
  }

  Future<void> updateSubTask({
    required String taskId,
    required String subTaskId,
    required bool isDone,
    required List<SubTask> allSubTasks,
  }) async {
    final updated = allSubTasks
        .map((s) => s.id == subTaskId ? s.copyWith(isDone: isDone) : s)
        .toList();
    await _db.collection(AppConstants.tasksCollection).doc(taskId).update({
      'subTasks': updated.map((s) => s.toMap()).toList(),
    });
  }

  // FIX: Removed orderBy — arrayContains + orderBy requires composite index.
  // Silently returns empty without the index. Sort in memory instead.
  Stream<List<TaskModel>> projectTasksStream(String projectId) {
    return _db
        .collection(AppConstants.tasksCollection)
        .where('projectId', isEqualTo: projectId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<TaskModel>> createdByUserTasksStream(String userId) {
  return _db
      .collection(AppConstants.tasksCollection)
      .where('creatorId', isEqualTo: userId)
      .snapshots()
      .map((snap) {
        final list = snap.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .toList();

        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return list;
      });
}

  Stream<List<TaskModel>> userTasksStream(String userId) {
    return _db
        .collection(AppConstants.tasksCollection)
        .where('assigneeId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<TaskModel>> overdueTasksStream(String userId) {
    return _db
        .collection(AppConstants.tasksCollection)
        .where('assigneeId', isEqualTo: userId)
        .where('dueDate', isLessThan: Timestamp.fromDate(DateTime.now()))
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => TaskModel.fromFirestore(doc))
            .where((t) => t.status != 'done')
            .toList());
  }

  // FIX: Removed orderBy — whereIn + orderBy also needs composite index
  Stream<List<TaskModel>> allUserProjectTasksStream(List<String> projectIds) {
    if (projectIds.isEmpty) return Stream.value([]);
    return _db
        .collection(AppConstants.tasksCollection)
        .where('projectId', whereIn: projectIds.take(10).toList())
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => TaskModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<TaskModel?> getTask(String taskId) async {
    final doc =
        await _db.collection(AppConstants.tasksCollection).doc(taskId).get();
    if (!doc.exists) return null;
    return TaskModel.fromFirestore(doc);
  }
}