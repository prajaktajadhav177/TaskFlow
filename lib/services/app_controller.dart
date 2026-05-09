import 'dart:async';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../services/auth_service.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';

class AppController extends GetxController {
  final AuthService _authService = AuthService();
  final ProjectService _projectService = ProjectService();
  final TaskService _taskService = TaskService();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxList<ProjectModel> projects = <ProjectModel>[].obs;
  final RxList<TaskModel> myTasks = <TaskModel>[].obs;
  final RxList<TaskModel> allTasks = <TaskModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedProjectId = ''.obs;
  final RxInt selectedTab = 0.obs;

  // Track subscriptions so we can cancel & restart cleanly
  StreamSubscription? _userSub;
  StreamSubscription? _projectsSub;
  StreamSubscription? _myTasksSub;
  StreamSubscription? _allTasksSub;

  @override
  void onInit() {
    super.onInit();
    // React to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _startListening(user.uid);
      } else {
        _cancelAllSubscriptions();
        currentUser.value = null;
        projects.clear();
        myTasks.clear();
        allTasks.clear();
      }
    });
  }

  @override
  void onClose() {
    _cancelAllSubscriptions();
    super.onClose();
  }

  void _cancelAllSubscriptions() {
    _userSub?.cancel();
    _projectsSub?.cancel();
    _myTasksSub?.cancel();
    _allTasksSub?.cancel();
    _userSub = null;
    _projectsSub = null;
    _myTasksSub = null;
    _allTasksSub = null;
  }

  /// Uses a real-time Firestore stream for the user document.
  /// This means any change to role/name/etc. in Firestore is
  /// reflected immediately in the app — no re-login needed.
  void _startListening(String uid) {
    isLoading.value = true;

    // Cancel old subs first (handles re-login edge cases)
    _cancelAllSubscriptions();

    // 1. Real-time user document stream — fixes the role bug
    _userSub = _authService.userStream(uid).listen((user) {
      currentUser.value = user;
      isLoading.value = false;
    });

    // 2. Projects stream
    _projectsSub = _projectService.userProjectsStream(uid).listen((list) {
      projects.value = list;
      // Restart allTasks stream whenever project list changes
      _allTasksSub?.cancel();
      final ids = list.map((p) => p.id).toList();
      if (ids.isNotEmpty) {
        _allTasksSub =
            _taskService.allUserProjectTasksStream(ids).listen((tasks) {
          allTasks.value = tasks;
        });
      } else {
        allTasks.clear();
      }
    });

    // 3. My assigned tasks stream
    _myTasksSub = _taskService.userTasksStream(uid).listen((list) {
      myTasks.value = list;
    });
  }

  /// Call this after signup so the controller picks up the new user doc
  /// without waiting for the next authStateChange event.
  void refreshUser(String uid) {
    _startListening(uid);
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  int get totalProjects => projects.length;
  int get totalTasks => allTasks.length;
  int get completedTasks => allTasks.where((t) => t.status == 'done').length;
  int get overdueTasks => allTasks
      .where((t) => t.isOverdue && t.assigneeId == currentUser.value?.uid)
      .length;
  int get myPendingTasks => myTasks.where((t) => t.status != 'done').length;

  double get overallProgress =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

  Map<String, int> get tasksByStatus => {
        'todo': allTasks.where((t) => t.status == 'todo').length,
        'in_progress': allTasks.where((t) => t.status == 'in_progress').length,
        'review': allTasks.where((t) => t.status == 'review').length,
        'done': allTasks.where((t) => t.status == 'done').length,
      };

  Future<void> signOut() async {
    await _authService.signOut();
    Get.offAllNamed('/login');
  }

  bool get isAdmin => currentUser.value?.isAdmin ?? false;
}