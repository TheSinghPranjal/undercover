import 'package:flutter/foundation.dart';

@immutable
class Player {
  const Player({
    required this.id,
    required this.name,
    required this.position,
    this.isActive = true,
  });

  /// Unique identifier. Never use [name] to identify a player – duplicate
  /// names can be allowed.
  final String id;
  final String name;

  /// 1-based seat order in the pass-the-phone rotation.
  final int position;
  final bool isActive;

  Player copyWith({String? name, int? position, bool? isActive}) => Player(
    id: id,
    name: name ?? this.name,
    position: position ?? this.position,
    isActive: isActive ?? this.isActive,
  );

  @override
  bool operator ==(Object other) =>
      other is Player &&
      other.id == id &&
      other.name == name &&
      other.position == position &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(id, name, position, isActive);

  @override
  String toString() => 'Player($position, $name)';
}
