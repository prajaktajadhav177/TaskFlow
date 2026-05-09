import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/app_controller.dart';
import '../services/task_service.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _taskService = TaskService();
  final _commentCtrl = TextEditingController();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();
    return StreamBuilder<TaskModel?>(
      stream: Stream.fromFuture(_taskService.getTask(widget.taskId)).asyncExpand(
        (_) => Stream.periodic(const Duration(seconds: 2))
            .asyncMap((_) => _taskService.getTask(widget.taskId)),
      ),
      builder: (_, snapshot) {
        // Fallback: use a FutureBuilder for initial load
        return FutureBuilder<TaskModel?>(
          future: _taskService.getTask(widget.taskId),
          builder: (context, snap) {
            final task = snap.data;
            if (task == null) {
              return const Scaffold(
                backgroundColor: AppTheme.bgDark,
                body:
                    Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              );
            }
            return _buildScreen(context, task, controller);
          },
        );
      },
    );
  }

  Widget _buildScreen(
      BuildContext context, TaskModel task, AppController controller) {
    final user = controller.currentUser.value!;
    final canEdit = task.creatorId == user.uid ||
        task.assigneeId == user.uid ||
        controller.isAdmin;

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
        statusLabel = 'In Review';
        break;
      case 'done':
        statusColor = AppTheme.statusDone;
        statusLabel = 'Done';
        break;
      default:
        statusColor = AppTheme.statusTodo;
        statusLabel = 'To Do';
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(task.projectName,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 14, color: AppTheme.textSecondary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (canEdit)
            PopupMenuButton<String>(
              color: AppTheme.bgCard,
              onSelected: (val) => _handleMenu(context, val, task, controller),
              itemBuilder: (_) => [
                _menuItem('status', Icons.swap_horiz_rounded, 'Change Status'),
                _menuItem('priority', Icons.flag_rounded, 'Change Priority'),
                if (task.creatorId == user.uid || controller.isAdmin)
                  _menuItem('delete', Icons.delete_rounded, 'Delete Task',
                      isDestructive: true),
              ],
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Icon(Icons.more_horiz, size: 20),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Title & Status row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 52,
                decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title,
                        style: GoogleFonts.syne(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.3)),
                    const SizedBox(height: 4),
                    Text('in ${task.projectName}',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status & Priority badges
          Row(children: [
            _badge(statusLabel, statusColor),
            const SizedBox(width: 8),
            _badge(task.priority.capitalizeFirst!, priorityColor),
            if (task.isOverdue) ...[
              const SizedBox(width: 8),
              _badge('Overdue', AppTheme.error),
            ],
          ]),
          const SizedBox(height: 20),

          // Meta info
          _infoCard(task),
          const SizedBox(height: 20),

          // Description
          if (task.description.isNotEmpty) ...[
            _sectionTitle('Description'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Text(task.description,
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],

          // Sub-tasks
          if (task.subTasks.isNotEmpty) ...[
            Row(children: [
              _sectionTitle('Sub-Tasks'),
              const Spacer(),
              Text(
                  '${task.completedSubTasks}/${task.subTasks.length}',
                  style: GoogleFonts.syne(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 8),
            // Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: task.subTaskProgress,
                backgroundColor: AppTheme.divider,
                valueColor: const AlwaysStoppedAnimation(AppTheme.success),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 12),
            ...task.subTasks.map((s) => _subTaskTile(context, task, s, canEdit)),
            const SizedBox(height: 20),
          ],

          // Tags
          if (task.tags.isNotEmpty) ...[
            _sectionTitle('Tags'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: task.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.primary.withOpacity(0.3)),
                        ),
                        child: Text('#$t',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppTheme.primary, fontSize: 12)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Quick status update
          if (canEdit) ...[
            _sectionTitle('Update Status'),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _quickStatus(context, task, 'todo', 'To Do', AppTheme.statusTodo),
                _quickStatus(context, task, 'in_progress', 'In Progress',
                    AppTheme.statusInProgress),
                _quickStatus(context, task, 'review', 'Review',
                    AppTheme.statusReview),
                _quickStatus(context, task, 'done', 'Done', AppTheme.statusDone),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Comments
          _sectionTitle('Comments (${task.comments.length})'),
          const SizedBox(height: 12),
          ...task.comments.map((c) => _commentTile(c)),
          const SizedBox(height: 8),
          // Add comment
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
              child: Center(
                child: Text(user.initials,
                    style: GoogleFonts.syne(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppTheme.primary),
                  ),
                  filled: true,
                  fillColor: AppTheme.bgCard,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: AppTheme.primary, size: 20),
                    onPressed: () => _submitComment(task, user),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoCard(TaskModel task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _infoRow(Icons.person_outline, 'Assignee',
              task.assigneeName ?? 'Unassigned'),
          const Divider(color: AppTheme.divider, height: 20),
          _infoRow(Icons.person_rounded, 'Created by', task.creatorName),
          const Divider(color: AppTheme.divider, height: 20),
          _infoRow(Icons.calendar_today_outlined, 'Created',
              DateFormat('MMM dd, yyyy').format(task.createdAt)),
          if (task.dueDate != null) ...[
            const Divider(color: AppTheme.divider, height: 20),
            _infoRow(
              Icons.schedule_rounded,
              'Due Date',
              DateFormat('MMM dd, yyyy').format(task.dueDate!),
              valueColor: task.isOverdue ? AppTheme.error : null,
            ),
          ],
          if (task.estimatedHours > 0) ...[
            const Divider(color: AppTheme.divider, height: 20),
            _infoRow(Icons.timer_outlined, 'Estimated',
                '${task.estimatedHours}h'),
          ],
          if (task.completedAt != null) ...[
            const Divider(color: AppTheme.divider, height: 20),
            _infoRow(Icons.check_circle_outline, 'Completed',
                DateFormat('MMM dd, yyyy').format(task.completedAt!),
                valueColor: AppTheme.success),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(children: [
      Icon(icon, color: AppTheme.textMuted, size: 16),
      const SizedBox(width: 10),
      Text(label,
          style: GoogleFonts.spaceGrotesk(
              color: AppTheme.textMuted, fontSize: 13)),
      const Spacer(),
      Text(value,
          style: GoogleFonts.spaceGrotesk(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _subTaskTile(
      BuildContext context, TaskModel task, SubTask sub, bool canEdit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: canEdit
              ? () async {
                  await _taskService.updateSubTask(
                    taskId: task.id,
                    subTaskId: sub.id,
                    isDone: !sub.isDone,
                    allSubTasks: task.subTasks,
                  );
                  setState(() {});
                }
              : null,
          child: Icon(
            sub.isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: sub.isDone ? AppTheme.success : AppTheme.textMuted,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(sub.title,
              style: GoogleFonts.spaceGrotesk(
                  color: sub.isDone
                      ? AppTheme.textMuted
                      : AppTheme.textPrimary,
                  fontSize: 13,
                  decoration:
                      sub.isDone ? TextDecoration.lineThrough : null)),
        ),
      ]),
    );
  }

  Widget _commentTile(TaskComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.7),
                  shape: BoxShape.circle),
              child: Center(
                  child: Text(comment.initials,
                      style: GoogleFonts.syne(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment.authorName,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text(
                      DateFormat('MMM dd, hh:mm a')
                          .format(comment.createdAt),
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(comment.text,
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _quickStatus(BuildContext context, TaskModel task, String status,
      String label, Color color) {
    final isActive = task.status == status;
    return GestureDetector(
      onTap: isActive
          ? null
          : () async {
              await _taskService.updateTaskStatus(
                  task.id, task.projectId, status);
              if (context.mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Status updated to $label'),
                  backgroundColor: color,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.2) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isActive ? color : AppTheme.divider,
              width: isActive ? 2 : 1),
        ),
        child: Text(label,
            style: GoogleFonts.spaceGrotesk(
                color: isActive ? color : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.spaceGrotesk(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: GoogleFonts.syne(
          color: AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700));

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon,
            color:
                isDestructive ? AppTheme.error : AppTheme.textSecondary,
            size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                color: isDestructive ? AppTheme.error : AppTheme.textPrimary,
                fontSize: 14)),
      ]),
    );
  }

  void _handleMenu(BuildContext context, String val, TaskModel task,
      AppController controller) {
    if (val == 'status') {
      _showStatusSheet(context, task);
    } else if (val == 'priority') {
      _showPrioritySheet(context, task);
    } else if (val == 'delete') {
      _confirmDelete(context, task);
    }
  }

  void _showStatusSheet(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change Status',
                style: GoogleFonts.syne(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...['todo', 'in_progress', 'review', 'done'].map((s) {
              final labels = {
                'todo': 'To Do',
                'in_progress': 'In Progress',
                'review': 'In Review',
                'done': 'Done'
              };
              final colors = {
                'todo': AppTheme.statusTodo,
                'in_progress': AppTheme.statusInProgress,
                'review': AppTheme.statusReview,
                'done': AppTheme.statusDone
              };
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: colors[s], shape: BoxShape.circle),
                ),
                title: Text(labels[s]!,
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary)),
                trailing: task.status == s
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  await _taskService.updateTaskStatus(
                      task.id, task.projectId, s);
                  setState(() {});
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showPrioritySheet(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change Priority',
                style: GoogleFonts.syne(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...['low', 'medium', 'high', 'critical'].map((p) {
              final colors = {
                'low': AppTheme.priorityLow,
                'medium': AppTheme.priorityMedium,
                'high': AppTheme.priorityHigh,
                'critical': AppTheme.priorityCritical
              };
              return ListTile(
                leading: Icon(Icons.flag_rounded, color: colors[p]),
                title: Text(p.capitalizeFirst!,
                    style: GoogleFonts.spaceGrotesk(
                        color: AppTheme.textPrimary)),
                trailing: task.priority == p
                    ? const Icon(Icons.check, color: AppTheme.primary)
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  await _taskService.updateTask(task.copyWith(priority: p));
                  setState(() {});
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Task',
            style: GoogleFonts.syne(color: AppTheme.textPrimary)),
        content: Text('Delete "${task.title}"? This cannot be undone.',
            style: GoogleFonts.spaceGrotesk(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _taskService.deleteTask(task.id, task.projectId);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Delete',
                style: GoogleFonts.spaceGrotesk(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitComment(TaskModel task, dynamic user) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final comment = TaskComment(
      id: _uuid.v4(),
      authorId: user.uid,
      authorName: user.name,
      authorPhotoUrl: user.photoUrl,
      text: text,
      createdAt: DateTime.now(),
    );
    _commentCtrl.clear();
    await _taskService.addComment(taskId: task.id, comment: comment);
    setState(() {});
  }
}