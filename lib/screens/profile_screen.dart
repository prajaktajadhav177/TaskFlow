import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_controller.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppController>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Obx(() {
          final user = controller.currentUser.value;
          if (user == null) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final colors = [
            AppTheme.primary, AppTheme.secondary, AppTheme.success,
            AppTheme.warning, AppTheme.accent
          ];
          final avatarColor = colors[user.name.hashCode.abs() % colors.length];

          return ListView(
            padding: const EdgeInsets.all(0),
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      avatarColor.withOpacity(0.25),
                      AppTheme.bgDark,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [avatarColor, avatarColor.withBlue(200)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: avatarColor.withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.initials,
                          style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(user.name,
                        style: GoogleFonts.syne(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(user.email,
                        style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textSecondary, fontSize: 14)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: user.isAdmin
                            ? AppTheme.primary.withOpacity(0.2)
                            : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: user.isAdmin
                              ? AppTheme.primary
                              : AppTheme.divider,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          user.isAdmin
                              ? Icons.admin_panel_settings_rounded
                              : Icons.person_rounded,
                          color: user.isAdmin
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.isAdmin ? 'Admin' : 'Member',
                          style: GoogleFonts.spaceGrotesk(
                            color: user.isAdmin
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),

              // Stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats grid
                    Row(children: [
                      _statCard(context, 'Projects',
                          controller.totalProjects.toString(),
                          Icons.folder_rounded, AppTheme.primary),
                      const SizedBox(width: 12),
                      _statCard(context, 'Tasks',
                          controller.myTasks.length.toString(),
                          Icons.task_alt_rounded, AppTheme.secondary),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _statCard(context, 'Completed',
                          controller.myTasks
                              .where((t) => t.status == 'done')
                              .length
                              .toString(),
                          Icons.check_circle_rounded, AppTheme.success),
                      const SizedBox(width: 12),
                      _statCard(context, 'Overdue',
                          controller.overdueTasks.toString(),
                          Icons.warning_amber_rounded, AppTheme.error),
                    ]),
                    const SizedBox(height: 28),

                    // Settings section
                    Text('Settings',
                        style: GoogleFonts.syne(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    _settingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Edit Profile',
                      subtitle: 'Update your name and info',
                      onTap: () => _showEditProfile(context, controller),
                    ),
                    _settingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage your alerts',
                      onTap: () {},
                    ),
                    _settingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Appearance',
                      subtitle: 'Dark mode enabled',
                      onTap: () {},
                    ),
                    _settingsTile(
                      icon: Icons.security_outlined,
                      title: 'Security',
                      subtitle: 'Password & access',
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),

                    Text('About',
                        style: GoogleFonts.syne(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    _settingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'App Version',
                      subtitle: '1.0.0',
                      onTap: () {},
                    ),
                    _settingsTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      subtitle: 'FAQ and contact',
                      onTap: () {},
                    ),
                    const SizedBox(height: 24),

                    // Sign out
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmSignOut(context, controller),
                        icon: const Icon(Icons.logout_rounded,
                            color: AppTheme.error, size: 18),
                        label: Text('Sign Out',
                            style: GoogleFonts.syne(
                                color: AppTheme.error,
                                fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: GoogleFonts.syne(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800)),
            Text(label,
                style: GoogleFonts.spaceGrotesk(
                    color: AppTheme.textMuted, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.bgCardLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.textSecondary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style: GoogleFonts.spaceGrotesk(
                          color: AppTheme.textMuted, fontSize: 12)),
                ]),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: AppTheme.textMuted, size: 14),
        ]),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AppController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sign Out',
            style: GoogleFonts.syne(color: AppTheme.textPrimary)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.spaceGrotesk(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await controller.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: Text('Sign Out',
                style: GoogleFonts.spaceGrotesk(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, AppController controller) {
    final nameCtrl = TextEditingController(
        text: controller.currentUser.value?.name ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Profile',
                style: GoogleFonts.syne(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline,
                    color: AppTheme.textMuted, size: 20),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Update logic would go here via Firestore
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Profile updated!'),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}