import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_win/video_player_win.dart';
import '../../models/video_model.dart';
import '../../services/api_config.dart';
import '../../services/progress_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bouncy_button.dart';
import '../../widgets/celebration_dialog.dart';
import '../../widgets/kid_app_bar.dart';
import '../../widgets/kid_scaffold_background.dart';
import '../../widgets/mascot_widget.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoItem video;
  final ProgressService progressService;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.progressService,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasCompleted = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    if (_controller != null && _controller!.value.isPlaying) {
      _hideControlsTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted && _controller != null && _controller!.value.isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _onTapVideoCanvas() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _controller != null && _controller!.value.isPlaying) {
      _startHideTimer();
    } else if (!_showControls) {
      _hideControlsTimer?.cancel();
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
    });

    if (!kIsWeb && Platform.isWindows) {
      WindowsVideoPlayer.registerWith();
    }

    final rawUrl = widget.video.videoUrl;
    final resolvedUrl = ApiConfig.resolveMediaUrl(rawUrl);

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'காணொளி முகவரி கிடைக்கவில்லை (Video URL not found).';
      });
      return;
    }

    try {
      if (resolvedUrl.startsWith('http://') || resolvedUrl.startsWith('https://')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));
      } else {
        _controller = VideoPlayerController.asset(resolvedUrl);
      }

      await _controller!.initialize();
      _controller!.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _showControls = true;
        });
        _controller!.play();
        _startHideTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'காணொளியை இயக்க முடியவில்லை: $e';
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;

    // Check if video reached completion
    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (duration > Duration.zero && position >= duration && !_hasCompleted) {
      _hasCompleted = true;
      _completeVideo();
    }

    setState(() {});
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
        _hideControlsTimer?.cancel();
      } else {
        if (_controller!.value.position >= _controller!.value.duration) {
          _controller!.seekTo(Duration.zero);
        }
        _controller!.play();
        _showControls = true;
        _startHideTimer();
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  void _completeVideo() {
    widget.progressService.addStars(2);
    CelebrationDialog.show(
      context,
      title: 'காணொளி முடிந்தது! 🎉',
      message: 'காணொளியைப் பார்த்து மகிழ்ந்ததற்கு வாழ்த்துகள்! உங்களுக்கு 2 நட்சத்திரங்கள் கிடைத்துள்ளன!',
      starsEarned: 2,
      buttonText: 'தொடரலாம்',
      onContinue: () {
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.video;
    final isPlaying = _controller != null && _controller!.value.isPlaying;
    final shouldShowControls = _showControls || !isPlaying;

    return Scaffold(
      appBar: KidAppBar(
        title: v.title,
        starCount: widget.progressService.stars,
      ),
      body: KidScaffoldBackground(
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Player Canvas Container
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: AppColors.primary, width: 2.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio: (_isInitialized && _controller != null && _controller!.value.aspectRatio > 0)
                            ? _controller!.value.aspectRatio
                            : (16 / 9),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Actual Video Surface with Full Tap Detection
                            if (_isInitialized && _controller != null)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _onTapVideoCanvas,
                                  child: Center(
                                    child: AspectRatio(
                                      aspectRatio: _controller!.value.aspectRatio,
                                      child: VideoPlayer(_controller!),
                                    ),
                                  ),
                                ),
                              )
                            else if (_hasError)
                              // Error State
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error_outline_rounded, size: 36, color: Colors.amberAccent),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'காணொளியை ஏற்ற முடியவில்லை',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _errorMessage ?? 'இணைய இணைப்பை சரிபார்க்கவும்.',
                                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: _initializePlayer,
                                        icon: const Icon(Icons.refresh_rounded, size: 14),
                                        label: const Text('மீண்டும் முயற்சிக்கவும்', style: TextStyle(fontSize: 11)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              // Loading State
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(color: AppColors.starGold),
                                  const SizedBox(height: 10),
                                  Text(
                                    'காணொளி தயாராகிறது...',
                                    style: TextStyle(
                                      color: AppColors.sunnyYellow,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                            // 2. Center Play / Pause Overlay Button (only shown when controls active or paused)
                            if (_isInitialized && _controller != null)
                              AnimatedOpacity(
                                opacity: shouldShowControls ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 250),
                                child: IgnorePointer(
                                  ignoring: !shouldShowControls,
                                  child: GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: AppColors.starGold,
                                        size: 48,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // 3. Buffering Indicator
                            if (_isInitialized && _controller != null && _controller!.value.isBuffering)
                              const Positioned(
                                child: CircularProgressIndicator(color: AppColors.starGold),
                              ),

                            // 4. Bottom Controls Scrubber Bar (only shown when controls active or paused)
                            if (_isInitialized && _controller != null)
                              Positioned(
                                bottom: 8,
                                left: 10,
                                right: 10,
                                child: AnimatedOpacity(
                                  opacity: shouldShowControls ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 250),
                                  child: IgnorePointer(
                                    ignoring: !shouldShowControls,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _formatDuration(_controller!.value.position),
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                                trackHeight: 3.5,
                                                activeTrackColor: AppColors.primary,
                                                inactiveTrackColor: Colors.white24,
                                                thumbColor: AppColors.starGold,
                                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                              ),
                                              child: Slider(
                                                value: _controller!.value.duration.inMilliseconds > 0
                                                    ? (_controller!.value.position.inMilliseconds /
                                                            _controller!.value.duration.inMilliseconds)
                                                        .clamp(0.0, 1.0)
                                                    : 0.0,
                                                onChangeStart: (_) {
                                                  _hideControlsTimer?.cancel();
                                                },
                                                onChanged: (val) {
                                                  final seekMs = (_controller!.value.duration.inMilliseconds * val).toInt();
                                                  _controller!.seekTo(Duration(milliseconds: seekMs));
                                                },
                                                onChangeEnd: (_) {
                                                  if (_controller!.value.isPlaying) {
                                                    _startHideTimer();
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatDuration(_controller!.value.duration),
                                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Video Companion Card with Mascot
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const MascotWidget(
                            pose: MascotPose.video,
                            size: MascotSize.small,
                            customHeight: 88,
                            showGlow: true,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    v.category,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  v.title,
                                  style: AppTextStyles.cardTitle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (v.videoUrl.contains('cloudinary') || v.videoUrl.startsWith('http'))
                                      ? 'மூலம்: இணையதள காணொளி (Cloudinary)'
                                      : 'மூலம்: ஆப் காணொளி',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondary.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (v.description.isNotEmpty) ...[
                      Text(
                        v.description,
                        style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Complete Action Button
                    BouncyButton(
                      onPressed: _completeVideo,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.orangeGradient),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.white, size: 22),
                                const SizedBox(width: 8),
                                Text('பார்த்து முடித்தேன் (+2)', style: AppTextStyles.buttonText),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
