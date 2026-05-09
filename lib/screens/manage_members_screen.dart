import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/string_extensions.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/project_service.dart';
import '../models/project_model.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class ManageMembersScreen extends StatefulWidget {
  final ProjectModel project;
  const ManageMembersScreen({super.key, required this.project});

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  final _searchCtrl = TextEditingController();
  final _authService = AuthService();
  final _projectService = ProjectService();

  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await _authService.searchUsers(query);
    if (mounted) {
      setState(() {
        _searchResults = results
            .where((u) => !widget.project.memberIds.contains(u.uid))
            .toList();
        _isSearching = false;
      });
    }
  }

  Future<void> _addMember(UserModel user) async {
    setState(() => _isLoading = true);
    await _projectService.addMember(projectId: widget.project.id, user: user);
    if (mounted) {
      setState(() {
        _searchResults.remove(user);
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${user.name} added to project'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context); // go back to refresh project
    }
  }

  Future<void> _removeMember(ProjectMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove Member',
            style: GoogleFonts.syne(color: AppTheme.textPrimary)),
        content: Text('Remove ${member.name} from this project?',
            style: GoogleFonts.spaceGrotesk(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove',
                style: GoogleFonts.spaceGrotesk(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final user = UserModel(
      uid: member.uid,
      name: member.name,
      email: member.email,
      role: member.role,
      projectIds: [],
      createdAt: DateTime.now(),
    );
    await _projectService.removeMember(
        projectId: widget.project.id, user: user);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${member.name} removed'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text('Manage Members',
            style: GoogleFonts.syne(fontWeight: FontWeight.w700)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Search bar
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'Search by email...',
              prefixIcon:
                  const Icon(Icons.search, color: AppTheme.textMuted, size: 20),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            color: AppTheme.primary, strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
          // Search results
          if (_searchResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Search Results',
                style: GoogleFonts.syne(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ..._searchResults.map((user) => _searchResultTile(user)),
          ],
          const SizedBox(height: 24),
          // Current members
          Text('Current Members (${widget.project.members.length})',
              style: GoogleFonts.syne(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...widget.project.members.map((m) => _memberTile(m)),
        ],
      ),
    );
  }

  Widget _searchResultTile(UserModel user) {
    final colors = [
      AppTheme.primary, AppTheme.secondary, AppTheme.success,
      AppTheme.warning, AppTheme.accent
    ];
    final color = colors[user.name.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color, color.withBlue(200)]),
              shape: BoxShape.circle),
          child: Center(
            child: Text(user.initials,
                style: GoogleFonts.syne(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.name,
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text(user.email,
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textMuted, fontSize: 12)),
          ]),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _addMember(user),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ]),
    );
  }

  Widget _memberTile(ProjectMember m) {
    final colors = [
      AppTheme.primary, AppTheme.secondary, AppTheme.success,
      AppTheme.warning, AppTheme.accent
    ];
    final color = colors[m.name.hashCode.abs() % colors.length];
    final isOwner = m.uid == widget.project.ownerId;

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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color, color.withBlue(200)]),
              shape: BoxShape.circle),
          child: Center(
            child: Text(m.initials,
                style: GoogleFonts.syne(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(m.name,
                  style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              if (isOwner) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('Owner',
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.warning, fontSize: 9)),
                ),
              ],
            ]),
            Text(m.email,
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textMuted, fontSize: 12)),
          ]),
        ),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          if (!isOwner) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _removeMember(m),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_remove_outlined,
                    color: AppTheme.error, size: 16),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}