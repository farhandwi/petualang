import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Image yang otomatis pilih sumber yang tepat berdasarkan format URL:
/// - kosong → [fallback]
/// - dimulai dengan `assets/` (atau tidak ada protokol & relative ke proyek)
///   → `Image.asset`
/// - dimulai dengan `http://` / `https://` → `Image.network`
/// - relatif (mis. `/uploads/foo.png`) → di-prefix ke `AppConfig.baseUrl`
///   lalu `Image.network`.
///
/// Jika asset/network gagal (mis. asset tidak terdaftar di pubspec atau
/// network 404), fallback widget ditampilkan.
class AdaptiveImage extends StatelessWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext)? fallbackBuilder;

  const AdaptiveImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.fallbackBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final raw = (url ?? '').trim();
    final fallback = fallbackBuilder?.call(context) ?? _defaultFallback(context);

    if (raw.isEmpty) return fallback;

    if (raw.startsWith('assets/')) {
      return Image.asset(
        raw,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    final resolved = raw.startsWith('http://') || raw.startsWith('https://')
        ? raw
        : AppConfig.resolveImageUrl(raw);

    return Image.network(
      resolved,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  Widget _defaultFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.image_rounded, color: Colors.grey),
    );
  }
}
