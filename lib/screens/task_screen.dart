import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_manager/utils/app_theme.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import 'task_detail_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TaskService _taskService = TaskService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('My Tasks',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle:
                        const TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search,
                        color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.bgDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                tabs: const [
                  Tab(text: 'Assigned to Me'),
                  Tab(text: 'Created by Me'),
                  Tab(text: 'Overdue'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskStream(_taskService.userTasksStream(_uid)),
          _buildTaskStream(_taskService.createdByUserTasksStream(_uid),),
          _buildTaskStream(_taskService.overdueTasksStream(_uid)),
        ],
      ),
    );
  }

 Widget _buildTaskStream(Stream<List<TaskModel>> stream) {
  return StreamBuilder<List<TaskModel>>(
    stream: stream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
          ),
        );
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return _buildEmpty();
      }

      var tasks = snapshot.data!;

      if (_search.isNotEmpty) {
        tasks = tasks.where((t) =>
            t.title.toLowerCase().contains(_search) ||
            t.description.toLowerCase().contains(_search)
        ).toList();
      }

      if (tasks.isEmpty) {
        return _buildEmpty(message: 'No results found');
      }

      final grouped = <String, List<TaskModel>>{};

      for (final task in tasks) {
        grouped.putIfAbsent(task.status, () => []).add(task);
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _statusHeader(entry.key, entry.value.length),
              ...entry.value.map((task) => _buildTaskCard(task)),
              const SizedBox(height: 8),
            ],
          );
        }).toList(),
      );
    },
  );
}

  Widget _statusHeader(String status, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(status,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textPrimary)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(status))),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final priorityColor = _getPriorityColor(task.priority);
    final isOverdue = task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        task.status != 'Done';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isOverdue
                  ? AppTheme.error.withOpacity(0.3)
                  : AppTheme.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            decoration: task.status == 'Done'
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      if (isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('OVERDUE',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.error,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(task.description,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip(task.priority, priorityColor),
                      const SizedBox(width: 6),
                      if (task.assigneeName != null)
                        _chip(task.assigneeName!, AppTheme.primary),
                      const Spacer(),
                      if (task.dueDate != null)
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                size: 12,
                                color: isOverdue
                                    ? AppTheme.error
                                    : AppTheme.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              '${task.dueDate!.day}/${task.dueDate!.month}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isOverdue
                                      ? AppTheme.error
                                      : AppTheme.textSecondary),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildEmpty({String message = 'No tasks here'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 64, color: AppTheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('You\'re all caught up! 🎉',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Color _getStatusColor(String s) {
    switch (s.toLowerCase()) {
      case 'done': return AppTheme.success;
      case 'in progress': return AppTheme.primary;
      case 'review': return AppTheme.warning;
      default: return AppTheme.textSecondary;
    }
  }

  Color _getPriorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': return AppTheme.error;
      case 'medium': return AppTheme.warning;
      default: return AppTheme.success;
    }
  }
}