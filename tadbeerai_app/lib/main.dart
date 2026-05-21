import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tadbeerai/firebase_options.dart';
import 'package:tadbeerai/features/splash/splash_screen.dart';
import 'package:tadbeerai/core/providers/theme_provider.dart';
import 'package:tadbeerai/core/providers/language_provider.dart';
import 'package:tadbeerai/core/providers/notification_provider.dart';
import 'package:tadbeerai/shared/theme/app_theme.dart';
import 'package:tadbeerai/core/services/auth_service.dart';
import 'package:tadbeerai/core/services/alert_store.dart';
import 'package:tadbeerai/core/services/notification_service.dart';
import 'package:tadbeerai/core/services/hive_service.dart';
import 'package:tadbeerai/features/auth/auth_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await HiveService.initHive();

  // Load initial settings synchronously from Hive box
  final initialTheme = await HiveService.getThemeMode();
  final initialLanguage = await HiveService.getLanguage();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AuthService.instance.initialize();
    await AlertStore.instance.initialize();
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
    await AuthService.instance.initialize();
    await AlertStore.instance.initialize();
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ThemeProvider(initialTheme: initialTheme)),
        ChangeNotifierProvider(
            create: (_) => LanguageProvider(initialLanguage: initialLanguage)),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const TadbeerApp(),
    ),
  );
}

class TadbeerApp extends StatelessWidget {
  const TadbeerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Tadbeer AI',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildDarkAppTheme(),
          themeMode: themeProvider.themeMode,
          routes: {
            '/': (ctx) => const SplashScreen(),
            '/auth': (ctx) => const AuthScreen(),
          },
        );
      },
    );
  }
}
