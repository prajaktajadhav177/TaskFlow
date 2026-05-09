import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../services/app_controller.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';
import 'task_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Obx(() {
          final user = controller.currentUser.value;
          if (user == null) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 130,
                floating: true,
                snap: true,
                backgroundColor: AppTheme.bgDark,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _greeting(),
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                user.name,
                                style: GoogleFonts.syne(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Avatar
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.secondary],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              user.initials,
                              style: GoogleFonts.syne(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Row
                      Row(
                        children: [
                          _statCard(
                            context,
                            label: 'Projects',
                            value: controller.totalProjects.toString(),
                            icon: Icons.folder_rounded,
                            color: AppTheme.primary,
                            flex: 1,
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            context,
                            label: 'Total Tasks',
                            value: controller.totalTasks.toString(),
                            icon: Icons.task_alt_rounded,
                            color: AppTheme.secondary,
                            flex: 1,
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            context,
                            label: 'Overdue',
                            value: controller.overdueTasks.toString(),
                            icon: Icons.warning_amber_rounded,
                            color: AppTheme.error,
                            flex: 1,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Overall progress card
                      _overallProgressCard(context, controller),
                      const SizedBox(height: 20),
                      // Status chart
                      _statusDonutChart(context, controller),
                      const SizedBox(height: 20),
                      // Recent / overdue tasks
                      _sectionHeader(context, 'My Pending Tasks'),
                      const SizedBox(height: 12),
                      _pendingTasksList(context, controller),
                      const SizedBox(height: 20),
                      // Overdue section
                      if (controller.overdueTasks > 0) ...[
                        _sectionHeader(context, '⚠️ Overdue Tasks', color: AppTheme.error),
                        const SizedBox(height: 12),
                        _overdueTasksList(context, controller),
                        const SizedBox(height: 20),
                      ],
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  Widget _statCard(BuildContext context,
      {required String label,
      required String value,
      required IconData icon,
      required Color color,
      required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.syne(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overallProgressCard(BuildContext context, AppController controller) {
    final progress = controller.overallProgress;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.3),
            AppTheme.secondary.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Progress',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toInt()}% Complete',
                  style: GoogleFonts.syne(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${controller.completedTasks} of ${controller.totalTasks} tasks done',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          CircularPercentIndicator(
            radius: 42,
            lineWidth: 8,
            percent: progress.clamp(0.0, 1.0),
            center: Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.syne(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            progressColor: AppTheme.success,
            backgroundColor: AppTheme.divider,
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ],
      ),
    );
  }

  Widget _statusDonutChart(BuildContext context, AppController controller) {
    final stats = controller.tasksByStatus;
    final total = stats.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sections = [
      PieChartSectionData(
        value: stats['todo']!.toDouble(),
        color: AppTheme.statusTodo,
        title: '',
        radius: 30,
      ),
      PieChartSectionData(
        value: stats['in_progress']!.toDouble(),
        color: AppTheme.statusInProgress,
        title: '',
        radius: 30,
      ),
      PieChartSectionData(
        value: stats['review']!.toDouble(),
        color: AppTheme.statusReview,
        title: '',
        radius: 30,
      ),
      PieChartSectionData(
        value: stats['done']!.toDouble(),
        color: AppTheme.statusDone,
        title: '',
        radius: 30,
      ),
    ].where((s) => s.value > 0).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task Overview',
              style: GoogleFonts.syne(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 3,
                    centerSpaceRadius: 28,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _legendRow('To Do', stats['todo']!, AppTheme.statusTodo),
                    const SizedBox(height: 8),
                    _legendRow('In Progress', stats['in_progress']!, AppTheme.statusInProgress),
                    const SizedBox(height: 8),
                    _legendRow('In Review', stats['review']!, AppTheme.statusReview),
                    const SizedBox(height: 8),
                    _legendRow('Done', stats['done']!, AppTheme.statusDone),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textSecondary, fontSize: 12)),
        ),
        Text(
          count.toString(),
          style: GoogleFonts.syne(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title, {Color? color}) {
    return Text(
      title,
      style: GoogleFonts.syne(
        color: color ?? AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _pendingTasksList(BuildContext context, AppController controller) {
    final tasks = controller.myTasks
        .where((t) => t.status != 'done')
        .take(5)
        .toList();

    if (tasks.isEmpty) {
      return _emptyState('No pending tasks 🎉', 'All caught up!');
    }

    return Column(
      children: tasks.map((task) => _taskCard(context, task)).toList(),
    );
  }

  Widget _overdueTasksList(BuildContext context, AppController controller) {
    final uid = controller.currentUser.value?.uid ?? '';
    final tasks = controller.allTasks
        .where((t) => t.isOverdue && t.assigneeId == uid)
        .take(3)
        .toList();

    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      children: tasks.map((task) => _taskCard(context, task, isOverdue: true)).toList(),
    );
  }

  Widget _taskCard(BuildContext context, TaskModel task, {bool isOverdue = false}) {
    Color priorityColor;
    switch (task.priority) {
      case 'critical':
        priorityColor = AppTheme.priorityCritical;
        break;
      case 'high':
        priorityColor = AppTheme.priorityHigh;
        break;
      case 'medium':
        priorityColor = AppTheme.priorityMedium;
        break;
      default:
        priorityColor = AppTheme.priorityLow;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOverdue ? AppTheme.error.withOpacity(0.4) : AppTheme.divider,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 44,
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
                  Text(
                    task.title,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.folder_outlined, color: AppTheme.textMuted, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        task.projectName,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 10),
                        Icon(
                          Icons.calendar_today_outlined,
                          color: isOverdue ? AppTheme.error : AppTheme.textMuted,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd').format(task.dueDate!),
                          style: GoogleFonts.spaceGrotesk(
                            color: isOverdue ? AppTheme.error : AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            _statusBadge(task.status),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'in_progress':
        color = AppTheme.statusInProgress;
        label = 'In Progress';
        break;
      case 'review':
        color = AppTheme.statusReview;
        label = 'Review';
        break;
      case 'done':
        color = AppTheme.statusDone;
        label = 'Done';
        break;
      default:
        color = AppTheme.statusTodo;
        label = 'To Do';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text('✅', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.syne(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}