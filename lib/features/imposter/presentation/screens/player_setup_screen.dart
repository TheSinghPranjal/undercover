import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/game_background.dart';
import '../../../../core/widgets/player_avatar.dart';
import '../../domain/entities/player.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/player_validator.dart';
import '../providers/providers.dart';
import '../widgets/game_button.dart';
import '../widgets/labels.dart';
import 'game_config_screen.dart';

class PlayerSetupScreen extends ConsumerStatefulWidget {
  const PlayerSetupScreen({super.key});

  @override
  ConsumerState<PlayerSetupScreen> createState() => _PlayerSetupScreenState();
}

class _PlayerSetupScreenState extends ConsumerState<PlayerSetupScreen> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final error = ref.read(gameControllerProvider.notifier).validateName(value);
    setState(
      () => _error = error == PlayerNameError.empty ? null : error?.message,
    );
  }

  void _add() {
    final controller = ref.read(gameControllerProvider.notifier);
    final error = controller.addPlayer(_textController.text);
    if (error != null) {
      setState(() => _error = error.message);
      _focusNode.requestFocus();
      return;
    }
    final index = ref.read(playersProvider).length - 1;
    _listKey.currentState?.insertItem(index, duration: AppDurations.medium);
    _textController.clear();
    setState(() => _error = null);
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: AppDurations.medium,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _remove(Player player, int index) {
    ref.read(gameControllerProvider.notifier).removePlayer(player.id);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _PlayerTile(player: player, animation: animation, onRemove: null),
      duration: AppDurations.medium,
    );
    // Re-validate the draft – removing a player may clear a duplicate error.
    _onChanged(_textController.text);
  }

  Future<void> _rename(Player player) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(player: player),
    );
    if (newName == null) return;
    final error = ref
        .read(gameControllerProvider.notifier)
        .renamePlayer(player.id, newName);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all players?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final players = ref.read(playersProvider);
    ref.read(gameControllerProvider.notifier).clearPlayers();
    for (var i = players.length - 1; i >= 0; i--) {
      final p = players[i];
      _listKey.currentState?.removeItem(
        i,
        (context, animation) =>
            _PlayerTile(player: p, animation: animation, onRemove: null),
        duration: AppDurations.fast,
      );
    }
  }

  void _continue() {
    ref.read(gameControllerProvider.notifier).goToConfiguration();
    Navigator.of(
      context,
    ).push(GameRoute(builder: (_) => const GameConfigScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(playersProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.7);
    final canContinue = players.length >= GameRules.minPlayers;
    final full = players.length >= GameRules.maxPlayers;

    return Scaffold(
      appBar: AppBar(
        title: const Text("WHO'S PLAYING?"),
        actions: [
          if (players.isNotEmpty)
            IconButton(
              tooltip: 'Clear all players',
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearAll,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GameBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              children: [
                const SizedBox(height: kToolbarHeight),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        enabled: !full,
                        maxLength: GameRules.maxNameLength,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onChanged: _onChanged,
                        onSubmitted: (_) => _add(),
                        decoration: InputDecoration(
                          hintText: full ? 'Full house!' : 'Player name',
                          prefixIcon: const Icon(Icons.person_rounded),
                          errorText: _error,
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: full ? null : _add,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('ADD'),
                        style: FilledButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.button,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: AppSpacing.md,
                    children: [
                      Text(
                        '${players.length} / ${GameRules.maxPlayers} players',
                        style: text.titleSmall,
                      ),
                      Text(
                        'Best with ${GameRules.recommendedMinPlayers}–${GameRules.recommendedMaxPlayers} players',
                        style: text.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Stack(
                    children: [
                      if (players.isEmpty)
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('👥', style: TextStyle(fontSize: 56)),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Add at least ${GameRules.minPlayers} players to start.',
                                textAlign: TextAlign.center,
                                style: text.titleMedium?.copyWith(color: muted),
                              ),
                            ],
                          ),
                        ),
                      AnimatedList(
                        key: _listKey,
                        controller: _scrollController,
                        initialItemCount: players.length,
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        itemBuilder: (context, index, animation) {
                          final list = ref.read(playersProvider);
                          if (index >= list.length) {
                            return const SizedBox.shrink();
                          }
                          final p = list[index];
                          return _PlayerTile(
                            key: ValueKey(p.id),
                            player: p,
                            animation: animation,
                            onTap: () => _rename(p),
                            onRemove: () => _remove(p, index),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                if (!canContinue && players.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Add ${GameRules.minPlayers - players.length} more to start.',
                      style: text.bodyMedium?.copyWith(color: muted),
                    ),
                  ),
                GameButton(
                  label: 'CONTINUE',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: canContinue ? _continue : null,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    super.key,
    required this.player,
    required this.animation,
    required this.onRemove,
    this.onTap,
  });

  final Player player;
  final Animation<double> animation;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    );
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.3, 0),
            end: Offset.zero,
          ).animate(curved),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: scheme.surface,
              borderRadius: AppRadius.button,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        player.position.toString().padLeft(2, '0'),
                        style: text.labelLarge?.copyWith(color: scheme.primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      PlayerAvatar(name: player.name, seed: player.id),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium,
                        ),
                      ),
                      if (onRemove != null)
                        IconButton(
                          tooltip: 'Remove ${player.name}',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: onRemove,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.player});

  final Player player;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.player.name);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (PlayerValidator.normalize(_controller.text).isEmpty) return;
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Rename player'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: GameRules.maxNameLength,
      textCapitalization: TextCapitalization.words,
      onSubmitted: (_) => _save(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('CANCEL'),
      ),
      FilledButton(onPressed: _save, child: const Text('SAVE')),
    ],
  );
}
