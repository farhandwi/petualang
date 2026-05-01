import 'package:flutter/material.dart';
import '../../config/app_config.dart';

/// Universal image widget yang otomatis pilih `Image.asset` atau `Image.network`
/// berdasarkan format URL.
///
/// Aturan:
/// - URL diawali `http://` atau `https://` → `Image.network`
/// - URL diawali `assets/` → `Image.asset` (local bundled image)
/// - Path relatif (mis. `/uploads/foo.jpg`) → `Image.network` dengan baseUrl
/// - Null/empty → tampilkan `errorBuilder`
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.url,
    required this.errorBuilder,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?) errorBuilder;

  bool get _isAsset => url != null && url!.startsWith('assets/');
  bool get _isHttp =>
      url != null &&
      (url!.startsWith('http://') || url!.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Builder(
        builder: (ctx) => errorBuilder(ctx, 'empty url', null),
      );
    }

    if (_isAsset) {
      return Image.asset(
        url!,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    // Network image — handle absolute & relative
    final resolvedUrl = _isHttp ? url! : AppConfig.resolveImageUrl(url);
    return Image.network(
      resolvedUrl,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}
