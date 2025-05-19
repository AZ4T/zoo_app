import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/animal_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'pages/login_page.dart';
import 'pages/details_page.dart';
import 'widgets/bottom_nav_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: '.env');

  // Hive
  await Hive.initFlutter();

  // EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
    ),
  );

  // Providers — only init once each
  final animalProvider = AnimalProvider()..initHive();
  final themeProvider = ThemeProvider()..init();
  final localeProvider = LocaleProvider()..init();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
        Locale('kk'),
      ],
      path: 'translations', 
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: animalProvider),
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: localeProvider),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().themeData;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      title: tr('app.title'), // your key in JSON
      theme: theme,
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginPage(),
        '/details': (_) => const DetailsPage(),
      },
      builder: (ctx, child) => GestureDetector(
        onTap: () => FocusScope.of(ctx).unfocus(),
        child: child,
      ),
    );
  }
}

