import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'auth_controller.dart';
import '../../../ui/ui.dart';

/// Length of the scripted intro: three scenes, the last one holding until
/// the app opens.
const Duration kSplashIntroDuration = Duration(milliseconds: 2700);

/// How long the splash stays up at minimum, so the intro is seen even when
/// auth resolves in a few milliseconds.
final splashMinDurationProvider = Provider<Duration>((ref) => kSplashIntroDuration);

/// Completes once the intro has had its minimum time; the router keeps the
/// splash up until then.
final splashIntroDoneProvider = FutureProvider<void>((ref) => Future<void>.delayed(ref.watch(splashMinDurationProvider)));

// Timeline (ms). Each scene slides in from the right, holds, and slides out
// to the left as the next one arrives; the last one stays on screen.
const _sceneSlot = 850;
const _sceneSpan = 1050; // slot + overlap with the next scene
const _sceneEnter = 320;
const _sceneExit = 260;

/// Launch intro on the brand gradient: shop → groceries → delivery scenes
/// with captions and step dots. Also hosts the retry when the profile could
/// not be fetched.
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
                      Align(alignment: const Alignment(0, 0.72), child: _StepDots(ms: ms)),
                      if (failed)
                        // Profile fetch failed for a non-auth reason (offline,
                        // server down). The session is kept; let the user retry.
                        Align(
                          alignment: const Alignment(0, 0.95),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${ref.t('auth.sessionLoadFailed')}. ${ref.errorText(auth.error)}',
                                  textAlign: TextAlign.center,
                                  style: AppText.bodySm.withColor(AppColors.white),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppButton(
                                  label: ref.t('common.retry'),
                                  icon: LucideIcons.refreshCw,
                                  variant: AppButtonVariant.secondary,
                                  expand: false,
                                  onPressed: () => ref.invalidate(authControllerProvider),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: AppDurations.slow),
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
    // The last scene never exits: it holds until the app opens.
    final isLast = index == IntroScene.values.length - 1;
    if (ms < start || (!isLast && ms > end)) return const SizedBox.shrink();

    final enter = _phase(ms, start, _sceneEnter, Curves.easeOutCubic);
    final exit = isLast ? 0.0 : _phase(ms, end - _sceneExit, _sceneExit, Curves.easeInCubic);
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
    return Opacity(
      opacity: _phase(ms, 0, 300),
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
