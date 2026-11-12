import 'package:flutter/material.dart';
import '../services/api_config.dart';
import '../services/cloudinary_media.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum MascotSize { small, medium, large, hero }

enum MascotPose {
  welcome,
  learn,
  game,
  quiz,
  story,
  video,
  writing,
}

extension MascotPoseAsset on MascotPose {
  String get assetPath {
    switch (this) {
      case MascotPose.welcome:
        return 'assets/gifs/vanakam.gif';
      case MascotPose.learn:
        return 'assets/gifs/reading.gif';
      case MascotPose.game:
        return 'assets/gifs/games.gif';
      case MascotPose.quiz:
        return 'assets/gifs/question.gif';
      case MascotPose.story:
        return 'assets/gifs/reading.gif';
      case MascotPose.video:
        return 'assets/gifs/video.gif';
      case MascotPose.writing:
        return 'assets/gifs/writing.gif';
    }
  }

  String get fallbackPngAsset {
    switch (this) {
      case MascotPose.welcome:
        return 'assets/images/welcome.png';
      case MascotPose.learn:
        return 'assets/images/learn.png';
      case MascotPose.game:
        return 'assets/images/game.png';
      case MascotPose.quiz:
        return 'assets/images/quiz.png';
      case MascotPose.story:
        return 'assets/images/story.png';
      case MascotPose.video:
        return 'assets/images/video.png';
      case MascotPose.writing:
        return 'assets/images/writing.png';
    }
  }
}

class MascotWidget extends StatefulWidget {
  final MascotPose pose;
  final MascotSize size;
  final double? customHeight;
  final String? speechText;
  final VoidCallback? onTap;
  final bool showGlow;
  final bool animate;
  final String? customAssetOrUrl;

  const MascotWidget({
    super.key,
    this.pose = MascotPose.welcome,
    this.size = MascotSize.medium,
    this.customHeight,
    this.speechText,
    this.onTap,
    this.showGlow = false,
    this.animate = true,
    this.customAssetOrUrl,
  });

  @override
  State<MascotWidget> createState() => _MascotWidgetState();
}

class _MascotWidgetState extends State<MascotWidget> with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    if (widget.animate) {
      _idleController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_idleController.isAnimating) {
      _idleController.repeat(reverse: true);
    } else if (!widget.animate && _idleController.isAnimating) {
      _idleController.stop();
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  double get _computedHeight {
    if (widget.customHeight != null) return widget.customHeight!;
    switch (widget.size) {
      case MascotSize.small:
        return 85;
      case MascotSize.medium:
        return 150;
      case MascotSize.large:
        return 210;
      case MascotSize.hero:
        return 270;
    }
  }

  Widget _buildMascotImage(double height) {
    final custom = widget.customAssetOrUrl;
    if (custom != null && custom.isNotEmpty) {
      if (custom.startsWith('http://') || custom.startsWith('https://')) {
        return Image.network(
          custom,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              widget.pose.fallbackPngAsset,
              height: height,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => _buildFallbackIcon(height),
            );
          },
        );
      }
      final cUrl = CloudinaryMedia.getUrl(custom);
      if (cUrl != null && (cUrl.startsWith('http://') || cUrl.startsWith('https://'))) {
        return Image.network(
          cUrl,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              widget.pose.fallbackPngAsset,
              height: height,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => _buildFallbackIcon(height),
            );
          },
        );
      }
      return Image.asset(
        widget.pose.fallbackPngAsset,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (ctx, err, stack) => _buildFallbackIcon(height),
      );
    }

    final rawPath = widget.pose.assetPath;
    final cloudinaryUrl = CloudinaryMedia.getUrl(rawPath) ?? ApiConfig.resolveMediaUrl(rawPath);

    if (cloudinaryUrl != null && (cloudinaryUrl.startsWith('http://') || cloudinaryUrl.startsWith('https://'))) {
      return Image.network(
        cloudinaryUrl,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            widget.pose.fallbackPngAsset,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (ctx, err, stack) => _buildFallbackIcon(height),
          );
        },
      );
    }

    return Image.asset(
      widget.pose.fallbackPngAsset,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(height),
    );
  }

  Widget _buildFallbackIcon(double height) {
    return Container(
      height: height,
      width: height * 0.75,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.face_rounded, size: 40, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = _computedHeight;

    return GestureDetector(
      onTap: widget.onTap ??
          () {
            if (widget.animate) {
              _idleController.forward(from: 0.0);
            }
          },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.speechText != null) ...[
            _buildSpeechBubble(widget.speechText!),
            const SizedBox(height: 8),
          ],
          AnimatedBuilder(
            animation: _idleController,
            builder: (context, child) {
              final offset = widget.animate ? _bounceAnimation.value : 0.0;
              return Transform.translate(
                offset: Offset(0, offset),
                child: child,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.showGlow)
                  Container(
                    width: height * 0.9,
                    height: height * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFD166).withValues(alpha: 0.45),
                          const Color(0xFFFFD166).withValues(alpha: 0.0),
                        ],
                        radius: 0.7,
                      ),
                    ),
                  ),
                _buildMascotImage(height),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSpeechBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.starGold),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: widget.size == MascotSize.small ? 13 : 15,
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
