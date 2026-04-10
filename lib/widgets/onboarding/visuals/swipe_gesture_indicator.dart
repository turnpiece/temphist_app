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

    // Slide right, snap back invisibly once fully faded out.
    // The fade-out ends exactly when the snap happens (both at t=55%)
    // so the jump is never visible.
    _slide = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 48.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 55,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 45),
    ]).animate(_controller);

    _fade = TweenSequence([
      // Hold visible while sliding
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      // Fade out so opacity reaches 0 exactly when slide snaps at t=55%
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      // Fade back in at origin
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      // Hold visible before next cycle
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SizedBox + ClipRect ensure the sliding animation never overflows its
    // parent — the content fades out before the right edge clip is visible.
    return SizedBox(
      width: double.infinity,
      child: ClipRect(
        child: AnimatedBuilder(
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
        ),
      ),
    );
  }
}
