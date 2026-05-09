import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/app_controller.dart';
import '../services/task_service.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../utils/app_theme.dart';

class CreateTaskScreen extends StatefulWidget {
  final ProjectModel project;
  const CreateTaskScreen({super.key, required this.project});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _subTaskCtrl = TextEditingController();
  final _taskService = TaskService();
  final _uuid = const Uuid();

  bool _isLoading = false;
  String _status = 'todo';
  String _priority = 'medium';
  ProjectMember? _assignee;
  DateTime? _dueDate;
  int _estimatedHours = 0;
  final List<String> _tags = [];
  final List<SubTask> _subTasks = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    _subTaskCtrl.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final controller = Get.find<AppController>();
      final user = controller.currentUser.value!;
      await _taskService.createTask(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        projectId: widget.project.id,
        projectName: widget.project.name,
        creatorId: user.uid,
        creatorName: user.name,
        assigneeId: _assignee?.uid,
        assigneeName: _assignee?.name,
        assigneePhotoUrl: _assignee?.photoUrl,
        status: _status,
        priority: _priority,
        tags: _tags,
        dueDate: _dueDate,
        estimatedHours: _estimatedHours,
        subTasks: _subTasks,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Task created!'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text('New Task', style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isLoading ? null : _createTask,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppTheme.primary, strokeWidth: 2))
                  : Text('Create',
                      style: GoogleFonts.syne(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                prefixIcon:
                    Icon(Icons.title, color: AppTheme.textMuted, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.notes_rounded,
                      color: AppTheme.textMuted, size: 20),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Status & Priority'),
            const SizedBox(height: 12),
            // Status selector
            _label('Status'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _statusChip('todo', 'To Do', AppTheme.statusTodo),
                _statusChip('in_progress', 'In Progress', AppTheme.statusInProgress),
                _statusChip('review', 'Review', AppTheme.statusReview),
                _statusChip('done', 'Done', AppTheme.statusDone),
              ],
            ),
            const SizedBox(height: 14),
            _label('Priority'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _priorityChip('low', 'Low', AppTheme.priorityLow),
                _priorityChip('medium', 'Medium', AppTheme.priorityMedium),
                _priorityChip('high', 'High', AppTheme.priorityHigh),
                _priorityChip('critical', 'Critical', AppTheme.priorityCritical),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle('Assignment'),
            const SizedBox(height: 12),
            // Assignee
            _label('Assign To'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _assigneeChip(null, 'Unassigned'),
                  ...widget.project.members.map(
                      (m) => _assigneeChip(m, m.name)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('Dates & Time'),
            const SizedBox(height: 12),
            // Due date
            GestureDetector(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: AppTheme.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'Set due date'
                          : DateFormat('MMM dd, yyyy').format(_dueDate!),
                      style: GoogleFonts.spaceGrotesk(
                          color: _dueDate == null
                              ? AppTheme.textMuted
                              : AppTheme.textPrimary,
                          fontSize: 14),
                    ),
                  ),
                  if (_dueDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _dueDate = null),
                      child: const Icon(Icons.close,
                          color: AppTheme.textMuted, size: 18),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            // Estimated hours
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Estimated Hours'),
                    const SizedBox(height: 8),
                    Row(children: [
                      IconButton(
                        onPressed: () {
                          if (_estimatedHours > 0) {
                            setState(() => _estimatedHours--);
                          }
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: const Icon(Icons.remove,
                              color: AppTheme.textPrimary, size: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Text('$_estimatedHours h',
                            style: GoogleFonts.syne(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _estimatedHours++),
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: const Icon(Icons.add,
                              color: AppTheme.textPrimary, size: 16),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),
            _sectionTitle('Tags'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _tagCtrl,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Add a tag...',
                    prefixIcon: Icon(Icons.tag,
                        color: AppTheme.textMuted, size: 18),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addTag,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14)),
                child: const Text('Add'),
              ),
            ]),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _tags
                    .map((t) => Chip(
                          label: Text(t,
                              style: GoogleFonts.spaceGrotesk(
                                  color: AppTheme.primary, fontSize: 12)),
                          backgroundColor: AppTheme.primary.withOpacity(0.15),
                          deleteIcon: const Icon(Icons.close,
                              size: 14, color: AppTheme.primary),
                          onDeleted: () =>
                              setState(() => _tags.remove(t)),
                          side: BorderSide(
                              color: AppTheme.primary.withOpacity(0.3)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            _sectionTitle('Sub-Tasks'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _subTaskCtrl,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Add a sub-task...',
                    prefixIcon: Icon(Icons.checklist_rounded,
                        color: AppTheme.textMuted, size: 18),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onSubmitted: (_) => _addSubTask(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addSubTask,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14)),
                child: const Text('Add'),
              ),
            ]),
            if (_subTasks.isNotEmpty) ...[
              const SizedBox(height: 10),
              ..._subTasks.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Row(children: [
                      const Icon(Icons.radio_button_unchecked,
                          color: AppTheme.textMuted, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(s.title,
                              style: GoogleFonts.spaceGrotesk(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13))),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _subTasks.remove(s)),
                        child: const Icon(Icons.close,
                            color: AppTheme.textMuted, size: 16),
                      ),
                    ]),
                  )),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTask,
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5)
                    : Text('Create Task',
                        style: GoogleFonts.syne(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  void _addSubTask() {
    final title = _subTaskCtrl.text.trim();
    if (title.isNotEmpty) {
      setState(() {
        _subTasks.add(SubTask(id: _uuid.v4(), title: title, isDone: false));
        _subTaskCtrl.clear();
      });
    }
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
          dialogBackgroundColor: AppTheme.bgCard,
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Widget _sectionTitle(String title) => Text(title,
      style: GoogleFonts.syne(
          color: AppTheme.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700));

  Widget _label(String text) => Text(text,
      style: GoogleFonts.spaceGrotesk(
          color: AppTheme.textSecondary, fontSize: 12));

  Widget _statusChip(String value, String label, Color color) {
    final isSelected = _status == value;
    return GestureDetector(
      onTap: () => setState(() => _status = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? color : AppTheme.divider,
              width: isSelected ? 2 : 1),
        ),
        child: Text(label,
            style: GoogleFonts.spaceGrotesk(
                color: isSelected ? color : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }

  Widget _priorityChip(String value, String label, Color color) {
    final isSelected = _priority == value;
    return GestureDetector(
      onTap: () => setState(() => _priority = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? color : AppTheme.divider,
              width: isSelected ? 2 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  color: isSelected ? color : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
        ]),
      ),
    );
  }

  Widget _assigneeChip(ProjectMember? member, String label) {
    final isSelected = member == null
        ? _assignee == null
        : _assignee?.uid == member.uid;
    return GestureDetector(
      onTap: () => setState(() => _assignee = member),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.primary.withOpacity(0.15) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.divider,
              width: isSelected ? 2 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (member != null) ...[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
              child: Center(
                  child: Text(member.initials,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 9))),
            ),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: GoogleFonts.spaceGrotesk(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
        ]),
      ),
    );
  }
}