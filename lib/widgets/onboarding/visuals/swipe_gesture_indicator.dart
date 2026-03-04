import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';

/// Animated swipe-right gesture hint shown on the Swipe onboarding page.
class SwipeGestureIndicator extends StatefulWidget {
  const SwipeGestureIndicator({super.key});

  @override
  State<SwipeGestureIndicator> createState() => _SwipeGestureIndicatorState();
}

class _SwipeGestureIndicatorState extends State<SwipeGestureIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Slide right, hold briefly, snap back invisibly
    _slide = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 48.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 45),
    ]).animate(_controller);

    _fade = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(_slide.value, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swipe_right_outlined, color: kAccentColour, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'swipe right to explore',
                  style: TextStyle(
                    color: kGreyLabelColour,
                    fontSize: kFontSizeBody,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
