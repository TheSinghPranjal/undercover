import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/player_avatar.dart';
import '../../domain/entities/player.dart';
import '../../domain/services/game_rules.dart';
import '../../domain/services/player_validator.dart';
import '../providers/providers.dart';
import '../widgets/labels.dart';
import '../widgets/playful_ui.dart';
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
    final canContinue = players.length >= GameRules.minPlayers;
    final full = players.length >= GameRules.maxPlayers;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: PlayfulColors.page,
        body: PlayfulBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: RoundIconButton(
                          icon: Icons.chevron_left_rounded,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      if (players.isNotEmpty)
                        Align(
                          alignment: Alignment.topRight,
                          child: RoundIconButton(
                            icon: Icons.delete_sweep_rounded,
                            tooltip: 'Clear all players',
                            onPressed: _clearAll,
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(40, 22, 40, 0),
                        child: Center(
                          child: BubbleTitle(
                            top: "WHO'S",
                            bottom: 'PLAYING?',
                            semanticsLabel: "Who's playing?",
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
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
                          cursorColor: PlayfulColors.accent,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: PlayfulColors.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: full ? 'Full house!' : 'Player name',
                            hintStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: PlayfulColors.soft,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 18, right: 10),
                              child: Icon(
                                Icons.person_rounded,
                                color: Color(0xFF4A3F86),
                                size: 26,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(),
                            errorText: _error,
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                            border: _fieldBorder(PlayfulColors.field),
                            enabledBorder: _fieldBorder(PlayfulColors.field),
                            disabledBorder: _fieldBorder(PlayfulColors.field),
                            focusedBorder: _fieldBorder(
                              PlayfulColors.accent,
                              width: 2,
                            ),
                            errorBorder: _fieldBorder(const Color(0xFFE0304F)),
                            focusedErrorBorder: _fieldBorder(
                              const Color(0xFFE0304F),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _AddButton(onPressed: full ? null : _add),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${players.length} / ${GameRules.maxPlayers} players',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: PlayfulColors.ink,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Best with ${GameRules.recommendedMinPlayers}–${GameRules.recommendedMaxPlayers} players',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: PlayfulColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: Stack(
                      children: [
                        if (players.isEmpty) const Center(child: _EmptyState()),
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
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Add ${GameRules.minPlayers - players.length} more to start.',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: PlayfulColors.accentDeep,
                        ),
                      ),
                    ),
                  PillButton(
                    label: 'CONTINUE',
                    icon: Icons.arrow_forward_rounded,
                    primary: true,
                    onPressed: canContinue ? _continue : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, {double width = 1.5}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: width),
      );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    const radius = BorderRadius.all(Radius.circular(18));
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: enabled
                  ? PlayfulColors.primaryGradient
                  : const [Color(0xFFC9C0E3), Color(0xFFC9C0E3)],
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: PlayfulColors.accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'ADD',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    const burst = Color(0xFF7B55EE);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Sparks(color: burst, mirrored: true),
            const SizedBox(width: 4),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFC3B0F5), Color(0xFF9D82EC)],
              ).createShader,
              child: const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(Icons.groups_rounded, size: 96),
              ),
            ),
            const SizedBox(width: 4),
            const Sparks(color: burst),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Add at least ${GameRules.minPlayers} players to start.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: PlayfulColors.muted,
          ),
        ),
      ],
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
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    );
    const radius = BorderRadius.all(Radius.circular(18));
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
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              type: MaterialType.transparency,
              child: Ink(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: radius,
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: PlayfulColors.accent.withValues(alpha: 0.1),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: radius,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                    child: Row(
                      children: [
                        Text(
                          player.position.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: PlayfulColors.accent,
                          ),
                        ),
                        const SizedBox(width: 14),
                        PlayerAvatar(name: player.name, seed: player.id),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            player.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: PlayfulColors.ink,
                            ),
                          ),
                        ),
                        if (onRemove != null)
                          IconButton(
                            tooltip: 'Remove ${player.name}',
                            icon: const Icon(
                              Icons.close_rounded,
                              color: PlayfulColors.soft,
                            ),
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
