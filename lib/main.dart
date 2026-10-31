import 'package:firebase_core/firebase_core.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/views/auth/login_screen.dart';
import 'package:login_learn_new_app/views/auth/set_name_screen.dart';
import 'package:login_learn_new_app/views/home/home_screen.dart';
import 'package:login_learn_new_app/controllers/auth_controller.dart';
import 'package:login_learn_new_app/controllers/call_controller.dart';
import 'package:login_learn_new_app/controllers/notification_controller.dart';
import 'package:login_learn_new_app/services/session_service.dart';
import 'package:login_learn_new_app/views/splash/splash_screen.dart';
import 'package:login_learn_new_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SessionService.init(); // saved login (SharedPreferences)

  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Get.put(AuthController(), permanent: true);
    Get.put(CallController(), permanent: true); // listens for incoming calls
    Get.put(NotificationController(), permanent: true); // inbox + settings
  } catch (e) {
    firebaseError = e.toString();
  }

  runApp(MyApp(firebaseError: firebaseError));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.firebaseError});
  final String? firebaseError;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login New App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF12A594),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F8F8),
      ),
      home: const _Root(),
    );
  }
}

/// Splash first (min. 2 s), then Home (saved login) or Login (new user /
/// after logout).
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  static const _minSplash = Duration(milliseconds: 2000);
  bool _splashDone = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_minSplash, () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (c) {
        // keep the splash until the minimum time is over AND, when a saved
        // login exists, until Firebase has restored it
        final restoring = !c.authReady && SessionService.wasLoggedIn;
        if (!_splashDone || restoring) return const SplashScreen();

        if (!c.isLoggedIn) return const LoginScreen(); // new user / after logout
        if (c.needsName) return const SetNameScreen();
        return const HomeScreen();
      },
    );
  }
}
