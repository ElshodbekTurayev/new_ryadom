import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/env.dart';
import '../tokens.dart';

/// Builds the image provider for a resolved media url.
///
/// * Mobile: [CachedNetworkImageProvider] (disk cache via flutter_cache_manager).
/// * Web: a plain [NetworkImage] with [WebHtmlElementStrategy.fallback]. On web
///   flutter_cache_manager has no persistent storage (bytes are only kept in
///   memory — the browser HTTP cache does the real caching), and both of its
///   web loaders fetch the bytes via XHR, which the browser blocks whenever the
///   image host does not send `Access-Control-Allow-Origin` (our own
///   `/uploads/*` static files, many CDNs). The fallback strategy first tries
///   the CORS fetch and, if that fails, renders the image in an `<img>` element,
///   which needs no CORS at all.
///
/// The decoded bitmap is downscaled (never upscaled) to [cacheWidth] to keep
/// image-cache memory small on low-end phones.
@visibleForTesting
ImageProvider<Object> appImageProvider(String resolvedUrl, {int? cacheWidth}) {
  final ImageProvider<Object> base = kIsWeb
      ? NetworkImage(resolvedUrl, webHtmlElementStrategy: WebHtmlElementStrategy.fallback)
      : CachedNetworkImageProvider(resolvedUrl);
  if (cacheWidth == null || cacheWidth <= 0) return base;
  return ResizeImage(base, width: cacheWidth, policy: ResizeImagePolicy.fit, allowUpscaling: false);
}

/// Network image with a quiet placeholder, fade-in and a graceful fallback.
/// Server-relative paths (/uploads/x.jpg) are resolved against the API host.
/// Transient failures (flaky mobile network, dev server restart) are retried
/// automatically a couple of times before the fallback icon is shown.
class AppImage extends StatefulWidget {
  const AppImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.radius,
    this.fit = BoxFit.cover,
    this.fallbackIcon = LucideIcons.image,
    this.fallbackColor = AppColors.ink100,
    this.memCacheWidth,
    this.semanticLabel,
  });

  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? radius;
  final BoxFit fit;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final int? memCacheWidth;
  final String? semanticLabel;

  /// Delays before each automatic retry; after the last one the fallback stays.
  static const retryDelays = [Duration(seconds: 2), Duration(seconds: 6)];

  @override
  State<AppImage> createState() => _AppImageState();
}

class _AppImageState extends State<AppImage> {
  int _attempt = 0;
  Timer? _retryTimer;

  String? get _resolved {
    final url = widget.url?.trim();
    return (url == null || url.isEmpty) ? null : Env.resolveMediaUrl(url);
  }

  int? get _cacheWidth {
    if (widget.memCacheWidth != null) return widget.memCacheWidth;
    final w = widget.width;
    return (w != null && w.isFinite) ? (w * 2.5).round() : null;
  }

  @override
  void didUpdateWidget(AppImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _retryTimer?.cancel();
      _retryTimer = null;
      _attempt = 0;
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleRetry(ImageProvider<Object> provider) {
    if (_retryTimer != null || _attempt >= AppImage.retryDelays.length) return;
    _retryTimer = Timer(AppImage.retryDelays[_attempt], () {
      _retryTimer = null;
      if (!mounted) return;
      // Drop the failed entry so the next build really hits the network again.
      provider.evict();
      setState(() => _attempt++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.radius ?? BorderRadius.circular(AppRadius.sm);
    final resolved = _resolved;
    final fallback = _Fallback(icon: widget.fallbackIcon, color: widget.fallbackColor);

    Widget child;
    if (resolved == null) {
      child = fallback;
    } else {
      final provider = appImageProvider(resolved, cacheWidth: _cacheWidth);
      child = Image(
        key: ValueKey('$resolved#$_attempt'),
        image: provider,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        semanticLabel: widget.semanticLabel,
        excludeFromSemantics: widget.semanticLabel == null,
        gaplessPlayback: true,
        frameBuilder: (context, image, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return image;
          return Stack(
            fit: StackFit.passthrough,
            children: [
              const Positioned.fill(child: _Placeholder()),
              AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: AppDurations.slow,
                curve: Curves.easeOut,
                child: image,
              ),
            ],
          );
        },
        errorBuilder: (context, error, stack) {
          if (_attempt < AppImage.retryDelays.length) {
            _scheduleRetry(provider);
            return const _Placeholder();
          }
          return fallback;
        },
      );
    }

    return ClipRRect(
      borderRadius: r,
      child: SizedBox(width: widget.width, height: widget.height, child: child),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink100, AppColors.ink50],
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.ink300, size: 24),
    );
  }
}

/// Circular avatar with initials fallback (profile, shop logos in lists).
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.url, this.name, this.size = 44, this.background = AppColors.green100, this.foreground = AppColors.green700});

  final String? url;
  final String? name;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final initials = (name ?? '').trim().isEmpty
        ? '•'
        : name!.trim().split(RegExp(r'\s+')).take(2).map((p) => p.characters.first.toUpperCase()).join();
    if (url == null || url!.trim().isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(fontSize: size * 0.38, fontWeight: FontWeight.w800, color: foreground),
        ),
      );
    }
    return AppImage(url: url, width: size, height: size, radius: BorderRadius.circular(size / 2), fallbackIcon: LucideIcons.store);
  }
}
