# Firebase setup (one time)

1. Firebase Console -> create project -> Build -> Authentication -> Get started
   -> Sign-in method -> enable **Email/Password**.
2. In the project folder run:
       flutter pub get
       dart pub global activate flutterfire_cli
       flutterfire configure
   (choose your project + Android/iOS). This generates the real
   `lib/firebase_options.dart` and adds the google-services plugin to Gradle.
3. `flutter run`
