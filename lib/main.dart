import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/animal_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/bottom_nav_bar.dart';
import 'pages/login_page.dart';
import 'pages/details_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error caught: ${details.exception}');
    // TODO: report to Crashlytics or your analytics service
  };

  // Catch any uncaught async errors
  await runZonedGuarded<Future<void>>(() async {
    // 1) Load environment variables
    try {
      await dotenv.load(fileName: '.env');
    } catch (e, st) {
      debugPrint('Error loading .env: $e\n$st');
    }

    // 2) Initialize Hive
    try {
      await Hive.initFlutter();
    } catch (e, st) {
      debugPrint('Error initializing Hive: $e\n$st');
    }

    // 3) Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
          authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '',
          projectId: dotenv.env['FIREBASE_PROJECT_ID'] ?? '',
          storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '',
          messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '',
          appId: dotenv.env['FIREBASE_APP_ID'] ?? '',
        ),
      );
    } catch (e, st) {
      debugPrint('Error initializing Firebase: $e\n$st');
    }

    // 4) Set up your providers
    final animalProvider = AnimalProvider();
    try {
      await animalProvider.initHive();
    } catch (e, st) {
      debugPrint('AnimalProvider.initHive error: $e\n$st');
    }

    final themeProvider = ThemeProvider();
    try {
      await themeProvider.init();
    } catch (e, st) {
      debugPrint('ThemeProvider.init error: $e\n$st');
    }

    // 5) Run the app
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: animalProvider),
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    // This will catch anything not handled above
    debugPrint('Uncaught error in zone: $error\n$stack');
    // Optionally: show a fatal error screen here
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use watch so that MyApp rebuilds when the theme changes
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Animal Market',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/details': (context) => const DetailsPage(),
      },
      // Dismiss keyboard on tap-away
      builder: (context, child) => GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: child,
      ),
    );
  }
}
