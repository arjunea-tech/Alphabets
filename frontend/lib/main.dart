import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player_win/video_player_win.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';
import 'services/progress_service.dart';
import 'services/tamil_tts_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && Platform.isWindows) {
    WindowsVideoPlayer.registerWith();
  }

  // Set kid-friendly cheerful status bar overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Tamil TTS service at startup for zero-latency pronunciation
  unawaited(TamilTtsService.instance.init());

  final authService = AuthService();
  final progressService = ProgressService();

  // Check saved session
  await authService.loadSession();

  // Sync profile name with progress service if logged in
  if (authService.isAuthenticated && authService.currentUser != null) {
    if (authService.currentUser!.name.isNotEmpty) {
      progressService.updateProfile(
        name: authService.currentUser!.name,
        avatarIndex: progressService.avatarIndex,
      );
    }
  }

  runApp(AgaramApp(
    authService: authService,
    progressService: progressService,
  ));
}

class AgaramApp extends StatelessWidget {
  final AuthService? authService;
  final ProgressService progressService;
  final Widget? initialScreen;

  const AgaramApp({
    super.key,
    this.authService,
    required this.progressService,
    this.initialScreen,
  });

  @override
  Widget build(BuildContext context) {
    final auth = authService ?? AuthService();

    return MaterialApp(
      title: 'எழுத்துக்கள்',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: initialScreen ??
          (auth.isAuthenticated
              ? MainNavigationScreen(progressService: progressService)
              : LoginScreen(
                  authService: auth,
                  progressService: progressService,
                )),
    );
  }
}
