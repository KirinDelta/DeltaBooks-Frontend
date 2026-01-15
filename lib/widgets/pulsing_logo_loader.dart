import 'package:flutter/material.dart';
import '../theme/app_images.dart';

/// A custom loading widget that displays a pulsing logo animation
class PulsingLogoLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const PulsingLogoLoader({
    super.key,
    this.size = 60,
    this.color,
  });

  @override
  State<PulsingLogoLoader> createState() => _PulsingLogoLoaderState();
}

class _PulsingLogoLoaderState extends State<PulsingLogoLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.scale(
            scale: _animation.value,
            child: Image.asset(
              AppImages.logo,
              height: widget.size,
              fit: BoxFit.contain,
              color: widget.color,
              colorBlendMode: widget.color != null ? BlendMode.srcIn : BlendMode.color,
            ),
          ),
        );
      },
    );
  }
}
