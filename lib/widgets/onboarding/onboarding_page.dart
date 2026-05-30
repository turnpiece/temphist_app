import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// Scroll view that shows a bottom-fade hint when content overflows the viewport.
/// Use inside a [LayoutBuilder] so [constraints] reflects the available height.
class OnboardingScrollBody extends StatefulWidget {
  final BoxConstraints constraints;
  final Widget child;

  const OnboardingScrollBody({
    super.key,
    required this.constraints,
    required this.child,
  });

  @override
  State<OnboardingScrollBody> createState() => _OnboardingScrollBodyState();
}

class _OnboardingScrollBodyState extends State<OnboardingScrollBody> {
  final _controller = ScrollController();
  bool _showFade = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_checkOverflow);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  void _checkOverflow() {
    if (!mounted || !_controller.hasClients) return;
    final pos = _controller.position;
    final show = pos.maxScrollExtent > 1 &&
        pos.pixels < pos.maxScrollExtent - 1;
    if (show != _showFade) setState(() => _showFade = show);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: _controller,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minHeight: widget.constraints.maxHeight),
            child: Center(child: widget.child),
          ),
        ),
        if (_showFade)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 56,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, kBackgroundColourDark],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Reusable layout for a single onboarding page.
/// Portrait: visual centred above title and body.
/// Landscape: visual on the left, title and body on the right.
class OnboardingPage extends StatelessWidget {
  final String title;
  final String body;
  final Widget visual;
  final bool centerVisual;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.body,
    required this.visual,
    this.centerVisual = true,
  });

  @override
  Widget build(BuildContext context) {
    return _buildPortrait();
  }

  Widget _buildPortrait() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxHeight < 500;
          final isMedium = constraints.maxHeight < 700;
          final titleSize = isSmall ? 20.0 : (isMedium ? 22.0 : 24.0);
          final visualGap = isSmall ? 12.0 : (isMedium ? 24.0 : 40.0);
          final titleBodyGap = isSmall ? 10.0 : (isMedium ? 14.0 : 16.0);
          return OnboardingScrollBody(
            constraints: constraints,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (centerVisual) Center(child: visual) else visual,
                SizedBox(height: visualGap),
                _titleWidget(fontSize: titleSize),
                if (body.isNotEmpty) ...[
                  SizedBox(height: titleBodyGap),
                  _bodyWidget(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _titleWidget({double fontSize = 24.0}) => Text(
        title,
        style: TextStyle(
          color: kHeadingColour,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      );

  Widget _bodyWidget() => Text(
        body,
        style: const TextStyle(
          color: kTextPrimaryColour,
          fontSize: kFontSizeBody,
          height: 1.5,
        ),
      );
}
