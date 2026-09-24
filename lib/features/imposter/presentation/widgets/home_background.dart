import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Full-page illustrated home background (characters + logo baked in).
///
/// The artwork is drawn in three slices so it fits any screen height without
/// cropping the header: the top slice (characters + logo) is pinned just
/// below [headerTop], the bottom slice (waves) is pinned to the bottom edge,
/// and a plain band from the middle of the art is stretched to fill the gap.
class HomeBackground extends StatefulWidget {
  const HomeBackground({
    super.key,
    required this.headerTop,
    required this.scale,
  });

  static const asset = 'assets/images/home_background.png';
  static const imageSize = Size(941, 1672);

  /// Source row where the header artwork starts / ends (logo shadow included).
  static const headerStartRow = 290.0;
  static const headerEndRow = 915.0;

  /// Plain band used to fill any extra height.
  static const _bandTop = 955.0;
  static const _bandBottom = 975.0;

  /// Screen y at which [headerStartRow] is drawn.
  final double headerTop;

  /// Source pixel → logical pixel scale.
  final double scale;

  @override
  State<HomeBackground> createState() => _HomeBackgroundState();
}

class _HomeBackgroundState extends State<HomeBackground> {
  ImageStream? _stream;
  late final ImageStreamListener _listener = ImageStreamListener(
    (info, _) => setState(() => _image = info.image),
  );
  ui.Image? _image;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      HomeBackground.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key != _stream?.key) {
      _stream?.removeListener(_listener);
      _stream = stream..addListener(_listener);
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: _HomeBackgroundPainter(_image, widget.headerTop, widget.scale),
    ),
  );
}

class _HomeBackgroundPainter extends CustomPainter {
  _HomeBackgroundPainter(this.image, this.headerTop, this.scale);

  final ui.Image? image;
  final double headerTop;
  final double scale;

  static const _fallback = Color(0xFFF4EFFD);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _fallback);
    final image = this.image;
    if (image == null) return;

    const src = HomeBackground.imageSize;
    final s = scale;
    final left = (size.width - src.width * s) / 2;
    final width = src.width * s;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    // Asset may be served at a different resolution than the source size.
    final px = image.width / src.width;

    void draw(double fromRow, double toRow, double top, double height) {
      if (height <= 0) return;
      canvas.drawImageRect(
        image,
        Rect.fromLTRB(0, fromRow * px, image.width.toDouble(), toRow * px),
        Rect.fromLTWH(left, top, width, height),
        paint,
      );
    }

    final originY = headerTop - HomeBackground.headerStartRow * s;
    const bandTop = HomeBackground._bandTop;
    const bandBottom = HomeBackground._bandBottom;
    final topEnd = originY + bandTop * s;
    final bottomHeight = (src.height - bandBottom) * s;
    final bottomStart = size.height - bottomHeight;

    draw(bandBottom, src.height, bottomStart, bottomHeight);
    draw(bandTop, bandBottom, topEnd, bottomStart - topEnd);
    draw(0, bandTop, originY, bandTop * s);
  }

  @override
  bool shouldRepaint(_HomeBackgroundPainter old) =>
      old.image != image || old.headerTop != headerTop || old.scale != scale;
}
