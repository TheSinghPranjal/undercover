import 'package:flutter/material.dart';

/// Two-step confirmation before discarding a dealt round.
Future<bool> confirmExitRound(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Leave this round?'),
      content: const Text('Your secret card has already been assigned.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('EXIT ROUND'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('KEEP PLAYING'),
        ),
      ],
    ),
  );
  if (leave != true || !context.mounted) return false;

  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Discard this round?'),
      content: const Text(
        "Everyone's cards will be thrown away. Next time you'll get a new word.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('DISCARD'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('KEEP PLAYING'),
        ),
      ],
    ),
  );
  return discard == true;
}
