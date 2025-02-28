import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:soundmood/screens/auth_screen.dart';
import 'package:soundmood/screens/edit_profile_screen.dart';
import 'package:soundmood/screens/main_screen.dart';
import 'package:soundmood/screens/profile_screen.dart';
import 'package:soundmood/screens/search_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:soundmood/utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const SoundMoodApp(),
    ),
  );
}

class SoundMoodApp extends StatelessWidget {
  const SoundMoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'soundmood',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primary,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/main': (context) => const MainScreen(),
        '/search': (context) => const SearchScreen(),
        '/profile': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            return const AuthScreen();
          }
          return UserProfileScreen(userId: user.uid, isCurrentUser: true);
        },
        '/login': (context) => const AuthScreen(),
        '/editprofile': (context) => const EditProfileScreen(),
      },
    );
  }
}
