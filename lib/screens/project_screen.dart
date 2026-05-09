import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_controller.dart';
import '../models/project_model.dart';
import '../utils/app_theme.dart';
import 'project_detail_screen.dart';
import 'create_project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _filter = 'all'; // all, active, completed

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
                        Text('Projects',
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium),
                        Obx(() => Text(
                              '${controller.totalProjects} total',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )),
                      ],
                    ),
                  ),
                  Obx(() {
                    if (!controller.isAdmin) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateProjectScreen()),
                      ),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, AppTheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 24),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _filterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _filterChip('active', 'Active'),
                  const SizedBox(width: 8),
                  _filterChip('completed', 'Completed'),
                  const SizedBox(width: 8),
                  _filterChip('archived', 'Archived'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Project list
            Expanded(
              child: Obx(() {
                final projects = controller.projects.where((p) {
                  if (_filter == 'all') return true;
                  return p.status == _filter;
                }).toList();

                if (projects.isEmpty) {
                  return _emptyState(context, controller.isAdmin);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: projects.length,
                  itemBuilder: (_, i) => _projectCard(context, projects[i]),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _projectCard(BuildContext context, ProjectModel project) {
    final color = _hexToColor(project.color);
    final progress = project.progress;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProjectDetailScreen(projectId: project.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Center(
                    child: Text(project.icon,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: GoogleFonts.syne(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        project.ownerName,
                        style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(project.status, project.isOverdue),
              ],
            ),
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                project.description,
                style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.syne(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                // Member avatars
                _memberAvatars(project.members),
                const Spacer(),
                // Task count
                Icon(Icons.task_alt_outlined, color: AppTheme.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${project.completedTasks}/${project.totalTasks}',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (project.deadline != null) ...[
                  const SizedBox(width: 14),
                  Icon(
                    Icons.calendar_today_outlined,
                    color: project.isOverdue ? AppTheme.error : AppTheme.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd').format(project.deadline!),
                    style: GoogleFonts.spaceGrotesk(
                      color: project.isOverdue ? AppTheme.error : AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberAvatars(List<ProjectMember> members) {
    final show = members.take(4).toList();
    return SizedBox(
      height: 26,
      width: show.length * 20.0 + 6,
      child: Stack(
        children: List.generate(show.length, (i) {
          final m = show[i];
          return Positioned(
            left: i * 18.0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _avatarColor(m.name),
                    _avatarColor(m.name).withBlue(200),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.bgCard, width: 2),
              ),
              child: Center(
                child: Text(
                  m.initials,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Color _avatarColor(String name) {
    final colors = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.accent,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Widget _statusBadge(String status, bool isOverdue) {
    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Overdue',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.w600)),
      );
    }
    Color color;
    String label;
    switch (status) {
      case 'completed':
        color = AppTheme.success;
        label = 'Completed';
        break;
      case 'archived':
        color = AppTheme.textMuted;
        label = 'Archived';
        break;
      default:
        color = AppTheme.primary;
        label = 'Active';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: GoogleFonts.spaceGrotesk(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  Widget _emptyState(BuildContext context, bool isAdmin) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📁', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No projects yet',
              style: GoogleFonts.syne(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'Tap + to create your first project'
                : 'You haven\'t been added to any project yet',
            style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textMuted, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (isAdmin) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateProjectScreen()),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Project'),
            ),
          ],
        ],
      ),
    );
  }
}