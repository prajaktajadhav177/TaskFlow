import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_controller.dart';
import '../services/project_service.dart';
import '../services/task_service.dart';
import '../services/auth_service.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';
import 'create_task_screen.dart';
import 'task_detail_screen.dart';
import 'manage_members_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _projectService = ProjectService();
  final _taskService = TaskService();
  String _statusFilter = 'all';

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
    final controller = Get.find<AppController>();
    return StreamBuilder<ProjectModel?>(
      stream: _projectService.projectStream(widget.projectId),
      builder: (context, snapshot) {
        final project = snapshot.data;
        if (project == null) {
          return const Scaffold(
            backgroundColor: AppTheme.bgDark,
            body: Center(
                child: CircularProgressIndicator(color: AppTheme.primary)),
          );
        }
        final color = _hexToColor(project.color);
        final isAdmin = project.ownerId == controller.currentUser.value?.uid ||
            project.members.any((m) =>
                m.uid == controller.currentUser.value?.uid &&
                m.role == 'admin');

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppTheme.bgDark,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (isAdmin)
                    PopupMenuButton<String>(
                      color: AppTheme.bgCard,
                      onSelected: (val) => _handleMenu(context, val, project),
                      itemBuilder: (_) => [
                        _menuItem('members', Icons.group_rounded, 'Manage Members'),
                        _menuItem('archive', Icons.archive_rounded, 'Archive'),
                        _menuItem('delete', Icons.delete_rounded, 'Delete Project',
                            isDestructive: true),
                      ],
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.more_horiz,
                            color: Colors.white, size: 20),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.4),
                          AppTheme.bgDark,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 100, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                      color: color.withOpacity(0.4), width: 2),
                                ),
                                child: Center(
                                    child: Text(project.icon,
                                        style: const TextStyle(fontSize: 26))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(project.name,
                                        style: GoogleFonts.syne(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700)),
                                    Row(children: [
                                      Icon(Icons.person_outline,
                                          color: Colors.white60, size: 13),
                                      const SizedBox(width: 4),
                                      Text(project.ownerName,
                                          style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white60,
                                              fontSize: 12)),
                                      const SizedBox(width: 10),
                                      Icon(Icons.group_outlined,
                                          color: Colors.white60, size: 13),
                                      const SizedBox(width: 4),
                                      
                                      Text(
                                          '${project.members.length} members',
                                          style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white60,
                                              fontSize: 12)),
                                    ]),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Progress
                          Row(children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: project.progress,
                                  backgroundColor: Colors.white24,
                                  valueColor: AlwaysStoppedAnimation(color),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('${(project.progress * 100).toInt()}%',
                                style: GoogleFonts.syne(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ]),
                            const SizedBox(height: 20),

                        ],
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: color,
                    labelColor: color,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Tasks'),
                      Tab(text: 'Members'),
                      Tab(text: 'Overview'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _TasksTab(
                  project: project,
                  taskService: _taskService,
                  isAdmin: isAdmin,
                  color: color,
                ),
                _MembersTab(project: project, isAdmin: isAdmin),
                _OverviewTab(project: project, color: color),
              ],
            ),
          ),
          floatingActionButton: isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CreateTaskScreen(project: project)),
                  ),
                  backgroundColor: color,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text('Add Task',
                      style: GoogleFonts.syne(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                )
              : null,
        );
      },
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon,
            color: isDestructive ? AppTheme.error : AppTheme.textSecondary,
            size: 18),
        const SizedBox(width: 10),
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                color: isDestructive ? AppTheme.error : AppTheme.textPrimary,
                fontSize: 14)),
      ]),
    );
  }

  void _handleMenu(BuildContext context, String val, ProjectModel project) async {
    if (val == 'members') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ManageMembersScreen(project: project)));
    } else if (val == 'archive') {
      await _projectService.updateProject(project.copyWith(status: 'archived'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Project archived'), backgroundColor: AppTheme.warning));
      }
    } else if (val == 'delete') {
      _confirmDelete(context, project);
    }
  }

  void _confirmDelete(BuildContext context, ProjectModel project) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Project',
            style: GoogleFonts.syne(color: AppTheme.textPrimary)),
        content: Text(
            'Are you sure? This will delete all tasks in "${project.name}".',
            style: GoogleFonts.spaceGrotesk(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _projectService.deleteProject(project.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Delete',
                style: GoogleFonts.spaceGrotesk(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }
}

// ─── Tasks Tab ───────────────────────────────────────────────────────────────
class _TasksTab extends StatefulWidget {
  final ProjectModel project;
  final TaskService taskService;
  final bool isAdmin;
  final Color color;

  const _TasksTab(
      {required this.project,
      required this.taskService,
      required this.isAdmin,
      required this.color});

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            _chip('all', 'All'),
            _chip('todo', 'To Do'),
            _chip('in_progress', 'In Progress'),
            _chip('review', 'Review'),
            _chip('done', 'Done'),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<TaskModel>>(
            stream:
                widget.taskService.projectTasksStream(widget.project.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary));
              }
              final all = snapshot.data!;
              final tasks = _filter == 'all'
                  ? all
                  : all.where((t) => t.status == _filter).toList();

              if (tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('No tasks',
                          style: GoogleFonts.syne(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      Text('Add tasks to get started',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.textMuted, fontSize: 13)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tasks.length,
                itemBuilder: (_, i) => _taskTile(context, tasks[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(String value, String label) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? widget.color : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? widget.color : AppTheme.divider),
        ),
        child: Text(label,
            style: GoogleFonts.spaceGrotesk(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }

  Widget _taskTile(BuildContext context, TaskModel task) {
    Color priorityColor;
    switch (task.priority) {
      case 'critical': priorityColor = AppTheme.priorityCritical; break;
      case 'high': priorityColor = AppTheme.priorityHigh; break;
      case 'medium': priorityColor = AppTheme.priorityMedium; break;
      default: priorityColor = AppTheme.priorityLow;
    }

    Color statusColor;
    switch (task.status) {
      case 'in_progress': statusColor = AppTheme.statusInProgress; break;
      case 'review': statusColor = AppTheme.statusReview; break;
      case 'done': statusColor = AppTheme.statusDone; break;
      default: statusColor = AppTheme.statusTodo;
    }

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: task.isOverdue
                  ? AppTheme.error.withOpacity(0.4)
                  : AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    if (task.assigneeName != null) ...[
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(task.assigneeName![0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9)),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(task.assigneeName!,
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.textMuted, fontSize: 11)),
                      const SizedBox(width: 8),
                    ],
                    if (task.dueDate != null) ...[
                      Icon(Icons.access_time,
                          color: task.isOverdue
                              ? AppTheme.error
                              : AppTheme.textMuted,
                          size: 12),
                      const SizedBox(width: 3),
                      Text(DateFormat('MMM dd').format(task.dueDate!),
                          style: GoogleFonts.spaceGrotesk(
                              color: task.isOverdue
                                  ? AppTheme.error
                                  : AppTheme.textMuted,
                              fontSize: 11)),
                    ],
                    if (task.subTasks.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.checklist, color: AppTheme.textMuted, size: 12),
                      const SizedBox(width: 3),
                      Text(
                          '${task.completedSubTasks}/${task.subTasks.length}',
                          style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.textMuted, fontSize: 11)),
                    ],
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_statusLabel(task.status),
                  style: GoogleFonts.spaceGrotesk(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress': return 'In Progress';
      case 'review': return 'Review';
      case 'done': return 'Done';
      default: return 'To Do';
    }
  }
}

// ─── Members Tab ─────────────────────────────────────────────────────────────
class _MembersTab extends StatelessWidget {
  final ProjectModel project;
  final bool isAdmin;

  const _MembersTab({required this.project, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ManageMembersScreen(project: project)),
              ),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Manage Members'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ...project.members.map((m) => _memberTile(m)),
      ],
    );
  }

  Widget _memberTile(ProjectMember m) {
    final colors = [AppTheme.primary, AppTheme.secondary, AppTheme.success,
        AppTheme.warning, AppTheme.accent];
    final color = colors[m.name.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [color, color.withBlue(200)]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(m.initials,
                style: GoogleFonts.syne(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.name,
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(m.email,
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: m.role == 'admin'
                ? AppTheme.primary.withOpacity(0.15)
                : AppTheme.bgCardLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(m.role.capitalizeFirst!,
              style: GoogleFonts.spaceGrotesk(
                  color: m.role == 'admin'
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final ProjectModel project;
  final Color color;

  const _OverviewTab({required this.project, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (project.description.isNotEmpty) ...[
          _label('Description'),
          const SizedBox(height: 8),
          Text(project.description,
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textSecondary, fontSize: 14, height: 1.6)),
          const SizedBox(height: 20),
        ],
        Row(children: [
          Expanded(
              child: _infoCard('Total Tasks', project.totalTasks.toString(),
                  Icons.task_rounded, color)),
          const SizedBox(width: 12),
          Expanded(
              child: _infoCard('Completed',
                  project.completedTasks.toString(), Icons.check_circle_rounded,
                  AppTheme.success)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: _infoCard(
                  'Members',
                  project.members.length.toString(),
                  Icons.group_rounded,
                  AppTheme.secondary)),
          const SizedBox(width: 12),
          Expanded(
              child: _infoCard(
                  'Progress',
                  '${(project.progress * 100).toInt()}%',
                  Icons.donut_large_rounded,
                  AppTheme.warning)),
        ]),
        const SizedBox(height: 20),
        _label('Timeline'),
        const SizedBox(height: 10),
        _timelineRow('Created', DateFormat('MMM dd, yyyy').format(project.createdAt)),
        if (project.deadline != null)
          _timelineRow(
              'Deadline',
              DateFormat('MMM dd, yyyy').format(project.deadline!),
              isAlert: project.isOverdue),
        _timelineRow('Status', project.status.capitalizeFirst!),
      ],
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.syne(
          color: AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700));

  Widget _infoCard(String label, String value, IconData icon, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c, size: 22),
        const SizedBox(height: 8),
        Text(value,
            style: GoogleFonts.syne(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textMuted, fontSize: 11)),
      ]),
    );
  }

  Widget _timelineRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textMuted, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.spaceGrotesk(
                color: isAlert ? AppTheme.error : AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}