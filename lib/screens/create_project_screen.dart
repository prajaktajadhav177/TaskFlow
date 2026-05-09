import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_controller.dart';
import '../services/project_service.dart';
import '../utils/app_theme.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _projectService = ProjectService();

  bool _isLoading = false;
  String _selectedColor = '#6C63FF';
  String _selectedIcon = '📁';
  DateTime? _deadline;

  final List<String> _colors = [
    '#6C63FF', '#00D2FF', '#FF6B6B', '#06D6A0',
    '#FFD166', '#EF476F', '#118AB2', '#073B4C',
    '#F72585', '#7209B7', '#3A0CA3', '#4CC9F0',
  ];

  final List<String> _icons = [
    '📁', '🚀', '💡', '🎯', '🛠️', '📱', '🌐', '🎨',
    '📊', '🔬', '🏆', '💼', '⚡', '🔥', '💎', '🌟',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final controller = Get.find<AppController>();
      final user = controller.currentUser.value!;
      await _projectService.createProject(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        owner: user,
        color: _selectedColor,
        icon: _selectedIcon,
        deadline: _deadline,
      );
      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Project created successfully!');
      }
    } catch (e) {
      if (mounted) _showError('Failed to create project. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: const Text('New Project'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isLoading ? null : _createProject,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview card
              _previewCard(),
              const SizedBox(height: 28),
              _sectionTitle('Project Details'),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  prefixIcon:
                      Icon(Icons.title_rounded, color: AppTheme.textMuted, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Project name is required';
                  if (v.length < 2) return 'Name too short';
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_rounded,
                        color: AppTheme.textMuted, size: 20),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              // Deadline picker
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _deadline == null
                              ? 'Set deadline (optional)'
                              : DateFormat('MMM dd, yyyy').format(_deadline!),
                          style: GoogleFonts.spaceGrotesk(
                            color: _deadline == null
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_deadline != null)
                        GestureDetector(
                          onTap: () => setState(() => _deadline = null),
                          child: const Icon(Icons.close,
                              color: AppTheme.textMuted, size: 18),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _sectionTitle('Project Icon'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _icons.map((icon) {
                  final isSelected = _selectedIcon == icon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _hexToColor(_selectedColor).withOpacity(0.2)
                            : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: isSelected
                              ? _hexToColor(_selectedColor)
                              : AppTheme.divider,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                          child: Text(icon,
                              style: const TextStyle(fontSize: 22))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              _sectionTitle('Project Color'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((hex) {
                  final color = _hexToColor(hex);
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createProject,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text('Create Project',
                          style: GoogleFonts.syne(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewCard() {
    final color = _hexToColor(_selectedColor);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.25), color.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
                child: Text(_selectedIcon,
                    style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nameController.text.isEmpty
                      ? 'Project Name'
                      : _nameController.text,
                  style: GoogleFonts.syne(
                    color: _nameController.text.isEmpty
                        ? AppTheme.textMuted
                        : AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _deadline != null
                      ? 'Due ${DateFormat('MMM dd, yyyy').format(_deadline!)}'
                      : 'No deadline set',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.syne(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700));
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
          dialogBackgroundColor: AppTheme.bgCard,
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _deadline = date);
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppTheme.primary;
    }
  }
}