import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'utils/app_theme.dart';
import 'services/app_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX: Only initialize if not already initialized (prevents duplicate-app crash on hot restart)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,

    );
  }

  // Register AppController globally
  if (!Get.isRegistered<AppController>()) {
    Get.put(AppController(), permanent: true);
  }

  runApp(const TaskFlowApp());
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/login',  page: () => const LoginScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/home',   page: () => const HomeScreen()),
      ],
    );
  }
}