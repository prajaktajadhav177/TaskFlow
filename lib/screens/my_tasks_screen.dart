import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_controller.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';
import 'task_detail_screen.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'date'; // date, priority, status
  final _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Tasks',
                            style: Theme.of(context).textTheme.displayMedium),
                        Obx(() => Text(
                              '${controller.myPendingTasks} pending',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )),
                      ],
                    ),
                  ),
                  // Sort button
                  PopupMenuButton<String>(
                    color: AppTheme.bgCard,
                    onSelected: (val) => setState(() => _sortBy = val),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(children: [
                        const Icon(Icons.sort_rounded,
                            color: AppTheme.textSecondary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                            _sortBy == 'date'
                                ? 'Date'
                                : _sortBy == 'priority'
                                    ? 'Priority'
                                    : 'Status',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.textSecondary, fontSize: 12)),
                      ]),
                    ),
                    itemBuilder: (_) => [
                      _popupItem('date', 'Sort by Date'),
                      _popupItem('priority', 'Sort by Priority'),
                      _popupItem('status', 'Sort by Status'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'To Do'),
                Tab(text: 'In Progress'),
                Tab(text: 'Done'),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Obx(() {
                final allTasks = controller.myTasks;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _taskList(context, _sortTasks(allTasks.toList())),
                    _taskList(context,
                        _sortTasks(allTasks.where((t) => t.status == 'todo').toList())),
                    _taskList(
                        context,
                        _sortTasks(allTasks
                            .where((t) =>
                                t.status == 'in_progress' ||
                                t.status == 'review')
                            .toList())),
                    _taskList(context,
                        _sortTasks(allTasks.where((t) => t.status == 'done').toList())),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  List<TaskModel> _sortTasks(List<TaskModel> tasks) {
    switch (_sortBy) {
      case 'priority':
        final order = ['critical', 'high', 'medium', 'low'];
        tasks.sort((a, b) =>
            order.indexOf(a.priority).compareTo(order.indexOf(b.priority)));
        break;
      case 'status':
        final order = ['todo', 'in_progress', 'review', 'done'];
        tasks.sort((a, b) =>
            order.indexOf(a.status).compareTo(order.indexOf(b.status)));
        break;
      default:
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return tasks;
  }

  Widget _taskList(BuildContext context, List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No tasks here!',
                style: GoogleFonts.syne(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            Text("You're all caught up",
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (_, i) {
        // Grouping by project
        final task = tasks[i];
        final showProjectHeader = i == 0 ||
            tasks[i - 1].projectName != task.projectName;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showProjectHeader)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 16, bottom: 8),
                child: Row(children: [
                  const Icon(Icons.folder_rounded,
                      color: AppTheme.textMuted, size: 14),
                  const SizedBox(width: 6),
                  Text(task.projectName,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            _taskCard(context, task),
          ],
        );
      },
    );
  }

  Widget _taskCard(BuildContext context, TaskModel task) {
    Color priorityColor;
    switch (task.priority) {
      case 'critical': priorityColor = AppTheme.priorityCritical; break;
      case 'high': priorityColor = AppTheme.priorityHigh; break;
      case 'medium': priorityColor = AppTheme.priorityMedium; break;
      default: priorityColor = AppTheme.priorityLow;
    }

    Color statusColor;
    String statusLabel;
    switch (task.status) {
      case 'in_progress':
        statusColor = AppTheme.statusInProgress;
        statusLabel = 'In Progress';
        break;
      case 'review':
        statusColor = AppTheme.statusReview;
        statusLabel = 'Review';
        break;
      case 'done':
        statusColor = AppTheme.statusDone;
        statusLabel = 'Done';
        break;
      default:
        statusColor = AppTheme.statusTodo;
        statusLabel = 'To Do';
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TaskDetailScreen(taskId: task.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: task.isOverdue
                  ? AppTheme.error.withOpacity(0.4)
                  : AppTheme.divider),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left priority bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(task.title,
                                style: GoogleFonts.spaceGrotesk(
                                    color: task.isDone
                                        ? AppTheme.textMuted
                                        : AppTheme.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: task.isDone
                                        ? TextDecoration.lineThrough
                                        : null),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(statusLabel,
                                style: GoogleFonts.spaceGrotesk(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        // Priority badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: priorityColor,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 4),
                            Text(task.priority.capitalizeFirst!,
                                style: GoogleFonts.spaceGrotesk(
                                    color: priorityColor, fontSize: 10)),
                          ]),
                        ),
                        const Spacer(),
                        if (task.subTasks.isNotEmpty) ...[
                          Icon(Icons.checklist_rounded,
                              color: AppTheme.textMuted, size: 13),
                          const SizedBox(width: 3),
                          Text(
                              '${task.completedSubTasks}/${task.subTasks.length}',
                              style: GoogleFonts.spaceGrotesk(
                                  color: AppTheme.textMuted, fontSize: 11)),
                          const SizedBox(width: 8),
                        ],
                        if (task.comments.isNotEmpty) ...[
                          Icon(Icons.chat_bubble_outline,
                              color: AppTheme.textMuted, size: 13),
                          const SizedBox(width: 3),
                          Text('${task.comments.length}',
                              style: GoogleFonts.spaceGrotesk(
                                  color: AppTheme.textMuted, fontSize: 11)),
                          const SizedBox(width: 8),
                        ],
                        if (task.dueDate != null) ...[
                          Icon(Icons.calendar_today_outlined,
                              color: task.isOverdue
                                  ? AppTheme.error
                                  : AppTheme.textMuted,
                              size: 12),
                          const SizedBox(width: 4),
                          Text(
                              DateFormat('MMM dd').format(task.dueDate!),
                              style: GoogleFonts.spaceGrotesk(
                                  color: task.isOverdue
                                      ? AppTheme.error
                                      : AppTheme.textMuted,
                                  fontSize: 11)),
                        ],
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Text(label,
          style: GoogleFonts.spaceGrotesk(color: AppTheme.textPrimary)),
    );
  }
}