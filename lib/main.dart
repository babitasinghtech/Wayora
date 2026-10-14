import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:login_learn_new_app/auth/login_screen.dart';
import 'package:login_learn_new_app/home/home_screen.dart';

import 'auth/auth_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Get.put(AuthController(), permanent: true);
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
      home: GetBuilder<AuthController>(
        builder: (c) {
          return c.isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
