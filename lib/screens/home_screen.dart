import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/app_controller.dart';
import '../utils/app_theme.dart';
import 'dashboard_screen.dart';
import 'project_screen.dart';
import 'my_tasks_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // NEVER call Get.put here — AppController is already registered
    // permanently in main.dart via initialBinding
    final controller = Get.find<AppController>();

    return Obx(() {
      final index = controller.selectedTab.value;

      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: IndexedStack(
          index: index,
          children: const [
            DashboardScreen(),
            ProjectsScreen(),
            MyTasksScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            border: const Border(
                top: BorderSide(color: AppTheme.divider, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _navItem(controller, 0, Icons.dashboard_rounded,
                      Icons.dashboard_outlined, 'Dashboard'),
                  _navItem(controller, 1, Icons.folder_rounded,
                      Icons.folder_outlined, 'Projects'),
                  _navItem(controller, 2, Icons.task_alt_rounded,
                      Icons.task_alt_outlined, 'My Tasks'),
                  _navItem(controller, 3, Icons.person_rounded,
                      Icons.person_outlined, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _navItem(AppController controller, int index, IconData activeIcon,
      IconData inactiveIcon, String label) {
    final isActive = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectedTab.value = index,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.primary.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive ? AppTheme.primary : AppTheme.textMuted,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}