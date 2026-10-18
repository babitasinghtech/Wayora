import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/views/auth/login_screen.dart';
import 'package:login_learn_new_app/views/auth/set_name_screen.dart';
import 'package:login_learn_new_app/views/home/home_screen.dart';
import 'package:login_learn_new_app/controllers/auth_controller.dart';
import 'package:login_learn_new_app/controllers/call_controller.dart';
import 'package:login_learn_new_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? firebaseError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Get.put(AuthController(), permanent: true);
    Get.put(CallController(), permanent: true); // listens for incoming calls
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
          if (!c.isLoggedIn) return const LoginScreen();
          if (c.needsName) return const SetNameScreen();
          return const HomeScreen();
        },
      ),
    );
  }
}
