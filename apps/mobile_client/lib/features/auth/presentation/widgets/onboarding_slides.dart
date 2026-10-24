import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;

import '../../../../ui/ui.dart';

class OnboardingSlide {
  const OnboardingSlide({required this.scene, required this.title, required this.subtitle});

  final IntroScene scene;
  final String title;
  final String subtitle;
}

/// Auto-advancing PageView of slides — each the app's scene art on a
/// brand-green card (same art as the launch intro and Home promos) with a
/// title and subtitle — plus an animated dots indicator. Auto-advance pauses while the user is swiping and restarts
/// from a full interval afterwards.
class OnboardingSlides extends StatefulWidget {
  const OnboardingSlides({super.key, required this.slides, this.interval = const Duration(milliseconds: 3500)});

  final List<OnboardingSlide> slides;
  final Duration interval;
  @override
  State<OnboardingSlides> createState() => _OnboardingSlidesState();
}

class _OnboardingSlidesState extends State<OnboardingSlides> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;
  bool _userScrolling = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.slides.length < 2) return;
    _timer = Timer.periodic(widget.interval, (_) => _advance());
  }

  void _advance() {
    if (_userScrolling || !mounted || !_controller.hasClients) return;
    final next = (_page + 1) % widget.slides.length;
    _controller.animateToPage(next, duration: AppDurations.slow, curve: AppCurves.standard);
  }

  bool _onScroll(ScrollNotification n) {
    if (n is UserScrollNotification) {
      final scrolling = n.direction != ScrollDirection.idle;
      if (scrolling != _userScrolling) {
        _userScrolling = scrolling;
        if (!scrolling) _startTimer(); // give the user a full interval after a swipe
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.slides.length,
              onPageChanged: (i) => setState(() => _page = i),
              // Parallax: art and text drift at different speeds while swiping.
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final page = _controller.hasClients && _controller.position.haveDimensions ? _controller.page ?? 0 : _page.toDouble();
                  return _Slide(slide: widget.slides[i], offset: (i - page).clamp(-1.0, 1.0));
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Dots(count: widget.slides.length, active: _page),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide, required this.offset});

  final OnboardingSlide slide;

  /// -1..1: how far this page is from the centre of the viewport.
  final double offset;

  @override
  Widget build(BuildContext context) {
    final fade = 1 - offset.abs() * 0.6;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                // Capped so the circle keeps breathing room on phones.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300, maxHeight: 300),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle, boxShadow: AppShadows.brand),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft light blooms, shifted against the swipe for depth.
                          Positioned(top: -60 + offset * 20, right: -50 - offset * 40, child: _Bloom(size: 220, opacity: 0.10)),
                          Positioned(bottom: -70, left: -60 + offset * 40, child: _Bloom(size: 200, opacity: 0.06)),
                          Transform.translate(
                            offset: Offset(offset * 90, 0),
                            child: Transform.scale(
                              scale: 1 - offset.abs() * 0.12,
                              child: FractionallySizedBox(widthFactor: 0.72, child: IntroSceneArt(slide.scene, size: 260)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Opacity(
                opacity: fade.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(offset * 40, 0),
                  child: Column(
                    children: [
                      Text(slide.title, textAlign: TextAlign.center, style: AppText.h1, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        slide.subtitle,
                        textAlign: TextAlign.center,
                        style: AppText.bodyLg.secondary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bloom extends StatelessWidget {
  const _Bloom({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.white.withValues(alpha: opacity),
    ),
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDurations.normal,
            curve: AppCurves.standard,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? AppColors.brand : AppColors.ink200,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
      ],
    );
  }
}
