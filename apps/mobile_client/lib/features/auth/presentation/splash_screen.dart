import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'auth_controller.dart';
import '../../../ui/ui.dart';
import 'widgets/brand_mark.dart';

/// How long the intro plays at minimum. Auth often resolves in a few
/// milliseconds, which used to cut the animation off before it was seen.
final splashMinDurationProvider = Provider<Duration>((ref) => const Duration(milliseconds: 1800));

/// Completes once the intro has had its minimum time; the router keeps the
/// splash up until then.
final splashIntroDoneProvider = FutureProvider<void>((ref) => Future<void>.delayed(ref.watch(splashMinDurationProvider)));

/// Brand intro shown while the auth state loads: drifting glows, ripple
/// rings, the logo springing in, the wordmark typing in letter by letter, the
/// tagline and a slim loading bar. Also hosts the retry when the profile
/// could not be fetched.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final failed = auth.hasError && !auth.isLoading;
    final appName = ref.t('common.appName');

    return Scaffold(
      backgroundColor: AppColors.brand,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: _DriftingGlows()),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          for (var i = 0; i < 3; i++) _RippleRing(delay: (300 + i * 450).ms),
                          // Outer: one-shot spring entrance; inner: gentle breathing loop.
                          const BrandMark(size: 96)
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scaleXY(begin: 1, end: 1.035, duration: 1400.ms, curve: Curves.easeInOut)
                              .animate()
                              .fadeIn(duration: 300.ms)
                              .scale(begin: const Offset(0.55, 0.55), end: const Offset(1, 1), duration: 700.ms, curve: Curves.elasticOut)
                              .rotate(begin: -0.03, end: 0, duration: 600.ms, curve: AppCurves.emphasized),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _Wordmark(text: appName),
                    const SizedBox(height: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Text(
                        ref.t('welcome.title'),
                        textAlign: TextAlign.center,
                        style: AppText.body.withColor(AppColors.white.withValues(alpha: 0.82)),
                      ),
                    ).animate(delay: 750.ms).fadeIn(duration: 450.ms).moveY(begin: 10, end: 0, curve: AppCurves.emphasized),
                    const SizedBox(height: AppSpacing.xxxl),
                    if (failed) ...[
                      // Profile fetch failed for a non-auth reason (offline, server
                      // down). The session is kept; let the user try again.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                        child: Text(
                          '${ref.t('auth.sessionLoadFailed')}. ${ref.errorText(auth.error)}',
                          textAlign: TextAlign.center,
                          style: AppText.bodySm.withColor(AppColors.white),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: ref.t('common.retry'),
                        icon: LucideIcons.refreshCw,
                        variant: AppButtonVariant.secondary,
                        expand: false,
                        onPressed: () => ref.invalidate(authControllerProvider),
                      ).animate().fadeIn(duration: AppDurations.slow),
                    ] else
                      const _LoadingBar().animate(delay: 1000.ms).fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Ryadom", each letter rising and fading in a beat after the previous one.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.text});

  final String text;

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
                .animate(delay: (380 + i * 45).ms)
                .fadeIn(duration: 320.ms)
                .moveY(begin: 14, end: 0, duration: 420.ms, curve: AppCurves.emphasized)
                .blurY(begin: 4, end: 0, duration: 320.ms),
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
