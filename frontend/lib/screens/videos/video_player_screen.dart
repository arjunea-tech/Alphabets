import 'package:flutter/material.dart';
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

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  double _progressValue = 0.35;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.repeat(reverse: true);
      } else {
        _animController.stop();
      }
    });
  }

  void _completeVideo() {
    widget.progressService.addStars(2);
    CelebrationDialog.show(
      context,
      title: 'காணொளி முடிந்தது!',
      message: 'காணொளியைப் பார்த்து மகிழ்ந்ததற்கு வாழ்த்துகள்!',
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
                    // Kid Video Player Canvas
                    Container(
                      width: double.infinity,
                      height: 230,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2B2D42), Color(0xFF1D1E2C)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: AppColors.primary, width: 2.5),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated playful stage background
                          AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isPlaying ? 1.0 + (_animController.value * 0.05) : 1.0,
                                child: child,
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.movie_creation_rounded, size: 48, color: Colors.white70),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    v.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isPlaying ? 'ஒளிபரப்பாகிறது...' : 'நிறுத்தப்பட்டுள்ளது',
                                  style: TextStyle(
                                    color: _isPlaying ? AppColors.sunnyYellow : Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                      // Center Big Play/Pause Button
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                            color: AppColors.starGold,
                            size: 54,
                          ),
                        ),
                      ),

                      // Bottom Player Controls Bar
                      Positioned(
                        bottom: 12,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Text(
                              _isPlaying ? '01:12' : '00:00',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  trackHeight: 4,
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: AppColors.starGold,
                                ),
                                child: Slider(
                                  value: _progressValue,
                                  onChanged: (val) {
                                    setState(() {
                                      _progressValue = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(v.duration, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Video Companion with Mascot (video.png)
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
                        customHeight: 95,
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
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (ApiConfig.resolveMediaUrl(v.videoUrl) != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'மூலம்: இணையதள காணொளி',
                                style: TextStyle(fontSize: 11, color: AppColors.secondary.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  v.description,
                  style: AppTextStyles.bodyText.copyWith(color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 22),

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
