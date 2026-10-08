import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';

class AudioButton extends StatefulWidget {
  final String letter;
  final String? word;
  final String? audioPath;
  final double size;
  final Color? color;
  final Color? iconColor;

  const AudioButton({
    super.key,
    required this.letter,
    this.word,
    this.audioPath,
    this.size = 44,
    this.color,
    this.iconColor,
  });

  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isPlaying) return;

    setState(() => _isPlaying = true);
    _animController.forward().then((_) => _animController.reverse());

    if (widget.audioPath != null && widget.audioPath!.isNotEmpty) {
      await AudioService.instance.playLetterSound(
        context,
        letter: widget.letter,
        word: widget.word,
        audioPath: widget.audioPath,
      );
    } else {
      await AudioService.instance.playTamilAudio(widget.letter);
    }

    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.color ?? AppColors.primary;
    final fgColor = widget.iconColor ?? Colors.white;

    return Semantics(
      label: '${widget.letter} உச்சரிப்பு ஒலி',
      button: true,
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _isPlaying ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                color: fgColor,
                size: widget.size * 0.55,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
