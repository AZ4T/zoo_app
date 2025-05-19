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
  // 1. Make sure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load your .env file
  await dotenv.load(fileName: '.env');

  // 3. Initialize Hive for local storage
  await Hive.initFlutter();

  // 4. Initialize Firebase using values from .env
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey:               dotenv.env['FIREBASE_API_KEY']!,
      authDomain:           dotenv.env['FIREBASE_AUTH_DOMAIN']!,
      projectId:            dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket:        dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      messagingSenderId:    dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      appId:                dotenv.env['FIREBASE_APP_ID']!,
    ),
  );

  // 5. Prepare your providers
  final animalProvider = AnimalProvider();
  await animalProvider.initHive();

  final themeProvider = ThemeProvider();
  await themeProvider.init();

  // 6. Launch the app with MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AnimalProvider>.value(value: animalProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
      ],
      child: const MyApp(),
    ),
  );
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
