import 'package:flutter/material.dart';

/// Shrinks (or grows) everything inside [child] – text, icons, padding and
/// tap targets – by [scale] while still filling the available space.
///
/// The child is laid out in a box `1 / scale` times the available size and
/// then painted scaled by [scale], so layout stays proportional instead of
/// leaving empty margins. [MediaQuery] metrics (size, safe-area padding,
/// keyboard insets, pixel ratio) are converted into the scaled coordinates so
/// [SafeArea] and friends still line up with the real screen edges.
class UniformScale extends StatelessWidget {
  const UniformScale({super.key, required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(
        constraints.maxWidth / scale,
        constraints.maxHeight / scale,
      );
      final media = MediaQuery.of(context);
      return FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: MediaQuery(
          data: media.copyWith(
            size: size,
            devicePixelRatio: media.devicePixelRatio * scale,
            padding: media.padding / scale,
            viewPadding: media.viewPadding / scale,
            viewInsets: media.viewInsets / scale,
            systemGestureInsets: media.systemGestureInsets / scale,
          ),
          child: SizedBox.fromSize(size: size, child: child),
        ),
      );
    },
  );
}
