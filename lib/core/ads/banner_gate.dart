import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many visible screens currently want the anchored banner.
///
/// Home and the between-rounds screen each acquire while they are the current
/// route. The reveal flow never acquires.
class AnchoredBannerHolds extends Notifier<int> {
  int _count = 0;

  @override
  int build() => 0;

  void acquire() {
    _count += 1;
    state = _count;
  }

  void release() {
    if (_count == 0) return;
    _count -= 1;
    state = _count;
  }
}

final anchoredBannerHoldsProvider = NotifierProvider<AnchoredBannerHolds, int>(
  AnchoredBannerHolds.new,
);

/// Hides the banner immediately when a round ends, before the next pass-the-
/// phone screen is built.
class AnchoredBannerSuppress extends Notifier<bool> {
  @override
  bool build() => false;

  void setSuppressed(bool value) {
    if (state == value) return;
    state = value;
  }
}

final anchoredBannerSuppressProvider =
    NotifierProvider<AnchoredBannerSuppress, bool>(AnchoredBannerSuppress.new);

/// True only when a menu or between-rounds screen is asking for a banner and
/// the caller has not blocked it (the secret reveal, or the deal that starts
/// the next one).
bool showAnchoredBanner({
  required int holds,
  required bool suppressed,
  required bool blocked,
}) {
  if (holds <= 0 || suppressed || blocked) return false;
  return true;
}

/// Tells [anchoredBannerHoldsProvider] whether this route wants a banner.
///
/// Updates are deferred to a post-frame callback so a route change does not
/// notify ancestors during build. The phase gate in [showAnchoredBanner] still
/// hides the banner on the same frame the reveal starts.
class SyncAnchoredBanner extends ConsumerStatefulWidget {
  const SyncAnchoredBanner({super.key, required this.allowed});

  final bool allowed;

  @override
  ConsumerState<SyncAnchoredBanner> createState() => _SyncAnchoredBannerState();
}

class _SyncAnchoredBannerState extends ConsumerState<SyncAnchoredBanner> {
  bool _holding = false;
  AnchoredBannerHolds? _holds;

  void _sync() {
    if (!mounted) return;
    final current = ModalRoute.of(context)?.isCurrent ?? false;
    final want = widget.allowed && current;
    if (want == _holding) return;
    final holds = _ensureHolds();
    _holding = want;
    if (want) {
      holds.acquire();
    } else {
      holds.release();
    }
  }

  AnchoredBannerHolds _ensureHolds() {
    final existing = _holds;
    if (existing != null) return existing;
    final created = ref.read(anchoredBannerHoldsProvider.notifier);
    _holds = created;
    return created;
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant SyncAnchoredBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void dispose() {
    if (_holding) {
      _holding = false;
      _holds?.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ModalRoute.of(context);
    return const SizedBox.shrink();
  }
}
