import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player_win/video_player_win.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/progress_service.dart';
import 'services/tamil_tts_service.dart';
import 'theme/app_theme.dart';

import 'screens/language/language_selection_screen.dart';
import 'services/language_service.dart';

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

  // Initialize Language Service
  await LanguageService.instance.init();

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

class AgaramApp extends StatefulWidget {
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
  State<AgaramApp> createState() => _AgaramAppState();
}

class _AgaramAppState extends State<AgaramApp> {
  bool _warmedUp = false;

  /// Bundled images that appear right after opening Home / Games.
  /// Decoding them once in the background removes the stutter on first open.
  static const List<String> _warmImages = [
    'assets/images/learn.png',
    'assets/images/game.png',
    'assets/images/writing.png',
    'assets/images/video.png',
    'assets/images/quiz.png',
    'assets/images/welcome.png',
    'assets/images/games/candy_match_cover.png',
    'assets/images/games/runner_cover.png',
    'assets/images/games/balloon_pop_cover.png',
    'assets/images/games/flappy_word_cover.png',
    'assets/images/games/word_ninja_cover.png',
    'assets/images/games/car_racing_cover.png',
    'assets/images/games/fishing_cover.png',
    'assets/images/games/basket_vowels_cover.png',
    'assets/images/games/basket_consonants_cover.png',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmedUp) return;
    _warmedUp = true;
    // After the first frame is on screen, quietly load data and decode images.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(DataService.instance.prefetchAll());
      for (final path in _warmImages) {
        precacheImage(AssetImage(path), context, onError: (_, _) {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = widget.authService ?? AuthService();

    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final lang = LanguageService.instance;

        Widget homeWidget;
        if (widget.initialScreen != null) {
          homeWidget = widget.initialScreen!;
        } else if (!lang.hasSelectedLanguage) {
          homeWidget = LanguageSelectionScreen(
            isInitialSetup: true,
            onLanguageSelected: () {
              setState(() {});
            },
          );
        } else if (auth.isAuthenticated) {
          homeWidget = MainNavigationScreen(progressService: widget.progressService);
        } else {
          homeWidget = LoginScreen(
            authService: auth,
            progressService: widget.progressService,
          );
        }

        return MaterialApp(
          title: 'ALPHABETS - Learn 26 Letters',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          home: homeWidget,
        );
      },
    );
  }
}
