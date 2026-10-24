import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'auth_controller.dart';
import '../../../ui/ui.dart';
import 'widgets/brand_mark.dart';
import 'widgets/intro_scenes.dart';

/// Length of the scripted intro (three scenes, then the logo).
const Duration kSplashIntroDuration = Duration(milliseconds: 3400);

/// How long the splash stays up at minimum, so the intro is seen even when
/// auth resolves in a few milliseconds.
final splashMinDurationProvider = Provider<Duration>((ref) => kSplashIntroDuration);

/// Completes once the intro has had its minimum time; the router keeps the
/// splash up until then.
final splashIntroDoneProvider = FutureProvider<void>((ref) => Future<void>.delayed(ref.watch(splashMinDurationProvider)));

// Timeline (ms). Each scene slides in from the right, holds, and slides out
// to the left as the next one arrives; the logo takes over after the third.
const _sceneSlot = 850;
const _sceneSpan = 1050; // slot + overlap with the next scene
const _sceneEnter = 320;
const _sceneExit = 260;
const _logoAt = 2550;

/// Launch intro on the brand gradient: shop → groceries → delivery scenes
/// with captions and step dots, then the logo springs in with ripple rings,
/// the wordmark and a loading bar. Also hosts the retry when the profile
/// could not be fetched.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: kSplashIntroDuration)..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final failed = auth.hasError && !auth.isLoading;
    final captions = [ref.t('splash.scene1'), ref.t('splash.scene2'), ref.t('splash.scene3')];

    return Scaffold(
      backgroundColor: AppColors.brand,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: _DriftingGlows()),
            SafeArea(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final ms = _c.value * kSplashIntroDuration.inMilliseconds;
                  return Stack(
                    children: [
                      for (var i = 0; i < IntroScene.values.length; i++)
                        _SceneLayer(scene: IntroScene.values[i], caption: captions[i], index: i, ms: ms),
                      if (ms < _logoAt + 300) Align(alignment: const Alignment(0, 0.72), child: _StepDots(ms: ms)),
                      // Mounted only when its turn comes: its looping rings
                      // would otherwise sit visible over the scenes.
                      if (ms >= _logoAt || failed)
                        Center(
                          child: _LogoStage(
                            appName: ref.t('common.appName'),
                            tagline: ref.t('welcome.title'),
                            failed: failed,
                            errorText: failed ? '${ref.t('auth.sessionLoadFailed')}. ${ref.errorText(auth.error)}' : null,
                            retryLabel: ref.t('common.retry'),
                            onRetry: () => ref.invalidate(authControllerProvider),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 0→1 progress of [ms] through [start, start+length], clamped and eased.
double _phase(double ms, num start, num length, [Curve curve = Curves.linear]) =>
    curve.transform(((ms - start) / length).clamp(0.0, 1.0));

class _SceneLayer extends StatelessWidget {
  const _SceneLayer({required this.scene, required this.caption, required this.index, required this.ms});

  final IntroScene scene;
  final String caption;
  final int index;
  final double ms;

  @override
  Widget build(BuildContext context) {
    final start = index * _sceneSlot;
    final end = start + _sceneSpan;
    if (ms < start || ms > end) return const SizedBox.shrink();

    final enter = _phase(ms, start, _sceneEnter, Curves.easeOutCubic);
    final exit = _phase(ms, end - _sceneExit, _sceneExit, Curves.easeInCubic);
    final local = ms - start;

    // Per-scene life while on stage.
    var dx = 0.0;
    var dy = 0.0;
    var tilt = 0.0;
    switch (scene) {
      case IntroScene.shop:
        dy = -4 * math.sin(local / 180);
      case IntroScene.bag:
        dy = -10 * (math.sin(local / 110)).abs() * (1 - _phase(ms, start + 500, 300));
        tilt = 0.04 * math.sin(local / 140);
      case IntroScene.delivery:
        dx = -18 + 30 * _phase(ms, start + 150, 800, Curves.easeOutCubic);
        dy = 1.5 * math.sin(local / 40); // road vibration
    }

    final opacity = (enter * (1 - exit)).clamp(0.0, 1.0);
    final slide = 60 * (1 - enter) - 60 * exit;
    final scale = 0.82 + 0.18 * enter - 0.06 * exit;

    return Align(
      alignment: const Alignment(0, -0.18),
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(slide + dx, dy),
              child: Transform.rotate(
                angle: tilt,
                child: Transform.scale(scale: scale, child: IntroSceneArt(scene, size: 230)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Transform.translate(
              offset: Offset(slide * 0.6, 8 * (1 - enter)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Text(caption, textAlign: TextAlign.center, style: AppText.h2.onBrand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three dots; the current scene's dot stretches into a pill.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.ms});

  final double ms;

  @override
  Widget build(BuildContext context) {
    final current = (ms / _sceneSlot).floor().clamp(0, 2);
    final fade = 1 - _phase(ms, _logoAt - 100, 300);
    return Opacity(
      opacity: fade * _phase(ms, 0, 300),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            AnimatedContainer(
              duration: AppDurations.normal,
              curve: AppCurves.standard,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == current ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: i == current ? 1 : 0.35),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}

/// Final beat: ripple rings, the logo springing in, the wordmark typing in,
/// the tagline and a loading bar (or the retry when the profile failed).
class _LogoStage extends StatelessWidget {
  const _LogoStage({
    required this.appName,
    required this.tagline,
    required this.failed,
    required this.errorText,
    required this.retryLabel,
    required this.onRetry,
  });

  final String appName;
  final String tagline;
  final bool failed;
  final String? errorText;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    const at = 0; // mounted at _logoAt, so delays are relative to that
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < 3; i++) _RippleRing(delay: (at + 250 + i * 450).ms),
              // Outer: one-shot spring entrance; inner: gentle breathing loop.
              const BrandMark(size: 96)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 1, end: 1.035, duration: 1400.ms, curve: Curves.easeInOut)
                  .animate(delay: at.ms)
                  .fadeIn(duration: 250.ms)
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 750.ms, curve: Curves.elasticOut)
                  .rotate(begin: -0.04, end: 0, duration: 600.ms, curve: AppCurves.emphasized),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Wordmark(text: appName, delay: at + 250),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Text(tagline, textAlign: TextAlign.center, style: AppText.body.withColor(AppColors.white.withValues(alpha: 0.82))),
        ).animate(delay: (at + 550).ms).fadeIn(duration: 400.ms).moveY(begin: 10, end: 0, curve: AppCurves.emphasized),
        const SizedBox(height: AppSpacing.xxxl),
        if (failed) ...[
          // Profile fetch failed for a non-auth reason (offline, server
          // down). The session is kept; let the user try again.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Text(errorText ?? '', textAlign: TextAlign.center, style: AppText.bodySm.withColor(AppColors.white)),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: retryLabel,
            icon: LucideIcons.refreshCw,
            variant: AppButtonVariant.secondary,
            expand: false,
            onPressed: onRetry,
          ),
        ] else
          const _LoadingBar().animate(delay: (at + 700).ms).fadeIn(duration: 350.ms),
      ],
    );
  }
}

/// The app name, each letter rising and un-blurring a beat after the last.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.text, required this.delay});

  final String text;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final style = AppText.sarlavhaL.onBrand.copyWith(letterSpacing: -0.5);
    final letters = text.characters.toList();
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < letters.length; i++)
            Text(letters[i], style: style)
                .animate(delay: (delay + i * 45).ms)
                .fadeIn(duration: 300.ms)
                .moveY(begin: 14, end: 0, duration: 420.ms, curve: AppCurves.emphasized)
                .blurY(begin: 4, end: 0, duration: 300.ms),
        ],
      ),
    );
  }
}

/// A white ring that grows out of the logo and fades, on repeat.
class _RippleRing extends StatelessWidget {
  const _RippleRing({required this.delay});

  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white.withValues(alpha: 0.5), width: 1.5),
        ),
      )
          .animate(delay: delay, onPlay: (c) => c.repeat())
          .scaleXY(begin: 0.85, end: 2.0, duration: 1800.ms, curve: Curves.easeOutCubic)
          .fadeOut(begin: 0.55, duration: 1800.ms, curve: Curves.easeOut),
    );
  }
}

/// Indeterminate 120px bar: a bright segment sweeping across a faint track.
class _LoadingBar extends StatelessWidget {
  const _LoadingBar();

  @override
  Widget build(BuildContext context) {
    const width = 120.0;
    const segment = 40.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: width,
        height: 3,
        color: AppColors.white.withValues(alpha: 0.18),
        alignment: Alignment.centerLeft,
        child: Container(width: segment, height: 3, color: AppColors.white)
            .animate(onPlay: (c) => c.repeat())
            .moveX(begin: -segment, end: width, duration: 1100.ms, curve: Curves.easeInOutCubic),
      ),
    );
  }
}

/// Two large, very soft light blobs slowly drifting behind everything, so
/// the gradient feels alive without drawing attention.
class _DriftingGlows extends StatefulWidget {
  const _DriftingGlows();

  @override
  State<_DriftingGlows> createState() => _DriftingGlowsState();
}

class _DriftingGlowsState extends State<_DriftingGlows> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value * 2 * math.pi;
            return Stack(
              children: [
                Align(
                  alignment: Alignment(-0.9 + 0.25 * math.sin(t), -0.8 + 0.15 * math.cos(t)),
                  child: const _Glow(size: 360, color: Color(0xFF2FA37A)),
                ),
                Align(
                  alignment: Alignment(0.9 + 0.2 * math.cos(t), 0.85 + 0.15 * math.sin(t)),
                  child: const _Glow(size: 420, color: Color(0xFF06382A)),
                ),
              ],
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 900.ms);
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)]),
      ),
    );
  }
}
